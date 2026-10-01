import logging
import secrets
from datetime import timedelta
from typing import Dict, Optional, Tuple
from django.conf import settings
from django.contrib.auth import authenticate
from django.core.exceptions import ValidationError
from django.db import transaction
from django.utils import timezone
from rest_framework_simplejwt.tokens import RefreshToken

from apps.authentication.models import OTPCode, OTPPurpose
from apps.users.models import (
    AuditLog,
    DeviceType,
    SecurityEvent,
    SecurityEventType,
    User,
    UserDevice,
    UserRole,
    UserSession,
    UserStatus,
)

logger = logging.getLogger("banking.auth")


class OTPService:
    """Handles secure OTP code generation, dispatching, and verification."""

    @classmethod
    def generate_otp(
        cls,
        purpose: str,
        user: Optional[User] = None,
        phone_number: str = "",
        email: str = "",
        ttl_minutes: int = 5,
        ip_address: Optional[str] = None
    ) -> Tuple[OTPCode, str]:
        raw_code = "".join(secrets.choice("0123456789") for _ in range(6))

        # Invalidate prior pending OTPs for this destination & purpose
        prior_query = OTPCode.objects.filter(purpose=purpose, is_used=False)
        if phone_number:
            prior_query = prior_query.filter(phone_number=phone_number)
        elif email:
            prior_query = prior_query.filter(email=email)
        elif user:
            prior_query = prior_query.filter(user=user)
        prior_query.update(is_used=True)

        otp_record = OTPCode.create_otp(
            purpose=purpose,
            raw_code=raw_code,
            user=user,
            phone_number=phone_number or (user.phone_number if user else ""),
            email=email or (user.email if user else ""),
            ttl_minutes=ttl_minutes
        )

        SecurityEvent.objects.create(
            user=user,
            event_type=SecurityEventType.OTP_REQUEST,
            ip_address=ip_address,
            details={"purpose": purpose, "destination": phone_number or email}
        )

        # In a simulated environment, print the code for test visibility
        logger.info("SIMULATED OTP DISPATCH: Destination=%s Purpose=%s Code=%s", phone_number or email, purpose, raw_code)
        print(f"[OTP SIMULATION] >>> Sent {purpose} code: {raw_code} to {phone_number or email} <<<")

        return otp_record, raw_code

    @classmethod
    def verify_otp(
        cls,
        purpose: str,
        code: str,
        user: Optional[User] = None,
        phone_number: str = "",
        email: str = "",
        ip_address: Optional[str] = None
    ) -> bool:
        query = OTPCode.objects.filter(
            purpose=purpose,
            is_used=False,
            expires_at__gt=timezone.now()
        ).order_by("-created_at")

        if phone_number:
            query = query.filter(phone_number=phone_number)
        elif email:
            query = query.filter(email=email)
        elif user:
            query = query.filter(user=user)
        else:
            raise ValidationError("A user, phone number, or email destination is required.")

        otp_record = query.first()
        if not otp_record:
            SecurityEvent.objects.create(
                user=user,
                event_type=SecurityEventType.OTP_FAILURE,
                ip_address=ip_address,
                details={"purpose": purpose, "reason": "No active OTP found or expired"}
            )
            raise ValidationError("Invalid or expired OTP code. Please request a new one.")

        is_valid = otp_record.verify(code)
        if not is_valid:
            SecurityEvent.objects.create(
                user=user,
                event_type=SecurityEventType.OTP_FAILURE,
                ip_address=ip_address,
                details={"purpose": purpose, "attempts": otp_record.attempt_count}
            )
            raise ValidationError("Incorrect OTP code. Please verify and try again.")

        SecurityEvent.objects.create(
            user=user,
            event_type=SecurityEventType.OTP_SUCCESS,
            ip_address=ip_address,
            details={"purpose": purpose}
        )
        return True


class AuthService:
    """Manages user registration, JWT generation, device tracking, and session rotation."""

    @classmethod
    @transaction.atomic
    def register_user(cls, validated_data: dict, ip_address: Optional[str] = None, user_agent: str = "") -> Tuple[User, Dict]:
        password = validated_data.pop("password", None)
        role = validated_data.get("role", UserRole.CUSTOMER)
        pin = validated_data.pop("pin", None)
        profile_photo_b64 = validated_data.pop("profile_photo_base64", None)
        id_doc_photo_b64 = validated_data.pop("id_document_photo_base64", None)
        profile_photo_file = validated_data.pop("profile_photo", None)
        id_doc_photo_file = validated_data.pop("id_document_photo", None)

        user = User.objects.create_user(
            email=validated_data["email"],
            phone_number=validated_data["phone_number"],
            full_name=validated_data["full_name"],
            password=password,
            role=role,
            status=validated_data.get("status", UserStatus.PENDING_APPROVAL),
            date_of_birth=validated_data.get("date_of_birth"),
            gender=validated_data.get("gender"),
            id_document_type=validated_data.get("id_document_type"),
            id_document_number=validated_data.get("id_document_number"),
            kyc_tier=1,
        )

        import base64
        import uuid
        from django.core.files.base import ContentFile

        if profile_photo_file:
            user.profile_photo = profile_photo_file
        elif profile_photo_b64:
            try:
                b64_data = profile_photo_b64.split(",")[1] if "," in profile_photo_b64 else profile_photo_b64
                decoded = base64.b64decode(b64_data)
                user.profile_photo.save(f"avatar_{uuid.uuid4().hex[:8]}.jpg", ContentFile(decoded), save=False)
            except Exception as e:
                logger.warning("Failed to decode profile_photo_base64: %s", e)

        if id_doc_photo_file:
            user.id_document_photo = id_doc_photo_file
        elif id_doc_photo_b64:
            try:
                b64_data = id_doc_photo_b64.split(",")[1] if "," in id_doc_photo_b64 else id_doc_photo_b64
                decoded = base64.b64decode(b64_data)
                user.id_document_photo.save(f"doc_{uuid.uuid4().hex[:8]}.jpg", ContentFile(decoded), save=False)
            except Exception as e:
                logger.warning("Failed to decode id_document_photo_base64: %s", e)

        if pin:
            user.set_pin(pin)
        user.save()

        # Ensure only 1 primary wallet is provisioned (get_or_create prevents duplicates)
        from apps.wallets.models import Wallet
        Wallet.objects.get_or_create(
            user=user,
            is_primary=True,
            defaults={
                "currency": "USD",
                "current_balance": 0,
                "available_balance": 0,
                "hold_balance": 0,
            }
        )

        SecurityEvent.objects.create(
            user=user,
            event_type=SecurityEventType.LOGIN_SUCCESS,
            ip_address=ip_address,
            user_agent=user_agent,
            details={"action": "registration", "status": user.status}
        )

        session_data = (
            cls.create_user_session(user=user, ip_address=ip_address, user_agent=user_agent)
            if user.status == UserStatus.ACTIVE
            else None
        )
        return user, session_data

    @classmethod
    def create_user_session(
        cls,
        user: User,
        ip_address: Optional[str] = None,
        user_agent: str = "",
        device_identifier: Optional[str] = None,
        device_name: Optional[str] = None,
        device_type: str = DeviceType.OTHER
    ) -> Dict:
        """Issues JWT token pair and records UserDevice and UserSession."""
        # Update device tracking
        device = None
        if device_identifier:
            device, created = UserDevice.objects.get_or_create(
                user=user,
                device_identifier=device_identifier,
                defaults={
                    "device_name": device_name or "Mobile / Browser",
                    "device_type": device_type,
                    "ip_address": ip_address,
                    "last_login_at": timezone.now(),
                    "is_active": True,
                }
            )
            if not created:
                device.ip_address = ip_address
                device.last_login_at = timezone.now()
                device.save(update_fields=["ip_address", "last_login_at", "updated_at"])

        # Generate JWT pair
        refresh = RefreshToken.for_user(user)
        refresh["role"] = user.role
        refresh["email"] = user.email

        raw_refresh = str(refresh)
        raw_access = str(refresh.access_token)

        refresh_lifetime = getattr(settings, "SIMPLE_JWT", {}).get("REFRESH_TOKEN_LIFETIME", timedelta(days=7))
        expires_at = timezone.now() + refresh_lifetime

        token_hash = UserSession.hash_token(raw_refresh)
        session = UserSession.objects.create(
            user=user,
            device=device,
            refresh_token_hash=token_hash,
            ip_address=ip_address,
            user_agent=user_agent,
            expires_at=expires_at,
            is_revoked=False
        )

        user.last_login_at = timezone.now()
        user.save(update_fields=["last_login_at"])

        return {
            "access_token": raw_access,
            "refresh_token": raw_refresh,
            "token_type": "Bearer",
            "expires_in": int(getattr(settings, "SIMPLE_JWT", {}).get("ACCESS_TOKEN_LIFETIME", timedelta(minutes=15)).total_seconds()),
            "session_id": str(session.id)
        }

    @classmethod
    def rotate_session_token(cls, raw_refresh_token: str, ip_address: Optional[str] = None, user_agent: str = "") -> Dict:
        """Rotates refresh token and maintains session security audit."""
        token_hash = UserSession.hash_token(raw_refresh_token)

        try:
            session = UserSession.objects.select_related("user", "device").get(
                refresh_token_hash=token_hash
            )
        except UserSession.DoesNotExist:
            raise ValidationError("Invalid refresh token.")

        if not session.is_valid:
            # Token reuse detection: possible compromise!
            SecurityEvent.objects.create(
                user=session.user,
                event_type=SecurityEventType.SUSPICIOUS_ACTIVITY,
                ip_address=ip_address,
                user_agent=user_agent,
                details={"reason": "Attempted reuse of revoked or expired refresh token."}
            )
            raise ValidationError("Token has been revoked or expired.")

        # Revoke previous session
        session.is_revoked = True
        session.save(update_fields=["is_revoked", "updated_at"])

        # Issue new token pair
        user = session.user
        if not user.can_transact():
            raise ValidationError("Account is not active.")

        new_session_data = cls.create_user_session(
            user=user,
            ip_address=ip_address,
            user_agent=user_agent,
            device_identifier=session.device.device_identifier if session.device else None,
            device_name=session.device.device_name if session.device else None
        )
        return new_session_data

    @classmethod
    def revoke_session(cls, user: User, raw_refresh_token: str) -> None:
        """Revokes session and token on logout."""
        token_hash = UserSession.hash_token(raw_refresh_token)
        UserSession.objects.filter(user=user, refresh_token_hash=token_hash).update(
            is_revoked=True,
            updated_at=timezone.now()
        )
        SecurityEvent.objects.create(
            user=user,
            event_type=SecurityEventType.LOGOUT,
            details={"action": "user_logout"}
        )

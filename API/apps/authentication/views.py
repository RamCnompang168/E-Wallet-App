from django.contrib.auth import authenticate
from django.core.exceptions import ValidationError
from django.db.models import Q
from rest_framework import status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.views import APIView

from apps.authentication.models import OTPPurpose
from apps.authentication.serializers import (
    ForgotPasswordSerializer,
    LoginSerializer,
    RefreshTokenSerializer,
    RegisterSerializer,
    ResetPasswordSerializer,
    SendOTPSerializer,
    UserProfileSerializer,
    VerifyOTPSerializer,
)
from apps.authentication.services import AuthService, OTPService
from apps.core.responses import error_response, success_response
from apps.users.models import SecurityEvent, SecurityEventType, User, UserStatus


def get_client_ip(request) -> str:
    x_forwarded_for = request.META.get("HTTP_X_FORWARDED_FOR")
    if x_forwarded_for:
        return x_forwarded_for.split(",")[0].strip()
    return request.META.get("REMOTE_ADDR", "127.0.0.1")


class RegisterView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        ip = get_client_ip(request)
        ua = request.META.get("HTTP_USER_AGENT", "")

        user, session_data = AuthService.register_user(
            validated_data=serializer.validated_data,
            ip_address=ip,
            user_agent=ua
        )

        user_data = UserProfileSerializer(user).data
        if user.status == UserStatus.PENDING_APPROVAL:
            return success_response(
                message="Registration successful! Your account is pending administrator approval. Please wait for admin approval before logging in.",
                data={"user": user_data, "tokens": None, "pending_approval": True},
                status_code=status.HTTP_201_CREATED
            )

        return success_response(
            message="User registration successful.",
            data={"user": user_data, "tokens": session_data, "pending_approval": False},
            status_code=status.HTTP_201_CREATED
        )


class LoginView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        identifier = serializer.validated_data["username"].strip().lower()
        password = serializer.validated_data["password"]
        ip = get_client_ip(request)
        ua = request.META.get("HTTP_USER_AGENT", "")

        # Find user by email or phone
        try:
            user = User.objects.get(Q(email=identifier) | Q(phone_number=identifier))
        except User.DoesNotExist:
            user = None

        if user is None or not user.check_password(password):
            if user:
                SecurityEvent.objects.create(
                    user=user,
                    event_type=SecurityEventType.LOGIN_FAILURE,
                    ip_address=ip,
                    user_agent=ua,
                    details={"reason": "Incorrect password"}
                )
            return error_response(
                message="Invalid email/phone or password.",
                status_code=status.HTTP_401_UNAUTHORIZED
            )

        if user.status == UserStatus.PENDING_APPROVAL:
            SecurityEvent.objects.create(
                user=user,
                event_type=SecurityEventType.LOGIN_FAILURE,
                ip_address=ip,
                user_agent=ua,
                details={"reason": "Account is pending administrator approval."}
            )
            return error_response(
                message="Your account is pending administrator approval. Please wait for an administrator to approve your account before logging in.",
                status_code=status.HTTP_403_FORBIDDEN
            )

        if not user.is_active or user.status != UserStatus.ACTIVE:
            SecurityEvent.objects.create(
                user=user,
                event_type=SecurityEventType.LOGIN_FAILURE,
                ip_address=ip,
                user_agent=ua,
                details={"reason": f"Account status is {user.status}"}
            )
            return error_response(
                message=f"Account is {user.status.lower()}. Please contact support.",
                status_code=status.HTTP_403_FORBIDDEN
            )

        # Issue session and JWT
        session_data = AuthService.create_user_session(
            user=user,
            ip_address=ip,
            user_agent=ua,
            device_identifier=serializer.validated_data.get("device_identifier"),
            device_name=serializer.validated_data.get("device_name"),
            device_type=serializer.validated_data.get("device_type")
        )

        SecurityEvent.objects.create(
            user=user,
            event_type=SecurityEventType.LOGIN_SUCCESS,
            ip_address=ip,
            user_agent=ua,
            details={"device": serializer.validated_data.get("device_name")}
        )

        user_data = UserProfileSerializer(user).data
        return success_response(
            message="Login successful.",
            data={"user": user_data, "tokens": session_data}
        )


class LogoutView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        refresh_token = request.data.get("refresh_token")
        if refresh_token:
            AuthService.revoke_session(request.user, refresh_token)
        return success_response(message="Logout successful.")


class RefreshTokenView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = RefreshTokenSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        ip = get_client_ip(request)
        ua = request.META.get("HTTP_USER_AGENT", "")

        try:
            session_data = AuthService.rotate_session_token(
                raw_refresh_token=serializer.validated_data["refresh_token"],
                ip_address=ip,
                user_agent=ua
            )
            return success_response(message="Token refreshed successfully.", data=session_data)
        except ValidationError as exc:
            return error_response(message=str(exc.message), status_code=status.HTTP_401_UNAUTHORIZED)


class SendOTPView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = SendOTPSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        purpose = serializer.validated_data["purpose"]
        phone = serializer.validated_data.get("phone_number", "")
        email = serializer.validated_data.get("email", "")
        ip = get_client_ip(request)

        user = None
        if request.user.is_authenticated:
            user = request.user
        elif phone or email:
            user = User.objects.filter(Q(phone_number=phone) | Q(email=email)).first()

        otp_rec, raw_code = OTPService.generate_otp(
            purpose=purpose,
            user=user,
            phone_number=phone,
            email=email,
            ip_address=ip
        )

        # In simulation mode, we return the code in the response for test convenience
        return success_response(
            message=f"OTP code sent successfully to {phone or email}.",
            data={"purpose": purpose, "simulation_code": raw_code}
        )


class VerifyOTPView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = VerifyOTPSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        purpose = serializer.validated_data["purpose"]
        code = serializer.validated_data["code"]
        phone = serializer.validated_data.get("phone_number", "")
        email = serializer.validated_data.get("email", "")
        ip = get_client_ip(request)

        user = None
        if request.user.is_authenticated:
            user = request.user
        elif phone or email:
            user = User.objects.filter(Q(phone_number=phone) | Q(email=email)).first()

        try:
            OTPService.verify_otp(
                purpose=purpose,
                code=code,
                user=user,
                phone_number=phone,
                email=email,
                ip_address=ip
            )
            if user:
                if phone and not user.is_phone_verified:
                    user.is_phone_verified = True
                    user.save(update_fields=["is_phone_verified"])
                if email and not user.is_email_verified:
                    user.is_email_verified = True
                    user.save(update_fields=["is_email_verified"])

            return success_response(message="OTP verified successfully.")
        except ValidationError as exc:
            return error_response(message=str(exc.message), status_code=status.HTTP_400_BAD_REQUEST)


class ForgotPasswordView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = ForgotPasswordSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        identifier = serializer.validated_data["identifier"].strip().lower()
        user = User.objects.filter(Q(email=identifier) | Q(phone_number=identifier)).first()

        if user:
            otp_rec, raw_code = OTPService.generate_otp(
                purpose=OTPPurpose.PASSWORD_RESET,
                user=user,
                phone_number=user.phone_number,
                email=user.email,
                ip_address=get_client_ip(request)
            )
            return success_response(
                message="Password reset instructions and OTP sent.",
                data={"simulation_code": raw_code}
            )

        # Do not reveal account existence
        return success_response(message="Password reset instructions and OTP sent if account exists.")


class ResetPasswordView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = ResetPasswordSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        identifier = serializer.validated_data["identifier"].strip().lower()
        code = serializer.validated_data["otp_code"]
        new_password = serializer.validated_data["new_password"]
        ip = get_client_ip(request)

        user = User.objects.filter(Q(email=identifier) | Q(phone_number=identifier)).first()
        if not user:
            return error_response(message="User account not found.", status_code=status.HTTP_404_NOT_FOUND)

        try:
            OTPService.verify_otp(
                purpose=OTPPurpose.PASSWORD_RESET,
                code=code,
                user=user,
                ip_address=ip
            )
        except ValidationError as exc:
            return error_response(message=str(exc.message), status_code=status.HTTP_400_BAD_REQUEST)

        user.set_password(new_password)
        user.save(update_fields=["password", "updated_at"])

        # Revoke all existing sessions for security
        user.sessions.filter(is_revoked=False).update(is_revoked=True)

        SecurityEvent.objects.create(
            user=user,
            event_type=SecurityEventType.PASSWORD_CHANGE,
            ip_address=ip,
            details={"action": "password_reset_via_otp"}
        )

        return success_response(message="Password has been reset successfully. Please log in with your new password.")


class GoogleAuthView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        email = request.data.get("email", "").strip().lower()
        full_name = request.data.get("full_name", "").strip()
        google_id = request.data.get("google_id", "")
        profile_photo = request.data.get("profile_photo", "")

        if not email:
            return error_response(message="Google email is required.", status_code=status.HTTP_400_BAD_REQUEST)

        ip = get_client_ip(request)
        ua = request.META.get("HTTP_USER_AGENT", "")

        user = User.objects.filter(email=email).first()
        if not user:
            # Generate deterministic or unique Cambodian phone number for Google user
            import random
            random_digits = "".join(random.choices("0123456789", k=6))
            generated_phone = f"+85590{random_digits}"
            while User.objects.filter(phone_number=generated_phone).exists():
                random_digits = "".join(random.choices("0123456789", k=6))
                generated_phone = f"+85590{random_digits}"

            user = User.objects.create_user(
                email=email,
                phone_number=generated_phone,
                full_name=full_name or email.split("@")[0].title(),
                role=UserRole.CUSTOMER,
                status=UserStatus.ACTIVE,
                is_email_verified=True,
                kyc_tier=1,
            )
            # Provision wallet
            from apps.wallets.models import Wallet
            Wallet.objects.get_or_create(
                user=user,
                is_primary=True,
                defaults={"currency": "USD", "current_balance": 0, "available_balance": 0, "hold_balance": 0}
            )

        if user.status in [UserStatus.SUSPENDED, UserStatus.FROZEN, UserStatus.CLOSED]:
            return error_response(
                message=f"Account is {user.status.lower()}. Please contact support.",
                status_code=status.HTTP_403_FORBIDDEN
            )

        # Activate user if was pending
        if user.status != UserStatus.ACTIVE:
            user.status = UserStatus.ACTIVE
            user.is_active = True
            user.save(update_fields=["status", "is_active"])

        # Create session tokens
        session_data = AuthService.create_user_session(
            user=user,
            ip_address=ip,
            user_agent=ua,
            device_name=request.data.get("device_name", "Google Account"),
            device_identifier=request.data.get("device_identifier", f"google-{google_id or email}")
        )

        SecurityEvent.objects.create(
            user=user,
            event_type=SecurityEventType.LOGIN_SUCCESS,
            ip_address=ip,
            user_agent=ua,
            details={"provider": "google", "email": email}
        )

        user_data = UserProfileSerializer(user).data
        return success_response(
            message="Google sign-in successful.",
            data={"user": user_data, "tokens": session_data}
        )

import secrets
from decimal import Decimal
from django.db import transaction
from rest_framework import status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.views import APIView

from apps.authentication.permissions import IsActiveUser
from apps.core.idempotency import idempotent_request
from apps.core.pagination import StandardResultsSetPagination
from apps.core.responses import error_response, success_response
from apps.payments.models import PaymentMethod, TopUp, Withdrawal
from apps.payments.serializers import (
    PaymentMethodSerializer,
    TopUpCreateSerializer,
    TopUpDetailSerializer,
    WithdrawalCreateSerializer,
    WithdrawalDetailSerializer,
)
from apps.payments.services import TopUpService, WithdrawalService
from apps.transactions.models import Transaction, TransactionStatus, TransactionType
from apps.users.models import AuditLog
from apps.wallets.models import Wallet
from apps.wallets.services import LedgerService


class PaymentMethodListView(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        methods = PaymentMethod.objects.filter(is_active=True).order_by("method_type", "method_name")
        serializer = PaymentMethodSerializer(methods, many=True)
        return success_response(data=serializer.data)


class TopUpListCreateView(APIView):
    permission_classes = [IsAuthenticated, IsActiveUser]

    def get(self, request):
        user_wallets = request.user.wallets.values_list("id", flat=True)
        topups = TopUp.objects.filter(
            transaction__receiver_wallet_id__in=user_wallets
        ).select_related("transaction", "payment_method").order_by("-created_at")

        paginator = StandardResultsSetPagination()
        page = paginator.paginate_queryset(topups, request)
        serializer = TopUpDetailSerializer(page, many=True)
        return paginator.get_paginated_response(serializer.data)

    @idempotent_request()
    def post(self, request):
        serializer = TopUpCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        txn = TopUpService.execute_topup(
            user=request.user,
            payment_method_id=str(serializer.validated_data["payment_method_id"]),
            amount=serializer.validated_data["amount"],
            provider_reference=serializer.validated_data.get("provider_reference")
        )

        topup_rec = txn.topup_details
        return success_response(
            message="Top-up completed successfully.",
            data=TopUpDetailSerializer(topup_rec).data,
            status_code=status.HTTP_201_CREATED
        )


class TopUpDetailView(APIView):
    permission_classes = [IsAuthenticated, IsActiveUser]

    def get(self, request, pk):
        user_wallets = request.user.wallets.values_list("id", flat=True)
        topup = TopUp.objects.filter(
            id=pk,
            transaction__receiver_wallet_id__in=user_wallets
        ).select_related("transaction", "payment_method").first()

        if not topup:
            return error_response(message="Top-up record not found.", status_code=status.HTTP_404_NOT_FOUND)

        return success_response(data=TopUpDetailSerializer(topup).data)


class WithdrawalListCreateView(APIView):
    permission_classes = [IsAuthenticated, IsActiveUser]

    def get(self, request):
        user_wallets = request.user.wallets.values_list("id", flat=True)
        withdrawals = Withdrawal.objects.filter(
            transaction__sender_wallet_id__in=user_wallets
        ).select_related("transaction", "payment_method").order_by("-created_at")

        paginator = StandardResultsSetPagination()
        page = paginator.paginate_queryset(withdrawals, request)
        serializer = WithdrawalDetailSerializer(page, many=True)
        return paginator.get_paginated_response(serializer.data)

    @idempotent_request()
    def post(self, request):
        serializer = WithdrawalCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        txn = WithdrawalService.execute_withdrawal(
            user=request.user,
            payment_method_id=str(serializer.validated_data["payment_method_id"]),
            destination_account=serializer.validated_data["destination_account"],
            amount=serializer.validated_data["amount"],
            pin=serializer.validated_data.get("pin")
        )

        withdrawal_rec = txn.withdrawal_details
        return success_response(
            message="Withdrawal processed successfully.",
            data=WithdrawalDetailSerializer(withdrawal_rec).data,
            status_code=status.HTTP_201_CREATED
        )


class WithdrawalDetailView(APIView):
    permission_classes = [IsAuthenticated, IsActiveUser]

    def get(self, request, pk):
        user_wallets = request.user.wallets.values_list("id", flat=True)
        withdrawal = Withdrawal.objects.filter(
            id=pk,
            transaction__sender_wallet_id__in=user_wallets
        ).select_related("transaction", "payment_method").first()

        if not withdrawal:
            return error_response(message="Withdrawal record not found.", status_code=status.HTTP_404_NOT_FOUND)

        return success_response(data=WithdrawalDetailSerializer(withdrawal).data)


class GovernmentServicePaymentView(APIView):
    """Executes public/government utility and tax payments."""
    permission_classes = [IsAuthenticated, IsActiveUser]

    @idempotent_request()
    def post(self, request):
        service_type = (request.data.get("service_type") or "GOV_SERVICE").strip()
        service_name = (request.data.get("service_name") or "Government Public Service").strip()
        consumer_number = (
            request.data.get("consumer_number")
            or request.data.get("reference_number")
            or ""
        ).strip()
        notes = (request.data.get("notes") or "").strip()
        pin = (request.data.get("pin") or "").strip()

        try:
            amount = Decimal(str(request.data.get("amount", "0")))
        except Exception:
            return error_response(message="Invalid payment amount.", status_code=status.HTTP_400_BAD_REQUEST)

        if amount <= Decimal("0.0000"):
            return error_response(message="Payment amount must be greater than zero.", status_code=status.HTTP_400_BAD_REQUEST)

        if not consumer_number:
            return error_response(message="Bill reference or account number is required.", status_code=status.HTTP_400_BAD_REQUEST)

        user = request.user
        if user.pin_hash:
            if not pin:
                return error_response(message="Transaction PIN is required to authorize payment.", status_code=status.HTTP_400_BAD_REQUEST)
            try:
                user.verify_pin(pin)
            except Exception as e:
                return error_response(message=str(e), status_code=status.HTTP_400_BAD_REQUEST)

        wallet = Wallet.objects.filter(user=user, is_primary=True, status="ACTIVE").first()
        if not wallet:
            return error_response(message="No active primary wallet found.", status_code=status.HTTP_400_BAD_REQUEST)

        with transaction.atomic():
            locked = LedgerService.lock_wallets_canonical(wallet.id)
            locked_wallet = locked[str(wallet.id)]

            if locked_wallet.available_balance < amount:
                return error_response(message="Insufficient wallet balance.", status_code=status.HTTP_400_BAD_REQUEST)

            desc = f"{service_name} ({consumer_number})"
            if notes:
                desc += f" - {notes}"
            ref = f"GOV-{secrets.token_hex(4).upper()}"

            txn = Transaction.objects.create(
                transaction_type=TransactionType.MERCHANT_PAYMENT,
                status=TransactionStatus.PROCESSING,
                sender_wallet=locked_wallet,
                amount=amount,
                fee_amount=Decimal("0.0000"),
                total_amount=amount,
                currency=locked_wallet.currency,
                description=desc,
                reference_number=ref,
            )

            LedgerService.post_withdrawal_entries(
                txn=txn,
                sender_wallet=locked_wallet,
                amount=amount,
                fee_amount=Decimal("0.0000")
            )

            txn.transition_to(TransactionStatus.COMPLETED)
            txn.save(update_fields=["status", "completed_at", "updated_at"])

            AuditLog.objects.create(
                user=user,
                action="GOV_PAYMENT_COMPLETED",
                entity_type="Transaction",
                entity_id=str(txn.id),
                new_value={"amount": str(amount), "service": service_name, "ref": consumer_number}
            )

            try:
                from apps.notifications.services import NotificationService
                NotificationService.create_notification(
                    user=user,
                    notification_type="TRANSACTION",
                    title="Government Service Paid",
                    message=f"Successfully paid ${amount:.2f} for {service_name} ({consumer_number}). Reference: {ref}",
                    related_transaction=txn
                )
            except Exception:
                pass

        return success_response(
            message=f"Successfully paid for {service_name}.",
            data={
                "transaction_code": txn.transaction_code,
                "reference_number": ref,
                "amount": str(amount),
                "service_name": service_name,
                "consumer_number": consumer_number,
                "description": desc,
                "created_at": txn.created_at.isoformat(),
            },
            status_code=status.HTTP_201_CREATED
        )

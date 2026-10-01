from django.db.models import Q
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.views import APIView

from apps.authentication.permissions import IsActiveUser
from apps.core.idempotency import idempotent_request
from apps.core.pagination import StandardResultsSetPagination
from apps.core.responses import error_response, success_response
from apps.transactions.models import Transaction, TransactionType
from apps.transfers.serializers import TransferCreateSerializer, TransferDetailSerializer
from apps.transfers.services import TransferService


class TransferListCreateView(APIView):
    permission_classes = [IsAuthenticated, IsActiveUser]

    def get(self, request):
        user_wallets = request.user.wallets.values_list("id", flat=True)
        txns = Transaction.objects.filter(
            Q(sender_wallet_id__in=user_wallets) | Q(receiver_wallet_id__in=user_wallets),
            transaction_type=TransactionType.TRANSFER
        ).select_related("sender_wallet__user", "receiver_wallet__user").order_by("-created_at")

        paginator = StandardResultsSetPagination()
        page = paginator.paginate_queryset(txns, request)
        serializer = TransferDetailSerializer(page, many=True)
        return paginator.get_paginated_response(serializer.data)

    @idempotent_request()
    def post(self, request):
        serializer = TransferCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        txn = TransferService.execute_transfer(
            sender_user=request.user,
            receiver_wallet_number=serializer.validated_data["receiver_wallet_number"],
            amount=serializer.validated_data["amount"],
            description=serializer.validated_data.get("description", ""),
            reference_number=serializer.validated_data.get("reference_number", ""),
            pin=serializer.validated_data.get("pin")
        )

        response_data = TransferDetailSerializer(txn).data
        return success_response(
            message="Transfer completed successfully.",
            data=response_data,
            status_code=status.HTTP_201_CREATED
        )


class TransferDetailView(APIView):
    permission_classes = [IsAuthenticated, IsActiveUser]

    def get(self, request, transaction_code):
        user_wallets = request.user.wallets.values_list("id", flat=True)
        txn = Transaction.objects.filter(
            Q(sender_wallet_id__in=user_wallets) | Q(receiver_wallet_id__in=user_wallets),
            transaction_code=transaction_code
        ).select_related("sender_wallet__user", "receiver_wallet__user").first()

        if not txn:
            return error_response(message="Transfer transaction not found.", status_code=status.HTTP_404_NOT_FOUND)

        serializer = TransferDetailSerializer(txn)
        return success_response(data=serializer.data)


class RecipientLookupView(APIView):
    """Searches active recipient users by name, phone, or wallet number."""
    permission_classes = [IsAuthenticated, IsActiveUser]

    def get(self, request):
        query = (request.query_params.get("q") or "").strip()
        from apps.wallets.models import Wallet

        wallets_qs = Wallet.objects.select_related("user").filter(
            status="ACTIVE",
            is_primary=True,
        ).exclude(user=request.user)

        if query:
            wallets_qs = wallets_qs.filter(
                Q(wallet_number__icontains=query)
                | Q(user__full_name__icontains=query)
                | Q(user__phone_number__icontains=query)
                | Q(user__email__icontains=query)
            )

        results = []
        for w in wallets_qs[:10]:
            results.append({
                "wallet_number": w.wallet_number,
                "name": w.user.full_name or w.user.phone_number,
                "phone_number": w.user.phone_number,
                "avatar_url": w.user.profile_photo.url if w.user.profile_photo else "",
            })

        return success_response(data=results)

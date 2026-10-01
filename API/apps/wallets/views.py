from django.db.models import Q
from rest_framework.permissions import IsAuthenticated
from rest_framework.views import APIView

from apps.authentication.permissions import IsActiveUser
from apps.core.pagination import StandardResultsSetPagination
from apps.core.responses import error_response, success_response
from apps.wallets.models import LedgerEntry, Wallet
from apps.wallets.serializers import LedgerEntrySerializer, WalletBalanceSerializer, WalletSerializer


class WalletDetailView(APIView):
    permission_classes = [IsAuthenticated, IsActiveUser]

    def get(self, request):
        wallet = Wallet.objects.filter(user=request.user, is_primary=True).first()
        if not wallet:
            # Fallback to any wallet
            wallet = Wallet.objects.filter(user=request.user).first()

        if not wallet:
            return error_response(message="Wallet not found for this account.", status_code=404)

        serializer = WalletSerializer(wallet)
        return success_response(data=serializer.data)


class WalletBalanceView(APIView):
    permission_classes = [IsAuthenticated, IsActiveUser]

    def get(self, request):
        wallet = Wallet.objects.filter(user=request.user, is_primary=True).first()
        if not wallet:
            return error_response(message="Wallet not found.", status_code=404)

        serializer = WalletBalanceSerializer(wallet)
        return success_response(data=serializer.data)


class WalletLedgerView(APIView):
    permission_classes = [IsAuthenticated, IsActiveUser]

    def get(self, request):
        wallet = Wallet.objects.filter(user=request.user, is_primary=True).first()
        if not wallet:
            return error_response(message="Wallet not found.", status_code=404)

        entries = LedgerEntry.objects.filter(wallet=wallet).select_related("transaction").order_by("-created_at")

        # Optional date filtering
        start_date = request.query_params.get("start_date")
        end_date = request.query_params.get("end_date")
        if start_date:
            entries = entries.filter(created_at__date__gte=start_date)
        if end_date:
            entries = entries.filter(created_at__date__lte=end_date)

        paginator = StandardResultsSetPagination()
        page = paginator.paginate_queryset(entries, request)
        serializer = LedgerEntrySerializer(page, many=True)
        return paginator.get_paginated_response(serializer.data)


class AdminWalletListView(APIView):
    """Staff/Admin view to list and filter all wallets."""
    from apps.authentication.permissions import IsStaffMember
    permission_classes = [IsAuthenticated, IsStaffMember]

    def get(self, request):
        wallets = Wallet.objects.all().select_related("user").order_by("-created_at")
        status_filter = request.query_params.get("status")
        if status_filter:
            wallets = wallets.filter(status=status_filter.upper())

        paginator = StandardResultsSetPagination()
        page = paginator.paginate_queryset(wallets, request)
        serializer = WalletSerializer(page, many=True)
        return paginator.get_paginated_response(serializer.data)


class AdminSystemAccountListView(APIView):
    """Staff/Admin view to inspect internal double-entry balancing accounts and fee revenues."""
    from apps.authentication.permissions import IsStaffMember
    permission_classes = [IsAuthenticated, IsStaffMember]

    def get(self, request):
        from apps.wallets.models import SystemAccount
        accounts = SystemAccount.objects.all().order_by("account_code")
        data = [
            {
                "id": str(acc.id),
                "account_code": acc.account_code,
                "account_name": acc.account_name,
                "currency": acc.currency,
                "balance": str(acc.balance),
                "description": acc.description,
            }
            for acc in accounts
        ]
        return success_response(data=data)


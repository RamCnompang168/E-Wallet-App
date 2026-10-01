from django.urls import path
from apps.wallets.views import (
    AdminSystemAccountListView,
    AdminWalletListView,
    WalletBalanceView,
    WalletDetailView,
    WalletLedgerView,
)

app_name = "wallets"

urlpatterns = [
    path("", WalletDetailView.as_view(), name="wallet_detail"),
    path("balance/", WalletBalanceView.as_view(), name="wallet_balance"),
    path("ledger/", WalletLedgerView.as_view(), name="wallet_ledger"),
    path("admin/wallets/", AdminWalletListView.as_view(), name="admin_wallets"),
    path("admin/system-accounts/", AdminSystemAccountListView.as_view(), name="admin_system_accounts"),
]

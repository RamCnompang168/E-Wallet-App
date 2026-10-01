from django.urls import path
from apps.payments.views import (
    PaymentMethodListView,
    TopUpDetailView,
    TopUpListCreateView,
    WithdrawalDetailView,
    WithdrawalListCreateView,
    GovernmentServicePaymentView,
)

app_name = "payments"

urlpatterns = [
    path("methods/", PaymentMethodListView.as_view(), name="payment_methods_list"),
    path("topups/", TopUpListCreateView.as_view(), name="topups_list_create"),
    path("topups/<uuid:pk>/", TopUpDetailView.as_view(), name="topup_detail"),
    path("withdrawals/", WithdrawalListCreateView.as_view(), name="withdrawals_list_create"),
    path("withdrawals/<uuid:pk>/", WithdrawalDetailView.as_view(), name="withdrawal_detail"),
    path("government/", GovernmentServicePaymentView.as_view(), name="government_payment"),
]

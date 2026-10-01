from django.urls import path
from apps.transfers.views import RecipientLookupView, TransferDetailView, TransferListCreateView

app_name = "transfers"

urlpatterns = [
    path("", TransferListCreateView.as_view(), name="transfer_list_create"),
    path("lookup/", RecipientLookupView.as_view(), name="recipient_lookup"),
    path("<str:transaction_code>/", TransferDetailView.as_view(), name="transfer_detail"),
]

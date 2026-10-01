from decimal import Decimal
from rest_framework import serializers
from apps.transactions.models import Transaction


class TransferCreateSerializer(serializers.Serializer):
    receiver_wallet_number = serializers.CharField(required=True, max_length=32)
    amount = serializers.DecimalField(max_digits=18, decimal_places=4, required=True, min_value=Decimal("0.0001"))
    description = serializers.CharField(required=False, allow_blank=True, default="", max_length=500)
    reference_number = serializers.CharField(required=False, allow_blank=True, default="", max_length=100)
    pin = serializers.CharField(required=False, write_only=True, min_length=6, max_length=6)


class TransferDetailSerializer(serializers.ModelSerializer):
    sender_wallet_number = serializers.CharField(source="sender_wallet.wallet_number", read_only=True)
    sender_name = serializers.CharField(source="sender_wallet.user.full_name", read_only=True)
    receiver_wallet_number = serializers.CharField(source="receiver_wallet.wallet_number", read_only=True)
    receiver_name = serializers.CharField(source="receiver_wallet.user.full_name", read_only=True)

    class Meta:
        model = Transaction
        fields = [
            "id",
            "transaction_code",
            "transaction_type",
            "status",
            "sender_wallet_number",
            "sender_name",
            "receiver_wallet_number",
            "receiver_name",
            "amount",
            "fee_amount",
            "total_amount",
            "currency",
            "description",
            "reference_number",
            "completed_at",
            "created_at",
        ]
        read_only_fields = fields

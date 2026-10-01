import uuid
from decimal import Decimal
import pytest
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APIClient

from apps.core.exceptions import InsufficientBalanceException, SelfTransferException
from apps.transactions.models import FeeRule, Transaction, TransactionStatus, TransactionType
from apps.transfers.services import TransferService
from apps.users.models import User
from apps.wallets.models import LedgerEntry, LedgerEntryType, SystemAccount, SystemAccountCode, Wallet


@pytest.mark.django_db
class TestTransferServiceAndAPI:
    @pytest.fixture(autouse=True)
    def setup_data(self):
        self.client = APIClient()

        # Seed system accounts
        SystemAccount.get_or_create_system_account(SystemAccountCode.FEE_REVENUE, currency="USD")

        # Create Alice ($500 balance)
        self.alice = User.objects.create_user(
            email="alice.test@example.com",
            phone_number="+11111111111",
            password="Password123!",
            full_name="Alice Test"
        )
        self.alice.set_pin("123456")
        self.alice.save()
        self.alice_wallet = Wallet.objects.get(user=self.alice)
        self.alice_wallet.available_balance = Decimal("500.0000")
        self.alice_wallet.current_balance = Decimal("500.0000")
        self.alice_wallet.save()

        # Create Bob ($100 balance)
        self.bob = User.objects.create_user(
            email="bob.test@example.com",
            phone_number="+12222222222",
            password="Password123!",
            full_name="Bob Test"
        )
        self.bob_wallet = Wallet.objects.get(user=self.bob)
        self.bob_wallet.available_balance = Decimal("100.0000")
        self.bob_wallet.current_balance = Decimal("100.0000")
        self.bob_wallet.save()

        # Set fee rule: fixed $1.00 fee for transfers
        FeeRule.objects.update_or_create(
            transaction_type=TransactionType.TRANSFER,
            defaults={"fixed_fee": Decimal("1.0000"), "percentage_fee": Decimal("0.0000"), "is_active": True}
        )

    def test_successful_transfer_and_ledger_balance(self):
        txn = TransferService.execute_transfer(
            sender_user=self.alice,
            receiver_wallet_number=self.bob_wallet.wallet_number,
            amount=Decimal("100.0000"),
            description="Dinner split",
            pin="123456"
        )

        assert txn.status == TransactionStatus.COMPLETED
        assert txn.amount == Decimal("100.0000")
        assert txn.fee_amount == Decimal("1.0000")
        assert txn.total_amount == Decimal("101.0000")

        self.alice_wallet.refresh_from_db()
        self.bob_wallet.refresh_from_db()

        # Alice: 500 - 101 = 399
        assert self.alice_wallet.available_balance == Decimal("399.0000")
        # Bob: 100 + 100 = 200
        assert self.bob_wallet.available_balance == Decimal("200.0000")

        # Verify Double-Entry Accounting Invariant: Sum(Debits) == Sum(Credits)
        entries = LedgerEntry.objects.filter(transaction=txn)
        total_debits = sum(e.amount for e in entries if e.entry_type == LedgerEntryType.DEBIT)
        total_credits = sum(e.amount for e in entries if e.entry_type == LedgerEntryType.CREDIT)

        assert total_debits == Decimal("101.0000")
        assert total_credits == Decimal("101.0000")
        assert total_debits == total_credits

    def test_insufficient_balance_rollback(self):
        with pytest.raises(InsufficientBalanceException):
            TransferService.execute_transfer(
                sender_user=self.alice,
                receiver_wallet_number=self.bob_wallet.wallet_number,
                amount=Decimal("600.0000"),
                pin="123456"
            )

        self.alice_wallet.refresh_from_db()
        self.bob_wallet.refresh_from_db()
        # Balances untouched
        assert self.alice_wallet.available_balance == Decimal("500.0000")
        assert self.bob_wallet.available_balance == Decimal("100.0000")
        assert not Transaction.objects.filter(sender_wallet=self.alice_wallet).exists()

    def test_self_transfer_prohibited(self):
        with pytest.raises(SelfTransferException):
            TransferService.execute_transfer(
                sender_user=self.alice,
                receiver_wallet_number=self.alice_wallet.wallet_number,
                amount=Decimal("50.0000"),
                pin="123456"
            )

    def test_idempotency_prevents_duplicate_charge(self):
        self.client.force_authenticate(user=self.alice)
        idempotency_key = str(uuid.uuid4())

        payload = {
            "receiver_wallet_number": self.bob_wallet.wallet_number,
            "amount": "50.0000",
            "description": "Test Idempotent Transfer",
            "pin": "123456",
        }

        # First request
        res1 = self.client.post(
            reverse("transfers:transfer_list_create"),
            payload,
            format="json",
            HTTP_IDEMPOTENCY_KEY=idempotency_key
        )
        assert res1.status_code == status.HTTP_201_CREATED
        txn_code_1 = res1.data["data"]["transaction_code"]

        # Duplicate request with same Idempotency-Key
        res2 = self.client.post(
            reverse("transfers:transfer_list_create"),
            payload,
            format="json",
            HTTP_IDEMPOTENCY_KEY=idempotency_key
        )
        assert res2.status_code in [status.HTTP_200_OK, status.HTTP_201_CREATED]
        txn_code_2 = res2.data["data"]["transaction_code"]

        # Identical transaction returned, no second deduction
        assert txn_code_1 == txn_code_2

        self.alice_wallet.refresh_from_db()
        # 500 - (50 + 1 fee) = 449 (debited only once!)
        assert self.alice_wallet.available_balance == Decimal("449.0000")
        assert Transaction.objects.count() == 1

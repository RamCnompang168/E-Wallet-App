import secrets
from decimal import Decimal
from fastapi import HTTPException
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession
from ..models import Transaction, TransactionStatus, TransactionType, Wallet, WalletStatus

class TransferService:
    """Financial mutations are serialized by locking both wallet rows in one order."""
    def __init__(self, session: AsyncSession): self.session = session

    async def send(self, sender_id, receiver_number: str, amount: Decimal, key: str, notes: str | None = None) -> Transaction:
        if not key or len(key) > 64: raise HTTPException(400, 'A valid Idempotency-Key is required')
        existing = await self.session.scalar(select(Transaction).where(Transaction.idempotency_key == key))
        if existing: return existing
        receiver_id = await self.session.scalar(select(Wallet.id).where(Wallet.wallet_number == receiver_number))
        if receiver_id is None: raise HTTPException(404, 'Recipient wallet not found')
        if receiver_id == sender_id: raise HTTPException(400, 'Cannot send money to the same wallet')
        # Deterministic lock order prevents deadlocks under concurrent transfers.
        ids = sorted([sender_id, receiver_id], key=str)
        wallets = (await self.session.scalars(select(Wallet).where(Wallet.id.in_(ids)).with_for_update())).all()
        locked = {wallet.id: wallet for wallet in wallets}
        sender, receiver = locked.get(sender_id), locked.get(receiver_id)
        if not sender or not receiver: raise HTTPException(404, 'Wallet not found')
        if sender.status != WalletStatus.ACTIVE or receiver.status != WalletStatus.ACTIVE: raise HTTPException(409, 'Wallet unavailable')
        fee = Decimal('0.0000')
        if sender.balance < amount + fee: raise HTTPException(400, 'Insufficient Balance')
        sender.balance -= amount + fee
        receiver.balance += amount
        record = Transaction(reference_no=f'NP-{secrets.token_hex(8).upper()}', sender_wallet_id=sender.id, receiver_wallet_id=receiver.id, amount=amount, fee=fee, transaction_type=TransactionType.SEND, status=TransactionStatus.COMPLETED, notes=notes, idempotency_key=key)
        self.session.add(record)
        try:
            await self.session.flush()
        except IntegrityError:
            # Concurrent retry may have inserted the same idempotency key.
            await self.session.rollback()
            replay = await self.session.scalar(select(Transaction).where(Transaction.idempotency_key == key))
            if replay: return replay
            raise
        return record

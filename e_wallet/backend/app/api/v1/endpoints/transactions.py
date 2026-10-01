from fastapi import APIRouter, Depends, Header, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from ....core.db import get_session
from ....models import Transaction, User, Wallet
from ....schemas import SendMoneyRequest, TransactionResponse
from ....services.transfers import TransferService
from ...deps import current_user, require_pin

router = APIRouter(tags=['Transactions'])

@router.get('/transactions', response_model=list[TransactionResponse])
async def list_transactions(
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
):
    wallet = await session.scalar(select(Wallet).where(Wallet.user_id == user.id))
    if not wallet:
        raise HTTPException(status.HTTP_404_NOT_FOUND, 'Wallet not found')
    transactions = (
        await session.scalars(
            select(Transaction)
            .where(
                (Transaction.sender_wallet_id == wallet.id)
                | (Transaction.receiver_wallet_id == wallet.id)
            )
            .order_by(Transaction.created_at.desc())
            .limit(100)
        )
    ).all()
    return transactions

@router.post('/transactions/send', response_model=TransactionResponse, status_code=status.HTTP_201_CREATED)
async def send_money(
    body: SendMoneyRequest,
    idempotency_key: str = Header(..., alias='Idempotency-Key'),
    user: User = Depends(require_pin),
    session: AsyncSession = Depends(get_session),
):
    async with session.begin():
        sender = await session.scalar(select(Wallet).where(Wallet.user_id == user.id))
        if not sender:
            raise HTTPException(status.HTTP_404_NOT_FOUND, 'Wallet not found')
        result = await TransferService(session).send(
            sender.id,
            body.receiver_wallet_number,
            body.amount,
            idempotency_key,
            body.notes,
        )
    return result

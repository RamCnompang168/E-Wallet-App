from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from ....core.db import get_session
from ....models import User, Wallet
from ...deps import current_user

router = APIRouter(tags=['Wallets'])

@router.get('/wallet')
async def get_wallet(
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
):
    account = await session.scalar(select(Wallet).where(Wallet.user_id == user.id))
    if not account:
        raise HTTPException(status.HTTP_404_NOT_FOUND, 'Wallet not found')
    return {
        'wallet_number': account.wallet_number,
        'balance': account.balance,
        'currency': account.currency,
        'status': account.status,
    }

import uuid
import jwt
from fastapi import Depends, Header, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from ..core.config import settings
from ..core.db import get_session
from ..core.security import verify_secret
from ..models import User

async def current_user(
    authorization: str = Header(...),
    session: AsyncSession = Depends(get_session),
) -> User:
    try:
        token = authorization.removeprefix('Bearer ').strip()
        subject = jwt.decode(
            token,
            settings.jwt_secret,
            algorithms=[settings.jwt_algorithm],
        )['sub']
        user = await session.get(User, uuid.UUID(subject))
    except Exception as exc:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, 'Invalid access token') from exc
    if not user or user.is_locked:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, 'Account unavailable')
    return user

async def require_pin(
    pin: str = Header(..., alias='x-transaction-pin'),
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
) -> User:
    # A production deployment additionally places this counter/15-minute expiry in Redis.
    if not user.pin_hash or not verify_secret(pin, user.pin_hash):
        user.pin_retry_count += 1
        if user.pin_retry_count >= 3:
            user.is_locked = True
        await session.commit()
        raise HTTPException(status.HTTP_403_FORBIDDEN, 'Invalid transaction PIN')
    if user.pin_retry_count:
        user.pin_retry_count = 0
        await session.commit()
    return user

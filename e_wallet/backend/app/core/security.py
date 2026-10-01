from datetime import datetime, timedelta, timezone
import jwt
from argon2 import PasswordHasher
from .config import settings

hasher = PasswordHasher()

def hash_secret(value: str) -> str:
    return hasher.hash(value)

def verify_secret(value: str, digest: str) -> bool:
    try:
        return hasher.verify(digest, value)
    except Exception:
        return False

def access_token(subject: str) -> str:
    payload = {
        'sub': subject,
        'exp': datetime.now(timezone.utc) + timedelta(minutes=15),
    }
    return jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)

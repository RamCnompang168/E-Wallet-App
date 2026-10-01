# Re-export from core for backward compatibility
from .core.security import access_token, hash_secret, hasher, verify_secret

__all__ = ['access_token', 'hash_secret', 'hasher', 'verify_secret']

# Re-export from core for backward compatibility
from .core.db import SessionLocal, engine, get_session

__all__ = ['SessionLocal', 'engine', 'get_session']

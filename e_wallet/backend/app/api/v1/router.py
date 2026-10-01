from fastapi import APIRouter
from .endpoints.health import router as health_router
from .endpoints.transactions import router as transactions_router
from .endpoints.wallets import router as wallets_router

api_router = APIRouter()

api_router.include_router(health_router)
api_router.include_router(wallets_router)
api_router.include_router(transactions_router)

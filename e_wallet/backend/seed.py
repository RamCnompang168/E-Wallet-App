import asyncio
from decimal import Decimal
from app.db import SessionLocal, engine
from app.models import Base, User, Wallet
from app.security import hash_secret

async def main():
    async with engine.begin() as connection: await connection.run_sync(Base.metadata.create_all)
    async with SessionLocal() as session:
        if await session.get(User, '00000000-0000-0000-0000-000000000001'): return
        a=User(id='00000000-0000-0000-0000-000000000001', phone_number='+85512000001', email='jordan@example.com', full_name='Jordan Davis', password_hash=hash_secret('DemoPass!1'), pin_hash=hash_secret('123456'))
        b=User(id='00000000-0000-0000-0000-000000000002', phone_number='+85512000002', email='sophia@example.com', full_name='Sophia Martinez', password_hash=hash_secret('DemoPass!1'), pin_hash=hash_secret('654321'))
        session.add_all([a,b,Wallet(user_id=a.id,wallet_number='NP73904892',balance=Decimal('12450.8000')),Wallet(user_id=b.id,wallet_number='NP90817263',balance=Decimal('250.0000'))]); await session.commit()
if __name__ == '__main__': asyncio.run(main())

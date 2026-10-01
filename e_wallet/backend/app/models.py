import enum
import uuid
from datetime import datetime
from decimal import Decimal
from sqlalchemy import Boolean, CheckConstraint, DateTime, Enum, ForeignKey, Integer, Numeric, String, Text, func
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column

class Base(DeclarativeBase): pass
class Role(str, enum.Enum): USER='USER'; ADMIN='ADMIN'
class WalletStatus(str, enum.Enum): ACTIVE='ACTIVE'; FROZEN='FROZEN'; CLOSED='CLOSED'
class TransactionType(str, enum.Enum): SEND='SEND'; RECEIVE='RECEIVE'; DEPOSIT='DEPOSIT'; WITHDRAW='WITHDRAW'; QR_PAYMENT='QR_PAYMENT'
class TransactionStatus(str, enum.Enum): PENDING='PENDING'; COMPLETED='COMPLETED'; FAILED='FAILED'; REVERSED='REVERSED'

class User(Base):
    __tablename__='users'
    id: Mapped[uuid.UUID]=mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    phone_number: Mapped[str]=mapped_column(String(32), unique=True, index=True)
    email: Mapped[str]=mapped_column(String(320), unique=True, index=True)
    full_name: Mapped[str]=mapped_column(String(160))
    password_hash: Mapped[str]=mapped_column(Text)
    pin_hash: Mapped[str|None]=mapped_column(String(256), nullable=True)
    pin_retry_count: Mapped[int]=mapped_column(Integer, default=0)
    is_locked: Mapped[bool]=mapped_column(Boolean, default=False)
    role: Mapped[Role]=mapped_column(Enum(Role), default=Role.USER)
    created_at: Mapped[datetime]=mapped_column(DateTime(timezone=True), server_default=func.now())

class Wallet(Base):
    __tablename__='wallets'; __table_args__=(CheckConstraint('balance >= 0', name='wallet_balance_non_negative'),)
    id: Mapped[uuid.UUID]=mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID]=mapped_column(ForeignKey('users.id'), unique=True, index=True)
    wallet_number: Mapped[str]=mapped_column(String(12), unique=True, index=True)
    currency: Mapped[str]=mapped_column(String(3), default='USD')
    balance: Mapped[Decimal]=mapped_column(Numeric(18,4), default=Decimal('0'))
    status: Mapped[WalletStatus]=mapped_column(Enum(WalletStatus), default=WalletStatus.ACTIVE)
    created_at: Mapped[datetime]=mapped_column(DateTime(timezone=True), server_default=func.now())

class Transaction(Base):
    __tablename__='transactions'
    id: Mapped[uuid.UUID]=mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    reference_no: Mapped[str]=mapped_column(String(32), unique=True, index=True)
    sender_wallet_id: Mapped[uuid.UUID|None]=mapped_column(ForeignKey('wallets.id'), nullable=True)
    receiver_wallet_id: Mapped[uuid.UUID|None]=mapped_column(ForeignKey('wallets.id'), nullable=True)
    amount: Mapped[Decimal]=mapped_column(Numeric(18,4))
    fee: Mapped[Decimal]=mapped_column(Numeric(18,4), default=Decimal('0'))
    transaction_type: Mapped[TransactionType]=mapped_column(Enum(TransactionType))
    status: Mapped[TransactionStatus]=mapped_column(Enum(TransactionStatus), default=TransactionStatus.PENDING)
    notes: Mapped[str|None]=mapped_column(Text, nullable=True)
    idempotency_key: Mapped[str]=mapped_column(String(64), unique=True)
    created_at: Mapped[datetime]=mapped_column(DateTime(timezone=True), server_default=func.now())

class AuditLog(Base):
    __tablename__='audit_logs'
    id: Mapped[uuid.UUID]=mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID|None]=mapped_column(ForeignKey('users.id'), nullable=True)
    action: Mapped[str]=mapped_column(String(100)); ip_address: Mapped[str|None]=mapped_column(String(64), nullable=True)
    metadata_: Mapped[dict|None]=mapped_column('metadata', JSONB, nullable=True)
    created_at: Mapped[datetime]=mapped_column(DateTime(timezone=True), server_default=func.now())

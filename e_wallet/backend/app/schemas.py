from decimal import Decimal
from pydantic import BaseModel, Field, field_validator

class SendMoneyRequest(BaseModel):
    receiver_wallet_number: str = Field(pattern=r'^[A-Z0-9]{6,12}$')
    amount: Decimal = Field(gt=0, max_digits=18, decimal_places=4)
    notes: str | None = Field(default=None, max_length=500)
    @field_validator('amount')
    @classmethod
    def finite_amount(cls, value: Decimal):
        if not value.is_finite(): raise ValueError('Amount must be finite')
        return value

class TransactionResponse(BaseModel):
    reference_no: str; status: str; amount: Decimal; fee: Decimal
    model_config = {'from_attributes': True}

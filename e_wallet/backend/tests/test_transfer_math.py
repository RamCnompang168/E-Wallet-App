from decimal import Decimal

def debit(balance: Decimal, amount: Decimal, fee: Decimal = Decimal('0')) -> Decimal:
    if balance < amount + fee:
        raise ValueError('Insufficient Balance')
    return balance - amount - fee

def test_transfer_preserves_total_value():
    left, right = Decimal('100.0000'), Decimal('20.0000')
    sent = Decimal('15.2500')
    assert debit(left, sent) + right + sent == left + right

def test_insufficient_balance_is_rejected():
    try:
        debit(Decimal('10.0000'), Decimal('10.0001'))
    except ValueError as error:
        assert str(error) == 'Insufficient Balance'
    else:
        raise AssertionError('Expected insufficient balance failure')

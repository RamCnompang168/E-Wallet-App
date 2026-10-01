# NovaPay API

Run a PostgreSQL 16 instance, set `DATABASE_URL` and `JWT_SECRET` in `backend/.env`, then install and start:

```powershell
cd backend
py -m pip install -r requirements.txt
py seed.py
py -m uvicorn app.main:app --reload
```

`POST /transactions/send` requires an access token, `x-transaction-pin`, and an `Idempotency-Key`. The transfer service locks sender and receiver wallet records in deterministic order before checking and changing balances; the transaction record is persisted in the same database commit.

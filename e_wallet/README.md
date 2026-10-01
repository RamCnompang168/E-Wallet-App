# NovaPay e-wallet

A dark-first Flutter mobile wallet experience with a FastAPI/PostgreSQL backend foundation.

## Mobile app

```powershell
flutter run
```

The app includes an animated balance card, activity feed, cash-flow chart, QR receive sheet, profile/theme controls, and a complete local send-money flow through review and receipt.

## API

See [backend/README.md](backend/README.md) for local setup. The transfer service uses a database transaction, deterministic `FOR UPDATE` locks on both wallets, balance checks, and an idempotency key to prevent double-spending and replayed transfers.

## Verification

```powershell
flutter analyze
flutter test
```

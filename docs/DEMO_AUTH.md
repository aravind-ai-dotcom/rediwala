# Demo Authentication Seeding

Development-only process for synthetic Customer and Vendor accounts.

## Prerequisites

1. Firebase project `rediwala-development`
2. Email/Password provider enabled (also declared in `firebase.json`)
3. Service account JSON path (never commit the real file)
4. Deployed RTDB rules from `firebase/database.rules.json`

## Commands

```bash
cd firebase
npm run seed:demo-auth:dry

CONFIRM_DEV_SEED=yes \
FIREBASE_SERVICE_ACCOUNT_PATH=/absolute/path/to/serviceAccount.json \
npm run seed:demo-auth
```

Deploy rules:

```bash
npx -y firebase-tools@latest deploy --only database --project rediwala-development
```

## Summary printed on success

- 5 Customer accounts verified
- 5 Vendor accounts verified
- 20 Supporting vendors seeded
- 2 Neighborhood clusters seeded
- Live / Scheduled scenarios configured

Passwords are used only for Auth user create/update. They are never written to RTDB.

# Demo Authentication Seeding

Development-only process for synthetic Customer and Vendor accounts.

Full developer workflow (dry run, emulator, remote, ADC): see **`firebase/README.md`**.

## Project location

```text
/Users/aravind/Developer/RediWala/firebase
```

## Quick commands

```bash
cd /Users/aravind/Developer/RediWala/firebase
npm install

# Mode A — dry run (no credentials)
npm run seed:demo-auth:dry

# Mode B — emulator
# (start emulators first)
npm run seed:demo-auth:emulator

# Mode C — remote development
export FIREBASE_SERVICE_ACCOUNT_PATH=/path/to/service-account.json
CONFIRM_DEV_SEED=yes npm run seed:demo-auth
```

## Accounts

See `firebase/src/demoAuthPersonas.js` for the five Customer and five Vendor demo identities.
Passwords are used only for Auth create/update and are never stored in RTDB.

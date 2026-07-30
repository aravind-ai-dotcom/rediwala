# RediWala Firebase tools

Project location:

```text
/Users/aravind/Developer/RediWala/firebase
```

These scripts seed **development** data for `rediwala-development`.
They never target production unless you deliberately override safety flags.

Related docs:

- `docs/DEMO_AUTH.md` — demo accounts and personas
- `docs/FIREBASE_SEEDING.md` — catalog / schema v2 RTDB seed

---

## Setup

```bash
cd /Users/aravind/Developer/RediWala/firebase
npm install
```

Do **not** commit service-account JSON files.

---

## Typical workflow

### 1) Dry run (no credentials)

Validates personas, paths, and duplicates. Writes a local preview only.

```bash
cd /Users/aravind/Developer/RediWala/firebase
npm run seed:demo-auth:dry
```

Expected output includes:

- Persona validation OK
- Generated preview path
- Customer / vendor / supporting / scenario counts

### 2) Firebase Emulator (no service account)

Start emulators (from this folder or the repo root that contains `firebase.json`):

```bash
cd /Users/aravind/Developer/RediWala
npx -y firebase-tools@latest emulators:start --only auth,database --project rediwala-development
```

In another terminal:

```bash
cd /Users/aravind/Developer/RediWala/firebase
npm run seed:demo-auth:emulator
```

Emulator mode auto-detects `FIREBASE_AUTH_EMULATOR_HOST` /
`FIREBASE_DATABASE_EMULATOR_HOST`, or you can force it with `--emulator`.

### 3) Remote development project

Only `rediwala-development` is allowed.

#### Option A — Service account JSON

1. Firebase Console → Project settings → Service accounts  
2. Generate a new private key  
3. Store it **outside the repo**, e.g. `~/secrets/rediwala-development-sa.json`

```bash
export FIREBASE_SERVICE_ACCOUNT_PATH=~/secrets/rediwala-development-sa.json
export FIREBASE_PROJECT_ID=rediwala-development
CONFIRM_DEV_SEED=yes npm run seed:demo-auth
```

#### Option B — Application Default Credentials (ADC)

```bash
gcloud auth application-default login
export GOOGLE_CLOUD_PROJECT=rediwala-development
CONFIRM_DEV_SEED=yes npm run seed:demo-auth
```

If neither a service account path nor ADC is available, the script prints a
friendly setup guide instead of a raw missing-env error.

---

## Demo-auth scripts

| Script | Purpose |
|--------|---------|
| `npm run seed:demo-auth:dry` | Validate + preview only |
| `npm run seed:demo-auth:emulator` | Seed Auth + RTDB emulators |
| `npm run seed:demo-auth` | Seed remote development (needs credentials + `CONFIRM_DEV_SEED=yes`) |
| `npm run seed:customers` | Customers only |
| `npm run seed:vendors` | Login vendors + supporting vendors |
| `npm run seed:scenarios` | Live / scheduled / expiring status snapshots |
| `npm run seed:reset-demo` | Clear demo roots, then full reseed (`CONFIRM_DEV_RESET=yes` for remote) |
| `npm run seed:all` | Full demo-auth seed |
| `npm run emulators` | Convenience wrapper to start Auth + Database emulators |

Legacy catalog seed (schema v2 neighborhoods/categories/vendors):

```bash
npm run seed:dry
CONFIRM_DEV_SEED=yes npm run seed
CONFIRM_DEV_SEED=yes CONFIRM_DEV_RESET=yes npm run reset
```

---

## Authentication methods supported

1. **None** — dry run  
2. **Emulator** — no service account  
3. **Service account JSON** via `FIREBASE_SERVICE_ACCOUNT_PATH`  
4. **ADC** via `gcloud auth application-default login`

Passwords are used only for Firebase Authentication create/update.
They are **never** written into Realtime Database documents.

---

## Safety rails

- Allowed remote project: **`rediwala-development`** only  
- Emulator mode is allowed without a service account  
- Remote writes require `CONFIRM_DEV_SEED=yes`  
- Remote demo reset requires `CONFIRM_DEV_RESET=yes`  
- Explicit non-dev override requires both:
  - `ALLOW_NON_DEV_PROJECT=yes`
  - `CONFIRM_FORCE_SEED=yes`  
- Dry-run never writes to Firebase  

---

## Expected success summary

```text
5 Customer accounts verified
5 Vendor accounts verified
20 Supporting vendors seeded
2 Neighborhood clusters seeded
25 Live or Scheduled scenarios configured
```

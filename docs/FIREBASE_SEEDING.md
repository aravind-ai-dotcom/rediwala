# RediWala Firebase Seeding Guide

Repeatable development seeding for **rediwala-development** Realtime Database (schema **v2**).

The iOS apps are **not** connected to this data yet.

---

## Prerequisites

```bash
cd firebase
npm install
```

1. Create a service account key for `rediwala-development` (Firebase Console → Project settings → Service accounts).  
2. Store it **outside the repo**, e.g. `~/secrets/rediwala-development-sa.json`.  
3. Never commit real credentials (`serviceAccount*.json` is gitignored).

```bash
export FIREBASE_SERVICE_ACCOUNT_PATH=~/secrets/rediwala-development-sa.json
export FIREBASE_PROJECT_ID=rediwala-development
# Optional if your RTDB URL differs:
# export FIREBASE_DATABASE_URL=https://….firebasedatabase.app
```

---

## Commands

| Command | Effect |
|---------|--------|
| `npm run seed:dry` / `npm run dry` | Build dataset + write `generated/seed-preview.json` (no remote) |
| `npm run validate` | Validate local/generated payload |
| `npm run seed` | Write payload to development RTDB (`CONFIRM_DEV_SEED=yes`) |
| `npm run reset` | Clear current + legacy roots, then reseed (`CONFIRM_DEV_SEED=yes` + `CONFIRM_DEV_RESET=yes`) |
| `npm run validate:remote` | Validate live development database |

### Dry run (always do this first)

```bash
cd firebase
npm run seed:dry
npm run validate
```

### Seed development

```bash
CONFIRM_DEV_SEED=yes npm run seed
```

### Reset + reseed development

```bash
CONFIRM_DEV_SEED=yes CONFIRM_DEV_RESET=yes npm run reset
npm run validate:remote
```

Reset clears:

- All v2 roots (`metadata`, `cities`, `vendors`, …)  
- Legacy v1 roots (`sellers`, `seller_*`, `announcements`, `category_groups`)

---

## Safety rails

- Allowed project ID: **`rediwala-development` only**  
- Remote write requires `CONFIRM_DEV_SEED=yes`  
- Reset requires `CONFIRM_DEV_RESET=yes`  
- Dry-run needs **no** credentials  
- Scripts exit non-zero on failure  

---

## What the seed creates (approximate)

| Entity | Count |
|--------|------:|
| Cities | 4 (1 pilot + 3 disabled shells) |
| Category groups | 4 |
| Categories | 17 |
| Neighborhoods | 3 |
| Vendors | 40 |
| Live vendors | ~13 |
| Locations | 40 |
| Routes | 28 |
| Announcements | 22 |
| Customers | 20 |
| Customer settings | 20 |
| Favorite links | ~60 |

Exact numbers are printed by the seed/validate scripts.

---

## Manual Firebase Console inspection

1. Open [Firebase Console](https://console.firebase.google.com/) → **rediwala-development**  
2. **Realtime Database**  
3. Confirm roots from `docs/FIREBASE_SCHEMA.md`  
4. Spot-check:
   - `/vendors/vendor_001`
   - `/vendor_locations/vendor_001`
   - `/vendor_routes/vendor_001`
   - `/vendor_announcements/vendor_001`
   - `/customer_favorites/customer_001`
5. Confirm `metadata.schemaVersion == "2.0"` and `environment == "development"`

More samples: `docs/FIREBASE_DATA_INSPECTION.md` (update mentally for `vendor_*` paths if an older sample still says `seller_*`).

---

## Database rules

Proposed file: `firebase/database.rules.json`  
Referenced from root `firebase.json` under `database.rules`.

**Do not deploy** unless explicitly authorized:

```bash
# Only when authorized
# npx firebase-tools deploy --only database --project rediwala-development
```

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `Refusing to run against project` | Use `rediwala-development` only |
| Missing service account | Set `FIREBASE_SERVICE_ACCOUNT_PATH` |
| RTDB URL errors | Set `FIREBASE_DATABASE_URL` to your instance URL |
| Validation fails on old preview | Re-run `npm run seed:dry` then `npm run validate` |
| Stale `sellers` node in console | Run `npm run reset` to clear legacy roots |

---

## Next sprint (after seeding is verified in Console)

**Read-only `FirebaseSellerRepository` / `FirebaseVendorRepository`** behind a feature flag, mapping `vendors` + companion nodes → existing iOS models, with `LocalSellerRepository` as fallback.

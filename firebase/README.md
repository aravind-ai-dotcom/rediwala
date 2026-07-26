# RediWala Firebase seed tools

Permanent **schema v2** seed + validation for `rediwala-development`.

iOS continues to use **`LocalSellerRepository`**. These tools do not modify Xcode targets.

Full instructions: **`docs/FIREBASE_SEEDING.md`**

```bash
npm install
npm run seed:dry
npm run validate

CONFIRM_DEV_SEED=yes npm run seed
CONFIRM_DEV_SEED=yes CONFIRM_DEV_RESET=yes npm run reset
```

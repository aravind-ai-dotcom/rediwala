# Firebase Data Inspection — Permanent Schema v2

Inspect synthetic Chennai pilot data in **rediwala-development** Realtime Database.

---

## Open the console

1. [Firebase Console](https://console.firebase.google.com/)  
2. Project **rediwala-development**  
3. **Build → Realtime Database**

---

## Expected root nodes (v2)

`metadata` · `cities` · `neighborhoods` · `categoryGroups` · `categories` · `vendors` · `vendor_status` · `vendor_locations` · `vendor_routes` · `vendor_announcements` · `customers` · `customer_favorites` · `customer_settings`

If you still see `sellers` / `seller_*`, run `npm run reset` from `firebase/` to clear legacy roots.

---

## Sample vendor

`/vendors/vendor_001`

```json
{
  "id": "vendor_001",
  "displayName": "Murugan",
  "businessName": "Murugan Cart",
  "categoryId": "vegetables",
  "cityId": "chennai",
  "neighborhoodId": "t_nagar",
  "languages": ["ta", "en"],
  "photoURL": null,
  "phone": null,
  "verified": false,
  "descriptionEnglish": "…",
  "descriptionTamil": "…"
}
```

## Sample location

`/vendor_locations/vendor_001` — Chennai lat/lng near T. Nagar landmarks, with `heading`, `speed`, `accuracy`, `updatedAt`.

## Sample route

`/vendor_routes/vendor_001/stops` — 3–5 morning stops with `time`, titles, coordinates, `status`.

## Sample announcement metadata

`/vendor_announcements/vendor_001` — `storagePath` placeholder only; no audio upload.

## Sample favorite

`/customer_favorites/customer_001/vendor_007: true`

---

## Manual checklist

- [ ] `metadata.schemaVersion` is `2.0`  
- [ ] `cities/chennai.pilot` is true  
- [ ] Three Chennai neighborhoods present  
- [ ] ~40 vendors; every pilot neighborhood has vendors  
- [ ] `tailor` / `sofa_repair` have `comingSoon: true`  
- [ ] Live status roughly one-third of vendors  
- [ ] Coordinates look Chennai-local (not US defaults)  
- [ ] iOS app still runs on local data unchanged  

---

## Reseed / validate

See `docs/FIREBASE_SEEDING.md`.

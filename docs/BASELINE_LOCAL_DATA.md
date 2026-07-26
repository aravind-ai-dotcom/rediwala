# RediWala Local Synthetic Data Baseline

**Baseline name:** RediWala Local Synthetic Data Baseline  
**Date:** 2026-07-27  
**Scope:** Stabilize current Chennai pilot UI + local synthetic data before Firebase database integration.

---

## Architecture

```
RediWalaCustomerApp
├── AppLanguageStore (EN / TA)
├── FavoritesViewModel
│   └── LocalSellerRepository  ← single source of truth for sellers + favorites
└── CustomerContentView (onboarding → main)
    └── CustomerRootView
        ├── Home (list + MapKit)
        ├── Favorites
        └── Profile / Settings

UI → ViewModels → SellerRepository (protocol) → LocalSellerRepository
```

- **Active seller data source:** `LocalSellerRepository`
- **Synthetic dataset:** `SyntheticChennaiData` (18 sellers)
- **Protocol for future swap:** `SellerRepository`
- Firebase is configured for Auth/bootstrap only; **no database reads or writes** in this baseline.

Vendor target remains local/onboarding UI with the same Firebase `configure()` pattern and **no Firestore/Realtime Database usage**.

---

## Pilot areas

| Area | English | Tamil label key |
|------|---------|-----------------|
| T. Nagar | T. Nagar | `neighborhood.tNagar` / `.ta_label` |
| West Mambalam | West Mambalam | `neighborhood.westMambalam` |
| Thiruvanmiyur | Thiruvanmiyur | `neighborhood.thiruvanmiyur` |

Map and list browsing center on these Chennai coordinates only (no US/default MapKit locations).

---

## Seller categories

### Fresh & Daily
Vegetables, Fruits, Flowers, Milk, Fish, Bakery

### Neighborhood Services
Knife Sharpening, Cobbler, Tailor *(Coming Soon)*, Sofa and Couch Repair *(Coming Soon)*

### Recycling Buyers
Old Newspapers, Plastic, Cardboard, Metal Scrap

### Street Treats
Kulfi, Roasted Corn, Peanuts

Coming Soon categories are visible but **not selectable**.

---

## Customer features currently working

- Onboarding: language, welcome, location soft-gate (no live GPS request)
- Home greeting + neighborhood switcher (T. Nagar / West Mambalam / Thiruvanmiyur)
- Category group browsing
- Nearby Now seller list (synthetic)
- Map / List switch with MapKit annotations
- Seller detail: photo placeholder, status, favorite, languages, hours, description
- My Day route timeline
- Sample announcement play/pause mock UI
- Favorites heart sync across home, map preview, detail, favorites tab
- English + Tamil localization
- Dark Mode + Dynamic Type-friendly layouts
- Scrollable onboarding and main screens on smaller phones

---

## Vendor features currently working

- Splash → language → welcome → name entry (no suggested-name chips) → business category → working hours → main tabs
- Vendor Home (status, GO LIVE UI, summary, quick actions)
- Inventory / Earnings / Profile / Settings (local mock)
- Profile photo placeholder (no camera / photo library)
- English + Tamil localization
- Scrollable onboarding on smaller devices
- Firebase `FirebaseApp.configure()` only (unchanged; no DB calls)

---

## Deferred features (intentionally not in this baseline)

- Firestore / Realtime Database
- Firebase Auth product flows beyond existing configure
- Live GPS / vendor location publishing
- Camera and photo-library access
- Vendor audio recording / live broadcast
- Push notifications
- Turn-by-turn route navigation
- Payments
- Ratings submission
- Persistent favorites across app relaunch

---

## Known limitations

- Favorites are **in-memory for the session** only
- Announcement audio is a **mock timer UI** (no bundled audio file)
- Directions and Call buttons are disabled placeholders
- Seller photos use initials placeholders (no remote images)
- Map uses selected pilot neighborhood center (not device GPS)
- Customer and Vendor targets each keep their own model copies (`AppLanguage`, themes, etc.)

---

## Manual verification checklist

### Customer (`RediWalaCustomer`)

- [ ] App launches
- [ ] Home scrolls
- [ ] Categories display (including Coming Soon)
- [ ] Map displays pins
- [ ] Map / list switch works
- [ ] Seller cards open details
- [ ] Seller details display My Day + announcement (when available)
- [ ] Favorites synchronize across screens
- [ ] Favorites tab updates
- [ ] Tamil strings render without severe truncation
- [ ] Dark Mode remains usable

### Vendor (`RediWalaVendor`)

- [ ] App launches
- [ ] Vendor onboarding works end-to-end
- [ ] Vendor Home scrolls
- [ ] Profile displays
- [ ] No Firebase database calls occur
- [ ] Existing Firebase initialization remains unchanged

---

## Build status (baseline gate)

Recorded during stabilization:

| Target | Configuration | Result |
|--------|---------------|--------|
| RediWalaCustomer | Debug, iPhone 17 simulator | Must succeed |
| RediWalaVendor | Debug, iPhone 17 simulator | Must succeed |

---

## Related docs

- `docs/FIREBASE_SCHEMA.md` — Realtime Database schema for the Chennai pilot seed (app still on local repo)
- `docs/FIREBASE_DATA_INSPECTION.md` — Console inspection & reseed steps
- `firebase/README.md` — Seed / validate commands

## Recommended next step after this baseline

Implement a read-only `FirebaseSellerRepository` conforming to `SellerRepository`, map Realtime Database nodes to the existing `Seller` model, and inject it behind a flag — without rewriting discovery UI. Keep `LocalSellerRepository` as fallback until validation passes.
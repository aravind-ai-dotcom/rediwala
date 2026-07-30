/**
 * Idempotent demo Auth + RTDB seeder (development only).
 *
 * Separates Firebase Authentication account creation from RTDB profile seeding.
 * Never writes passwords into the database.
 *
 * Usage:
 *   CONFIRM_DEV_SEED=yes FIREBASE_SERVICE_ACCOUNT_PATH=./serviceAccount.json npm run seed:demo-auth
 *   npm run seed:demo-auth:dry
 */

import { readFileSync, existsSync, writeFileSync, mkdirSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import {
  ALLOWED_PROJECT_IDS,
  DEFAULT_DATABASE_URL,
  assertDevelopmentProject,
} from "./src/config.js";
import {
  DEMO_CUSTOMERS,
  DEMO_VENDORS,
  SUPPORTING_VENDORS,
} from "./src/demoAuthPersonas.js";

const __dirname = dirname(fileURLToPath(import.meta.url));
const GENERATED_DIR = join(__dirname, "generated");

function parseArgs(argv) {
  return {
    dryRun: argv.includes("--dry-run"),
    help: argv.includes("--help") || argv.includes("-h"),
  };
}

function printHelp() {
  console.log(`
RediWala demo authentication seeder (development only)

Usage:
  npm run seed:demo-auth:dry
  CONFIRM_DEV_SEED=yes FIREBASE_SERVICE_ACCOUNT_PATH=./sa.json npm run seed:demo-auth

Creates/updates:
  - 5 Customer Auth accounts + users/customers RTDB profiles
  - 5 Vendor Auth accounts + users/vendors/vendor_status/locations/routes
  - 20 supporting vendors (no Auth)
  - Deterministic Live / Expected / Expiring scenarios
`);
}

function isoMinutesFromNow(minutes) {
  return new Date(Date.now() + minutes * 60_000).toISOString();
}

function isoHoursFromNow(hours) {
  return isoMinutesFromNow(hours * 60);
}

function todayWindow(startHour, endHour) {
  const start = new Date();
  start.setHours(startHour, 0, 0, 0);
  const end = new Date();
  end.setHours(endHour, 0, 0, 0);
  return { start: start.toISOString(), end: end.toISOString() };
}

async function initAdmin() {
  const credentialPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;
  if (!credentialPath) {
    throw new Error("FIREBASE_SERVICE_ACCOUNT_PATH is required for remote seed.");
  }
  const absolute = resolve(credentialPath);
  if (!existsSync(absolute)) {
    throw new Error(`Service account file not found: ${absolute}`);
  }
  const serviceAccount = JSON.parse(readFileSync(absolute, "utf8"));
  const projectId = process.env.FIREBASE_PROJECT_ID || serviceAccount.project_id;
  assertDevelopmentProject(projectId);
  if (process.env.CONFIRM_DEV_SEED !== "yes") {
    throw new Error('Refusing remote write. Set CONFIRM_DEV_SEED=yes.');
  }
  const admin = await import("firebase-admin");
  if (!admin.default.apps.length) {
    admin.default.initializeApp({
      credential: admin.default.credential.cert(serviceAccount),
      databaseURL: DEFAULT_DATABASE_URL,
      projectId,
    });
  }
  return { admin: admin.default, projectId };
}

async function ensureAuthUser(auth, persona) {
  let user;
  try {
    user = await auth.getUserByEmail(persona.email);
    await auth.updateUser(user.uid, {
      password: persona.password,
      displayName: persona.displayName || persona.businessName,
      disabled: false,
    });
    return { uid: user.uid, created: false };
  } catch (error) {
    if (error.code !== "auth/user-not-found") throw error;
    user = await auth.createUser({
      email: persona.email,
      password: persona.password,
      displayName: persona.displayName || persona.businessName,
      emailVerified: true,
      disabled: false,
    });
    return { uid: user.uid, created: true };
  }
}

function buildVendorStatus(vendor, nowIso) {
  const interval = vendor.presencePolicy?.intervalMinutes ?? 60;
  if (vendor.initialStatus === "offline") {
    return {
      vendorId: vendor.vendorId,
      isLive: false,
      serviceMode: vendor.serviceMode,
      lastSeen: nowIso,
      availabilityTextEn: "Offline",
      isPresenceConfirmationRequired: false,
    };
  }

  if (vendor.initialStatus === "expected_soon") {
    const window = vendor.scheduledWindow
      ? todayWindow(vendor.scheduledWindow.startHour, vendor.scheduledWindow.endHour)
      : { start: isoHoursFromNow(2), end: isoHoursFromNow(5) };
    return {
      vendorId: vendor.vendorId,
      isLive: false,
      serviceMode: vendor.serviceMode,
      lastSeen: nowIso,
      availabilityTextEn: "Expected soon",
      scheduledClosingTime: window.end,
      scheduledStartTime: window.start,
      isPresenceConfirmationRequired: Boolean(vendor.presencePolicy?.confirmationRequired),
      presenceCheckIntervalMinutes: interval,
    };
  }

  let expiresAt = isoMinutesFromNow(vendor.sessionDurationMinutes ?? interval);
  let confirmedAt = nowIso;
  if (vendor.initialStatus === "expiring_soon") {
    const due = vendor.presenceDueInMinutes ?? 10;
    expiresAt = isoMinutesFromNow(due);
    confirmedAt = isoMinutesFromNow(-(interval - due));
  }

  return {
    vendorId: vendor.vendorId,
    sellerId: vendor.vendorId,
    isLive: true,
    serviceMode: vendor.serviceMode,
    lastSeen: nowIso,
    startedAt: nowIso,
    availabilityTextEn: "Live nearby",
    isPresenceConfirmationRequired: Boolean(vendor.presencePolicy?.confirmationRequired),
    presenceCheckIntervalMinutes: interval,
    presenceConfirmedAt: confirmedAt,
    presenceExpiresAt: expiresAt,
    scheduledClosingTime: expiresAt,
    lastLocationUpdateAt: nowIso,
    currentStop: vendor.currentStop ?? null,
    nextStop: vendor.nextStop ?? null,
  };
}

function buildDataset(uidByEmail) {
  const nowIso = new Date().toISOString();
  const updates = {};
  let customersVerified = 0;
  let vendorsVerified = 0;
  let supporting = 0;
  let scenarios = 0;

  for (const customer of DEMO_CUSTOMERS) {
    const uid = uidByEmail[customer.email];
    if (!uid) continue;
    customersVerified += 1;
    updates[`users/${uid}`] = {
      uid,
      email: customer.email,
      role: "customer",
      displayName: customer.displayName,
      preferredLanguage: customer.preferredLanguage,
      profileCompleted: true,
      createdAt: nowIso,
      updatedAt: nowIso,
      isDemoAccount: true,
    };
    updates[`customers/${uid}`] = {
      uid,
      displayName: customer.displayName,
      homeNeighborhood: customer.homeNeighborhood,
      homeAreaLabel: customer.homeAreaLabel,
      // Private — rules must keep this readable only by owner.
      homeCoordinate: customer.homeCoordinate,
      apartmentMetadata: customer.apartmentMetadata,
      todaysNeeds: customer.todaysNeeds,
      followedVendorIds: customer.followedVendorIds,
      savedVendorIds: customer.savedVendorIds,
      notificationPreferences: { nearbyLive: true, expectedSoon: true },
      preferredLanguage: customer.preferredLanguage,
      secondaryLanguage: customer.secondaryLanguage,
      persona: customer.persona,
      updatedAt: nowIso,
    };
    const favorites = {};
    for (const id of [...customer.followedVendorIds, ...customer.savedVendorIds]) {
      favorites[id] = true;
    }
    updates[`customer_favorites/${uid}`] = favorites;
  }

  const allVendors = [...DEMO_VENDORS, ...SUPPORTING_VENDORS];
  for (const vendor of allVendors) {
    const ownerUid = uidByEmail[vendor.email] || null;
    if (vendor.email && ownerUid) vendorsVerified += 1;
    else supporting += 1;

    updates[`vendors/${vendor.vendorId}`] = {
      id: vendor.vendorId,
      vendorId: vendor.vendorId,
      businessName: vendor.businessName,
      displayName: vendor.businessName,
      businessType: vendor.businessType,
      categoryId: vendor.businessType,
      serviceMode: vendor.serviceMode,
      primaryArea: vendor.primaryArea,
      neighborhoodId: vendor.primaryArea,
      operatingAreas: [vendor.primaryArea],
      primaryAreaLabel: vendor.primaryAreaLabel || null,
      announcement: vendor.announcement || "",
      workingHours: vendor.workingHours || "9:00 AM – 5:00 PM",
      reliability: vendor.reliability ?? 0.8,
      presencePolicy: vendor.presencePolicy || { confirmationRequired: false, intervalMinutes: 60 },
      affiliations: vendor.affiliations || null,
      isDemoAccount: true,
      isSupportingOnly: !ownerUid,
      profileImageURL: null,
      updatedAt: nowIso,
    };
    if (ownerUid) {
      updates[`vendors/${vendor.vendorId}`].ownerUid = ownerUid;
    }

    updates[`vendor_locations/${vendor.vendorId}`] = {
      vendorId: vendor.vendorId,
      latitude: vendor.coordinate.latitude,
      longitude: vendor.coordinate.longitude,
      neighborhoodId: vendor.primaryArea,
      landmark: vendor.primaryAreaLabel || vendor.businessName,
      updatedAt: nowIso,
    };

    updates[`vendor_status/${vendor.vendorId}`] = buildVendorStatus(vendor, nowIso);
    scenarios += 1;

    if (vendor.route?.length) {
      const route = {};
      vendor.route.forEach((stop, index) => {
        route[stop.id] = {
          ...stop,
          order: index,
          isCompleted: Boolean(vendor.currentStop) && index < vendor.route.findIndex((s) => s.title === vendor.currentStop),
          isCurrent: vendor.currentStop === stop.title,
        };
      });
      updates[`vendor_routes/${vendor.vendorId}`] = route;
    }

    if (vendor.announcement) {
      updates[`vendor_announcements/${vendor.vendorId}`] = {
        vendorId: vendor.vendorId,
        textEn: vendor.announcement,
        updatedAt: nowIso,
      };
    }

    if (ownerUid) {
      updates[`users/${ownerUid}`] = {
        uid: ownerUid,
        email: vendor.email,
        role: "vendor",
        displayName: vendor.businessName,
        preferredLanguage: "en",
        profileCompleted: true,
        vendorId: vendor.vendorId,
        createdAt: nowIso,
        updatedAt: nowIso,
        isDemoAccount: true,
      };
      updates[`vendorLiveSessions/${vendor.vendorId}`] = {
        sessionId: `${vendor.vendorId}_demo`,
        vendorId: vendor.vendorId,
        status: vendor.initialStatus,
        startedAt: nowIso,
        ...buildVendorStatus(vendor, nowIso),
        currentCoordinate: vendor.coordinate,
        currentArea: vendor.primaryAreaLabel || vendor.primaryArea,
        currentStop: vendor.currentStop || null,
        nextStop: vendor.nextStop || null,
        routeProgress: vendor.currentStop || null,
      };
    }
  }

  updates["demo_control/meta"] = {
    seededAt: nowIso,
    customers: DEMO_CUSTOMERS.length,
    vendors: DEMO_VENDORS.length,
    supportingVendors: SUPPORTING_VENDORS.length,
    neighborhoods: ["west_mambalam", "thiruvanmiyur"],
  };

  return {
    updates,
    summary: {
      customersVerified,
      vendorsVerified,
      supportingVendors: supporting,
      neighborhoodClusters: 2,
      scenariosConfigured: scenarios,
    },
  };
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.help) {
    printHelp();
    process.exit(0);
  }

  const uidByEmail = {};
  const authResults = { created: 0, updated: 0, failed: [] };

  if (args.dryRun) {
    for (const persona of [...DEMO_CUSTOMERS, ...DEMO_VENDORS]) {
      uidByEmail[persona.email] = `dry_${persona.key}`;
    }
    const { updates, summary } = buildDataset(uidByEmail);
    mkdirSync(GENERATED_DIR, { recursive: true });
    const previewPath = join(GENERATED_DIR, "demo-auth-preview.json");
    // Strip nothing sensitive beyond passwords (already excluded from updates).
    writeFileSync(previewPath, JSON.stringify({ summary, keys: Object.keys(updates).length, sample: updates }, null, 2));
    console.log(`Dry run preview → ${previewPath}`);
    console.log(`\n${summary.customersVerified} Customer accounts verified`);
    console.log(`${summary.vendorsVerified} Vendor accounts verified`);
    console.log(`${summary.supportingVendors} Supporting vendors seeded`);
    console.log(`${summary.neighborhoodClusters} Neighborhood clusters seeded`);
    console.log(`${summary.scenariosConfigured} Live or Scheduled scenarios configured`);
    return;
  }

  const { admin, projectId } = await initAdmin();
  console.log(`Seeding demo auth into project ${projectId}…`);
  const auth = admin.auth();
  const db = admin.database();

  for (const persona of [...DEMO_CUSTOMERS, ...DEMO_VENDORS]) {
    try {
      const result = await ensureAuthUser(auth, {
        ...persona,
        displayName: persona.displayName || persona.businessName,
      });
      uidByEmail[persona.email] = result.uid;
      if (result.created) authResults.created += 1;
      else authResults.updated += 1;
      console.log(`Auth OK  ${persona.email} → ${result.uid} (${result.created ? "created" : "updated"})`);
    } catch (error) {
      authResults.failed.push({ email: persona.email, message: error.message });
      console.error(`Auth FAIL ${persona.email}: ${error.message}`);
    }
  }

  const { updates, summary } = buildDataset(uidByEmail);
  await db.ref().update(updates);

  console.log("\n— Summary —");
  console.log(`${summary.customersVerified} Customer accounts verified`);
  console.log(`${summary.vendorsVerified} Vendor accounts verified`);
  console.log(`${summary.supportingVendors} Supporting vendors seeded`);
  console.log(`${summary.neighborhoodClusters} Neighborhood clusters seeded`);
  console.log(`${summary.scenariosConfigured} Live or Scheduled scenarios configured`);
  console.log(`Auth created=${authResults.created} updated=${authResults.updated} failed=${authResults.failed.length}`);
  if (authResults.failed.length) {
    process.exitCode = 1;
  }
}

main().catch((error) => {
  console.error(error.message || error);
  process.exit(1);
});

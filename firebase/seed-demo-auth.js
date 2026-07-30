/**
 * Idempotent demo Auth + RTDB seeder (development only).
 *
 * Separates Firebase Authentication account creation from RTDB profile seeding.
 * Never writes passwords into the database.
 *
 * Modes:
 *   A) Dry run     npm run seed:demo-auth:dry
 *   B) Emulator    npm run seed:demo-auth:emulator
 *   C) Remote      CONFIRM_DEV_SEED=yes npm run seed:demo-auth
 */

import { writeFileSync, mkdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import {
  credentialsHelpMessage,
  detectEmulatorMode,
  initFirebaseAdmin,
} from "./src/adminBootstrap.js";
import {
  DEMO_CUSTOMERS,
  DEMO_VENDORS,
  SUPPORTING_VENDORS,
} from "./src/demoAuthPersonas.js";

const __dirname = dirname(fileURLToPath(import.meta.url));
const GENERATED_DIR = join(__dirname, "generated");

function parseArgs(argv) {
  const has = (flag) => argv.includes(flag);
  const scoped =
    has("--customers") ||
    has("--vendors") ||
    has("--scenarios") ||
    has("--supporting");
  return {
    dryRun: has("--dry-run"),
    emulator: has("--emulator"),
    help: has("--help") || has("-h"),
    reset: has("--reset"),
    customers: has("--customers") || has("--all") || !scoped,
    vendors: has("--vendors") || has("--all") || !scoped,
    scenarios: has("--scenarios") || has("--all") || !scoped,
    supporting: has("--supporting") || has("--all") || !scoped,
    all: has("--all") || !scoped,
  };
}

function printHelp() {
  console.log(`
RediWala demo authentication seeder (development only)

Modes:
  Dry run
    npm run seed:demo-auth:dry

  Firebase Emulator (no service account)
    npx firebase emulators:start --only auth,database --project rediwala-development
    npm run seed:demo-auth:emulator

  Remote development (rediwala-development only)
    export FIREBASE_SERVICE_ACCOUNT_PATH=/path/to/sa.json
    CONFIRM_DEV_SEED=yes npm run seed:demo-auth

    # or Application Default Credentials
    gcloud auth application-default login
    export GOOGLE_CLOUD_PROJECT=rediwala-development
    CONFIRM_DEV_SEED=yes npm run seed:demo-auth

Scoped writes:
  --customers     Auth + users/customers for demo customers
  --vendors       Auth + vendor profiles for login vendors
  --supporting    Supporting vendors (no Auth)
  --scenarios     Live / scheduled / expiring status snapshots
  --reset         Clear demo roots, then reseed selected scopes
  --all           Everything (default when no scope flags are set)

Safety:
  - Never writes passwords to RTDB
  - Remote writes require CONFIRM_DEV_SEED=yes
  - Only rediwala-development (or emulator) unless explicitly overridden
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

function validatePersonas() {
  const issues = [];
  const emails = new Set();
  const vendorIds = new Set();
  const customerKeys = new Set();
  const vendorKeys = new Set();

  for (const customer of DEMO_CUSTOMERS) {
    if (!customer.email?.includes("@")) issues.push(`Customer ${customer.key}: invalid email`);
    if (!customer.password || customer.password.length < 8) {
      issues.push(`Customer ${customer.key}: password missing or too short`);
    }
    if (emails.has(customer.email)) issues.push(`Duplicate email: ${customer.email}`);
    emails.add(customer.email);
    if (customerKeys.has(customer.key)) issues.push(`Duplicate customer key: ${customer.key}`);
    customerKeys.add(customer.key);
  }

  for (const vendor of DEMO_VENDORS) {
    if (!vendor.email?.includes("@")) issues.push(`Vendor ${vendor.key}: invalid email`);
    if (!vendor.password || vendor.password.length < 8) {
      issues.push(`Vendor ${vendor.key}: password missing or too short`);
    }
    if (emails.has(vendor.email)) issues.push(`Duplicate email: ${vendor.email}`);
    emails.add(vendor.email);
    if (vendorIds.has(vendor.vendorId)) issues.push(`Duplicate vendorId: ${vendor.vendorId}`);
    vendorIds.add(vendor.vendorId);
    if (vendorKeys.has(vendor.key)) issues.push(`Duplicate vendor key: ${vendor.key}`);
    vendorKeys.add(vendor.key);
  }

  for (const vendor of SUPPORTING_VENDORS) {
    if (vendorIds.has(vendor.vendorId)) {
      issues.push(`Supporting vendorId collides with login vendor: ${vendor.vendorId}`);
    }
    vendorIds.add(vendor.vendorId);
  }

  return issues;
}

function collectPathRoots(updates) {
  const roots = new Set();
  for (const path of Object.keys(updates)) {
    roots.add(path.split("/")[0]);
  }
  return [...roots].sort();
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

function buildDataset(uidByEmail, scopes) {
  const nowIso = new Date().toISOString();
  const updates = {};
  let customersVerified = 0;
  let vendorsVerified = 0;
  let supporting = 0;
  let scenarios = 0;

  if (scopes.customers) {
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
  }

  const loginVendors = scopes.vendors || scopes.scenarios ? DEMO_VENDORS : [];
  const supportingVendors = scopes.supporting ? SUPPORTING_VENDORS : [];
  const allVendors = [...loginVendors, ...supportingVendors];

  for (const vendor of allVendors) {
    const ownerUid = uidByEmail[vendor.email] || null;
    const isLoginVendor = Boolean(vendor.email);
    if (isLoginVendor && ownerUid) vendorsVerified += 1;
    if (!isLoginVendor) supporting += 1;

    if (scopes.vendors || scopes.supporting) {
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

      if (vendor.route?.length) {
        const route = {};
        vendor.route.forEach((stop, index) => {
          route[stop.id] = {
            ...stop,
            order: index,
            isCompleted:
              Boolean(vendor.currentStop) &&
              index < vendor.route.findIndex((s) => s.title === vendor.currentStop),
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
    }

    if (scopes.scenarios) {
      updates[`vendor_status/${vendor.vendorId}`] = buildVendorStatus(vendor, nowIso);
      scenarios += 1;
    }

    if (ownerUid && (scopes.vendors || scopes.scenarios)) {
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
      if (scopes.scenarios) {
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
  }

  updates["demo_control/meta"] = {
    seededAt: nowIso,
    customers: DEMO_CUSTOMERS.length,
    vendors: DEMO_VENDORS.length,
    supportingVendors: SUPPORTING_VENDORS.length,
    neighborhoods: ["west_mambalam", "thiruvanmiyur"],
    scopes,
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

async function resetDemoRoots(db) {
  const roots = [
    "users",
    "customers",
    "customer_favorites",
    "vendors",
    "vendor_status",
    "vendor_locations",
    "vendor_routes",
    "vendor_announcements",
    "vendorLiveSessions",
    "customerRequests",
    "demo_control",
  ];
  console.log("Resetting demo roots…");
  const updates = {};
  for (const root of roots) updates[root] = null;
  await db.ref().update(updates);
  console.log("Cleared:", roots.join(", "));
}

function printSummary(summary, extras = {}) {
  console.log("\n— Summary —");
  console.log(`${summary.customersVerified} Customer accounts verified`);
  console.log(`${summary.vendorsVerified} Vendor accounts verified`);
  console.log(`${summary.supportingVendors} Supporting vendors seeded`);
  console.log(`${summary.neighborhoodClusters} Neighborhood clusters seeded`);
  console.log(`${summary.scenariosConfigured} Live or Scheduled scenarios configured`);
  if (extras.authCreated != null) {
    console.log(
      `Auth created=${extras.authCreated} updated=${extras.authUpdated} failed=${extras.authFailed}`
    );
  }
  if (extras.mode) console.log(`Mode: ${extras.mode}`);
  if (extras.credentialSource) console.log(`Credentials: ${extras.credentialSource}`);
  if (extras.roots?.length) console.log(`RTDB roots touched: ${extras.roots.join(", ")}`);
}

async function runDry(scopes) {
  console.log("Mode A — Dry run (no Firebase writes)\n");
  const issues = validatePersonas();
  if (issues.length) {
    console.error("Validation failed:");
    for (const issue of issues) console.error(`  - ${issue}`);
    process.exitCode = 1;
    return;
  }
  console.log("Persona validation: OK (emails unique, vendorIds unique, passwords present)");

  const uidByEmail = {};
  for (const persona of [...DEMO_CUSTOMERS, ...DEMO_VENDORS]) {
    uidByEmail[persona.email] = `dry_${persona.key}`;
  }
  const { updates, summary } = buildDataset(uidByEmail, scopes);
  const roots = collectPathRoots(updates);
  const paths = Object.keys(updates);
  const duplicates = paths.filter((path, index) => paths.indexOf(path) !== index);

  mkdirSync(GENERATED_DIR, { recursive: true });
  const previewPath = join(GENERATED_DIR, "demo-auth-preview.json");
  writeFileSync(
    previewPath,
    JSON.stringify(
      {
        summary,
        scopes,
        roots,
        pathCount: paths.length,
        sampleKeys: paths.slice(0, 40),
        updates,
      },
      null,
      2
    )
  );

  console.log(`Generated preview → ${previewPath}`);
  console.log(`Firebase paths generated: ${paths.length}`);
  console.log(`Duplicate paths: ${duplicates.length}`);
  if (duplicates.length) {
    console.error("Duplicate path keys detected:", duplicates.slice(0, 10).join(", "));
    process.exitCode = 1;
  }
  printSummary(summary, { mode: "dry-run", roots });
}

async function runWrite(args) {
  const forcedEmulator = args.emulator || detectEmulatorMode().active;
  let boot;
  try {
    boot = await initFirebaseAdmin({ emulator: forcedEmulator });
  } catch (error) {
    const message = error.message || String(error);
    if (error.code === "MISSING_CREDENTIALS") {
      console.error(credentialsHelpMessage());
      console.error(`\nDetail: ${message}`);
      process.exit(1);
    }
    if (error.code === "MISSING_CONFIRM_DEV_SEED") {
      console.error(message);
      console.error("\n" + credentialsHelpMessage());
      process.exit(1);
    }
    if (
      message.includes("Could not load the default credentials") ||
      message.includes("Unable to detect a Project Id")
    ) {
      console.error(credentialsHelpMessage());
      console.error(`\nDetail: ${message}`);
      process.exit(1);
    }
    throw error;
  }

  console.log(
    boot.mode === "emulator"
      ? `Mode B — Firebase Emulator (${boot.projectId})`
      : `Mode C — Remote development (${boot.projectId})`
  );
  console.log(`Credentials: ${boot.credentialSource}`);

  const auth = boot.admin.auth();
  const db = boot.admin.database();
  const uidByEmail = {};
  const authResults = { created: 0, updated: 0, failed: [] };

  if (args.reset) {
    if (boot.mode === "remote" && process.env.CONFIRM_DEV_RESET !== "yes") {
      throw new Error("Refusing remote reset. Set CONFIRM_DEV_RESET=yes (and CONFIRM_DEV_SEED=yes).");
    }
    await resetDemoRoots(db);
  }

  const personasNeedingAuth = [];
  if (args.customers) personasNeedingAuth.push(...DEMO_CUSTOMERS);
  if (args.vendors || args.scenarios) personasNeedingAuth.push(...DEMO_VENDORS);

  for (const persona of personasNeedingAuth) {
    try {
      const result = await ensureAuthUser(auth, {
        ...persona,
        displayName: persona.displayName || persona.businessName,
      });
      uidByEmail[persona.email] = result.uid;
      if (result.created) authResults.created += 1;
      else authResults.updated += 1;
      console.log(
        `Auth OK  ${persona.email} → ${result.uid} (${result.created ? "created" : "updated"})`
      );
    } catch (error) {
      authResults.failed.push({ email: persona.email, message: error.message });
      console.error(`Auth FAIL ${persona.email}: ${error.message}`);
    }
  }

  const { updates, summary } = buildDataset(uidByEmail, args);
  await db.ref().update(updates);
  printSummary(summary, {
    mode: boot.mode,
    credentialSource: boot.credentialSource,
    roots: collectPathRoots(updates),
    authCreated: authResults.created,
    authUpdated: authResults.updated,
    authFailed: authResults.failed.length,
  });
  if (authResults.failed.length) process.exitCode = 1;
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.help) {
    printHelp();
    process.exit(0);
  }

  const issues = validatePersonas();
  if (issues.length && !args.dryRun) {
    console.error("Persona validation failed before write:");
    for (const issue of issues) console.error(`  - ${issue}`);
    process.exit(1);
  }

  if (args.dryRun) {
    await runDry(args);
    return;
  }

  await runWrite(args);
}

main().catch((error) => {
  const message = error.message || String(error);
  if (error.code === "MISSING_CREDENTIALS") {
    console.error(credentialsHelpMessage());
    console.error(`\nDetail: ${message}`);
  } else {
    console.error(message);
  }
  process.exit(1);
});

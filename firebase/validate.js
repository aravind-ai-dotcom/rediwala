import { readFileSync, existsSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { buildDataset } from "./src/dataset.js";
import {
  DEFAULT_DATABASE_URL,
  SEED_ROOT_KEYS,
  assertDevelopmentProject,
} from "./src/config.js";

const __dirname = dirname(fileURLToPath(import.meta.url));
const PREVIEW_PATH = join(__dirname, "generated", "seed-preview.json");

const CHENNAI_BOUNDS = {
  minLat: 12.9,
  maxLat: 13.12,
  minLng: 80.15,
  maxLng: 80.32,
};

function parseArgs(argv) {
  return {
    local: !argv.includes("--remote"),
    remote: argv.includes("--remote"),
    help: argv.includes("--help") || argv.includes("-h"),
  };
}

function printHelp() {
  console.log(`
RediWala Firebase dataset validation (schema v2)

  npm run validate              Validate local/generated dataset
  npm run validate:remote       Validate live development RTDB
`);
}

function isNonEmptyString(value) {
  return typeof value === "string" && value.trim().length > 0;
}

function inChennai(lat, lng) {
  return (
    typeof lat === "number" &&
    typeof lng === "number" &&
    lat >= CHENNAI_BOUNDS.minLat &&
    lat <= CHENNAI_BOUNDS.maxLat &&
    lng >= CHENNAI_BOUNDS.minLng &&
    lng <= CHENNAI_BOUNDS.maxLng
  );
}

export function validatePayload(payload) {
  const errors = [];
  const warnings = [];

  for (const key of SEED_ROOT_KEYS) {
    if (payload[key] == null) errors.push(`Missing root node: ${key}`);
  }

  const {
    metadata,
    cities,
    categoryGroups,
    categories,
    neighborhoods,
    vendors,
    vendor_status: status,
    vendor_locations: locations,
    vendor_routes: routes,
    vendor_announcements: announcements,
    customers,
    customer_favorites: favorites,
    customer_settings: settings,
  } = payload;

  if (metadata) {
    if (metadata.schemaVersion !== "2.0") {
      warnings.push(`Unexpected schemaVersion: ${metadata.schemaVersion}`);
    }
    if (metadata.environment !== "development") {
      errors.push(`metadata.environment must be development`);
    }
    if (metadata.pilotCityId !== "chennai") {
      errors.push(`metadata.pilotCityId must be chennai`);
    }
  }

  if (!cities?.chennai) errors.push("Missing cities/chennai");

  const categoryIds = new Set(Object.keys(categories || {}));
  const neighborhoodIds = new Set(Object.keys(neighborhoods || {}));
  const vendorIds = new Set(Object.keys(vendors || {}));
  const groupIds = new Set(Object.keys(categoryGroups || {}));

  if (vendorIds.size < 40) {
    errors.push(`Expected at least 40 vendors, found ${vendorIds.size}`);
  }

  for (const [id, category] of Object.entries(categories || {})) {
    if (!groupIds.has(category.group)) {
      errors.push(`Category ${id} references missing group ${category.group}`);
    }
    if (!isNonEmptyString(category.nameEn) || !isNonEmptyString(category.nameTa)) {
      errors.push(`Category ${id} missing EN/TA name`);
    }
    if ((id === "tailor" || id === "sofa_repair") && !category.comingSoon) {
      errors.push(`Category ${id} must be comingSoon=true`);
    }
  }

  for (const nid of ["t_nagar", "west_mambalam", "thiruvanmiyur"]) {
    if (!neighborhoodIds.has(nid)) {
      errors.push(`Missing neighborhood ${nid}`);
    } else {
      const n = neighborhoods[nid];
      if (n.cityId !== "chennai") errors.push(`Neighborhood ${nid} cityId must be chennai`);
      if (!isNonEmptyString(n.nameEn) || !isNonEmptyString(n.nameTa)) {
        errors.push(`Neighborhood ${nid} missing EN/TA name`);
      }
      if (!inChennai(n.mapCenter?.latitude, n.mapCenter?.longitude)) {
        errors.push(`Neighborhood ${nid} mapCenter outside Chennai bounds`);
      }
    }
  }

  const vendorsByNeighborhood = { t_nagar: 0, west_mambalam: 0, thiruvanmiyur: 0 };
  const vendorsByCategory = {};

  for (const [vendorId, vendor] of Object.entries(vendors || {})) {
    if (!categoryIds.has(vendor.categoryId)) {
      errors.push(`Vendor ${vendorId} invalid categoryId ${vendor.categoryId}`);
    }
    if (!neighborhoodIds.has(vendor.neighborhoodId)) {
      errors.push(`Vendor ${vendorId} invalid neighborhoodId`);
    }
    if (vendor.cityId !== "chennai") {
      errors.push(`Vendor ${vendorId} cityId must be chennai for this pilot seed`);
    }
    if (!isNonEmptyString(vendor.descriptionEnglish) || !isNonEmptyString(vendor.descriptionTamil)) {
      errors.push(`Vendor ${vendorId} missing bilingual descriptions`);
    }
    if (categories?.[vendor.categoryId]?.comingSoon) {
      errors.push(`Vendor ${vendorId} assigned to comingSoon category`);
    }
    vendorsByNeighborhood[vendor.neighborhoodId] =
      (vendorsByNeighborhood[vendor.neighborhoodId] || 0) + 1;
    vendorsByCategory[vendor.categoryId] = (vendorsByCategory[vendor.categoryId] || 0) + 1;
  }

  for (const nid of ["t_nagar", "west_mambalam", "thiruvanmiyur"]) {
    if ((vendorsByNeighborhood[nid] || 0) < 1) {
      errors.push(`Neighborhood ${nid} has no vendors`);
    }
  }

  for (const [categoryId, category] of Object.entries(categories || {})) {
    if (category.comingSoon) continue;
    if (category.enabled && !vendorsByCategory[categoryId]) {
      warnings.push(`Enabled category ${categoryId} has no vendors`);
    }
  }

  let liveCount = 0;
  for (const [vendorId, row] of Object.entries(status || {})) {
    if (!vendorIds.has(vendorId)) errors.push(`vendor_status orphan ${vendorId}`);
    if (row.isLive) liveCount += 1;
  }

  for (const [vendorId, row] of Object.entries(locations || {})) {
    if (!vendorIds.has(vendorId)) errors.push(`vendor_locations orphan ${vendorId}`);
    if (!inChennai(row.latitude, row.longitude)) {
      errors.push(`vendor_locations ${vendorId} outside Chennai bounds`);
    }
  }

  for (const [vendorId, route] of Object.entries(routes || {})) {
    if (!vendorIds.has(vendorId)) errors.push(`vendor_routes orphan ${vendorId}`);
    const stops = Object.values(route.stops || {});
    if (stops.length < 3 || stops.length > 5) {
      warnings.push(`Route ${vendorId} has ${stops.length} stops (expected 3–5)`);
    }
    for (const stop of stops) {
      if (!["completed", "current", "upcoming"].includes(stop.status)) {
        errors.push(`Route ${vendorId} stop ${stop.id} invalid status`);
      }
      if (!inChennai(stop.latitude, stop.longitude)) {
        errors.push(`Route ${vendorId} stop ${stop.id} outside Chennai bounds`);
      }
    }
  }

  for (const [vendorId, announcement] of Object.entries(announcements || {})) {
    if (!vendorIds.has(vendorId)) errors.push(`vendor_announcements orphan ${vendorId}`);
    if (![10, 15, 20].includes(announcement.playbackIntervalMinutes)) {
      errors.push(`Announcement ${vendorId} invalid playbackIntervalMinutes`);
    }
    if (
      !isNonEmptyString(announcement.transcriptEnglish) ||
      !isNonEmptyString(announcement.transcriptTamil)
    ) {
      errors.push(`Announcement ${vendorId} missing transcripts`);
    }
  }

  if (Object.keys(customers || {}).length < 20) {
    errors.push(`Expected at least 20 customers, found ${Object.keys(customers || {}).length}`);
  }

  let favoriteCount = 0;
  for (const [customerId, map] of Object.entries(favorites || {})) {
    if (!customers?.[customerId]) {
      errors.push(`customer_favorites missing customer ${customerId}`);
    }
    if (!settings?.[customerId]) {
      warnings.push(`customer_settings missing for ${customerId}`);
    }
    for (const vendorId of Object.keys(map || {})) {
      favoriteCount += 1;
      if (!vendorIds.has(vendorId)) {
        errors.push(`Favorite ${customerId} → missing vendor ${vendorId}`);
      }
    }
  }

  return {
    vendors: vendorIds.size,
    categories: categoryIds.size,
    categoryGroups: groupIds.size,
    neighborhoods: neighborhoodIds.size,
    cities: Object.keys(cities || {}).length,
    liveVendors: liveCount,
    routes: Object.keys(routes || {}).length,
    announcements: Object.keys(announcements || {}).length,
    customers: Object.keys(customers || {}).length,
    customerSettings: Object.keys(settings || {}).length,
    favoriteRelationships: favoriteCount,
    vendorsByNeighborhood: vendorsByNeighborhood,
    errors,
    warnings,
    ok: errors.length === 0,
  };
}

async function loadRemotePayload() {
  const credentialPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;
  if (!credentialPath) {
    throw new Error("FIREBASE_SERVICE_ACCOUNT_PATH required for --remote");
  }
  const serviceAccount = JSON.parse(readFileSync(resolve(credentialPath), "utf8"));
  const projectId = process.env.FIREBASE_PROJECT_ID || serviceAccount.project_id;
  assertDevelopmentProject(projectId);

  const admin = await import("firebase-admin");
  if (!admin.default.apps.length) {
    admin.default.initializeApp({
      credential: admin.default.credential.cert(serviceAccount),
      databaseURL: DEFAULT_DATABASE_URL,
      projectId,
    });
  }

  const root = (await admin.default.database().ref().once("value")).val() || {};
  const payload = {};
  for (const key of SEED_ROOT_KEYS) payload[key] = root[key] ?? null;
  return payload;
}

function loadLocalPayload() {
  if (existsSync(PREVIEW_PATH)) {
    const parsed = JSON.parse(readFileSync(PREVIEW_PATH, "utf8"));
    return parsed.payload || parsed;
  }
  console.log("No local preview found; generating dataset in memory…");
  return buildDataset(new Date()).payload;
}

function printSummary(summary) {
  console.log("\n=== Validation summary ===");
  for (const key of [
    "vendors",
    "categories",
    "categoryGroups",
    "neighborhoods",
    "cities",
    "liveVendors",
    "routes",
    "announcements",
    "customers",
    "customerSettings",
    "favoriteRelationships",
  ]) {
    console.log(`${key}:`.padEnd(26), summary[key]);
  }
  console.log("vendorsByNeighborhood:", summary.vendorsByNeighborhood);

  if (summary.warnings.length) {
    console.log(`\nWarnings (${summary.warnings.length}):`);
    summary.warnings.forEach((w) => console.log(`  - ${w}`));
  } else console.log("\nWarnings: none");

  if (summary.errors.length) {
    console.log(`\nErrors (${summary.errors.length}):`);
    summary.errors.forEach((e) => console.log(`  - ${e}`));
  } else console.log("\nErrors: none");

  console.log(summary.ok ? "\nVALIDATION PASSED" : "\nVALIDATION FAILED");
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.help) {
    printHelp();
    process.exit(0);
  }

  const payload = args.remote ? await loadRemotePayload() : loadLocalPayload();
  const summary = validatePayload(payload);
  printSummary(summary);
  process.exit(summary.ok ? 0 : 1);
}

main().catch((error) => {
  console.error("\nValidation failed to run:", error.message);
  process.exit(1);
});

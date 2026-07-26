import { mkdirSync, writeFileSync, readFileSync, existsSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { buildDataset } from "./src/dataset.js";
import {
  ALLOWED_PROJECT_IDS,
  DEFAULT_DATABASE_URL,
  LEGACY_ROOT_KEYS,
  SEED_ROOT_KEYS,
  assertDevelopmentProject,
} from "./src/config.js";

const __dirname = dirname(fileURLToPath(import.meta.url));
const GENERATED_DIR = join(__dirname, "generated");
const PREVIEW_PATH = join(GENERATED_DIR, "seed-preview.json");

function parseArgs(argv) {
  return {
    dryRun: argv.includes("--dry-run"),
    reset: argv.includes("--reset"),
    help: argv.includes("--help") || argv.includes("-h"),
  };
}

function printHelp() {
  console.log(`
RediWala Firebase RTDB seed — permanent schema v2 (development only)

Usage:
  npm run seed:dry     Generate dataset locally (no Firebase write)
  npm run seed         Write dataset to development RTDB
  npm run reset        Clear seed roots (incl. legacy), then reseed

Environment:
  FIREBASE_SERVICE_ACCOUNT_PATH   Required for remote write
  FIREBASE_PROJECT_ID             Must be rediwala-development
  FIREBASE_DATABASE_URL           Optional
  CONFIRM_DEV_SEED=yes            Required for remote write
  CONFIRM_DEV_RESET=yes           Required for reset

Safety: refuses non-development project IDs; never commits credentials.
`);
}

function printCounts(counts) {
  console.log("\nRecord counts:");
  for (const [key, value] of Object.entries(counts)) {
    console.log(`  ${key.padEnd(24)} ${value}`);
  }
}

function writePreview(payload, counts) {
  mkdirSync(GENERATED_DIR, { recursive: true });
  writeFileSync(PREVIEW_PATH, JSON.stringify({ counts, payload }, null, 2), "utf8");
  console.log(`Wrote local preview → ${PREVIEW_PATH}`);
}

async function initAdmin() {
  const credentialPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;
  if (!credentialPath) {
    throw new Error(
      "FIREBASE_SERVICE_ACCOUNT_PATH is required for remote seed. Use npm run seed:dry without credentials."
    );
  }

  const absolute = resolve(credentialPath);
  if (!existsSync(absolute)) {
    throw new Error(`Service account file not found: ${absolute}`);
  }

  const serviceAccount = JSON.parse(readFileSync(absolute, "utf8"));
  const projectId = process.env.FIREBASE_PROJECT_ID || serviceAccount.project_id;
  assertDevelopmentProject(projectId);

  if (process.env.CONFIRM_DEV_SEED !== "yes") {
    throw new Error(
      'Refusing remote write. Set CONFIRM_DEV_SEED=yes to seed development only.'
    );
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

async function resetDevelopmentRoots(db) {
  if (process.env.CONFIRM_DEV_RESET !== "yes") {
    throw new Error(
      "Refusing reset. Set CONFIRM_DEV_RESET=yes (and CONFIRM_DEV_SEED=yes)."
    );
  }

  console.log("Resetting development seed roots (current + legacy)…");
  const updates = {};
  for (const key of [...SEED_ROOT_KEYS, ...LEGACY_ROOT_KEYS]) {
    updates[key] = null;
  }
  await db.ref().update(updates);
  console.log("Cleared:", [...SEED_ROOT_KEYS, ...LEGACY_ROOT_KEYS].join(", "));
}

async function writePayload(db, payload) {
  console.log("Writing permanent schema payload to Realtime Database…");
  await db.ref().update(payload);
  console.log("Remote write complete.");
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.help) {
    printHelp();
    process.exit(0);
  }

  console.log("Building permanent Chennai pilot dataset (schema v2)…");
  const { payload, counts } = buildDataset(new Date());
  printCounts(counts);
  writePreview(payload, counts);

  if (args.dryRun) {
    console.log("\nDry-run complete. No remote writes performed.");
    console.log(`Allowed projects: ${ALLOWED_PROJECT_IDS.join(", ")}`);
    return;
  }

  const { admin, projectId } = await initAdmin();
  console.log(`Target project: ${projectId}`);
  console.log(`Database URL: ${DEFAULT_DATABASE_URL}`);

  const db = admin.database();
  if (args.reset) {
    await resetDevelopmentRoots(db);
  }

  await writePayload(db, payload);
  console.log("\nSeed finished successfully.");
  printCounts(counts);
}

main().catch((error) => {
  console.error("\nSeed failed:", error.message);
  process.exit(1);
});

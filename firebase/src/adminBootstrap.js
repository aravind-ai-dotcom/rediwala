/**
 * Shared Firebase Admin bootstrap for development seed scripts.
 * Never commits credentials. Never targets production by default.
 */

import { existsSync, readFileSync } from "node:fs";
import { homedir } from "node:os";
import { resolve, join } from "node:path";
import {
  ALLOWED_PROJECT_IDS,
  DEFAULT_DATABASE_URL,
  assertDevelopmentProject,
} from "./config.js";

export const DEFAULT_AUTH_EMULATOR_HOST = "127.0.0.1:9099";
export const DEFAULT_DATABASE_EMULATOR_HOST = "127.0.0.1:9000";

function adcCredentialPath() {
  if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    return resolve(process.env.GOOGLE_APPLICATION_CREDENTIALS);
  }
  return join(homedir(), ".config", "gcloud", "application_default_credentials.json");
}

function hasApplicationDefaultCredentials() {
  return existsSync(adcCredentialPath());
}

export function credentialsHelpMessage() {
  return `
No Firebase credentials were found.

Choose one of the following:

1. Run a dry run:

   npm run seed:demo-auth:dry

2. Start the Firebase Emulator and run:

   npm run seed:demo-auth:emulator

3. Seed the remote development project:

   export FIREBASE_SERVICE_ACCOUNT_PATH=/path/to/service-account.json
   CONFIRM_DEV_SEED=yes npm run seed:demo-auth

   or authenticate using Application Default Credentials:

   gcloud auth application-default login
   export GOOGLE_CLOUD_PROJECT=rediwala-development
   CONFIRM_DEV_SEED=yes npm run seed:demo-auth
`.trim();
}

export function detectEmulatorMode({ forceEmulator = false } = {}) {
  const authHost = process.env.FIREBASE_AUTH_EMULATOR_HOST;
  const dbHost = process.env.FIREBASE_DATABASE_EMULATOR_HOST;
  const envHint = process.env.FIREBASE_EMULATOR === "1" || process.env.FIREBASE_EMULATOR === "true";
  const active = Boolean(forceEmulator || envHint || authHost || dbHost);
  return {
    active,
    authHost: authHost || (active ? DEFAULT_AUTH_EMULATOR_HOST : null),
    databaseHost: dbHost || (active ? DEFAULT_DATABASE_EMULATOR_HOST : null),
  };
}

async function probeEmulatorHost(host) {
  if (!host) return false;
  const [hostname, portRaw] = host.split(":");
  const port = Number(portRaw);
  if (!hostname || !Number.isFinite(port)) return false;
  try {
    const response = await fetch(`http://${hostname}:${port}/`, {
      method: "GET",
      signal: AbortSignal.timeout(800),
    });
    return response.status >= 200 && response.status < 500;
  } catch {
    return false;
  }
}

export async function ensureEmulatorReachable(emulator) {
  const authOk = await probeEmulatorHost(emulator.authHost);
  const dbOk = await probeEmulatorHost(emulator.databaseHost);
  if (authOk || dbOk) return;
  throw new Error(
    [
      "Firebase Emulator mode was requested, but no emulator appears to be running.",
      "",
      "Start emulators from the repo root:",
      "  npx -y firebase-tools@latest emulators:start --only auth,database --project rediwala-development",
      "",
      "Then run:",
      "  npm run seed:demo-auth:emulator",
    ].join("\n")
  );
}

function resolveProjectId(serviceAccountProjectId) {
  const projectId =
    process.env.FIREBASE_PROJECT_ID ||
    process.env.GOOGLE_CLOUD_PROJECT ||
    process.env.GCLOUD_PROJECT ||
    serviceAccountProjectId ||
    "rediwala-development";

  if (ALLOWED_PROJECT_IDS.includes(projectId)) {
    return projectId;
  }

  if (process.env.CONFIRM_FORCE_SEED === "yes" && process.env.ALLOW_NON_DEV_PROJECT === "yes") {
    console.warn(
      `WARNING: seeding non-development project "${projectId}" because ALLOW_NON_DEV_PROJECT=yes and CONFIRM_FORCE_SEED=yes.`
    );
    return projectId;
  }

  assertDevelopmentProject(projectId);
  return projectId;
}

/**
 * Initialize firebase-admin for emulator or remote development.
 * @returns {{ admin: import('firebase-admin'), projectId: string, mode: 'emulator' | 'remote', credentialSource: string }}
 */
export async function initFirebaseAdmin({ emulator = false } = {}) {
  const emulatorInfo = detectEmulatorMode({ forceEmulator: emulator });
  const admin = await import("firebase-admin");

  if (emulatorInfo.active) {
    await ensureEmulatorReachable(emulatorInfo);
    process.env.FIREBASE_AUTH_EMULATOR_HOST =
      process.env.FIREBASE_AUTH_EMULATOR_HOST || emulatorInfo.authHost;
    process.env.FIREBASE_DATABASE_EMULATOR_HOST =
      process.env.FIREBASE_DATABASE_EMULATOR_HOST || emulatorInfo.databaseHost;

    const projectId = resolveProjectId("rediwala-development");
    if (!admin.default.apps.length) {
      admin.default.initializeApp({
        projectId,
        databaseURL: process.env.FIREBASE_DATABASE_URL || `http://${emulatorInfo.databaseHost}?ns=${projectId}`,
      });
    }
    return {
      admin: admin.default,
      projectId,
      mode: "emulator",
      credentialSource: "emulator (no service account)",
    };
  }

  // Remote development only.
  if (process.env.CONFIRM_DEV_SEED !== "yes") {
    const err = new Error(
      "Refusing remote write without confirmation.\n\nSet CONFIRM_DEV_SEED=yes to seed rediwala-development,\nor use the emulator / dry-run modes instead."
    );
    err.code = "MISSING_CONFIRM_DEV_SEED";
    throw err;
  }

  const credentialPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;
  let credential;
  let credentialSource;
  let serviceAccountProjectId;

  if (credentialPath) {
    const absolute = resolve(credentialPath);
    if (!existsSync(absolute)) {
      const err = new Error(`Service account file not found: ${absolute}`);
      err.code = "MISSING_CREDENTIALS";
      throw err;
    }
    const serviceAccount = JSON.parse(readFileSync(absolute, "utf8"));
    serviceAccountProjectId = serviceAccount.project_id;
    credential = admin.default.credential.cert(serviceAccount);
    credentialSource = `service account file (${absolute})`;
  } else if (hasApplicationDefaultCredentials()) {
    try {
      credential = admin.default.credential.applicationDefault();
      credentialSource = `Application Default Credentials (${adcCredentialPath()})`;
    } catch (error) {
      const err = new Error(error.message || String(error));
      err.code = "MISSING_CREDENTIALS";
      throw err;
    }
  } else {
    const err = new Error(
      "Neither FIREBASE_SERVICE_ACCOUNT_PATH nor Application Default Credentials were found."
    );
    err.code = "MISSING_CREDENTIALS";
    throw err;
  }

  const projectId = resolveProjectId(serviceAccountProjectId);
  assertDevelopmentProject(projectId);

  if (!admin.default.apps.length) {
    admin.default.initializeApp({
      credential,
      databaseURL: DEFAULT_DATABASE_URL,
      projectId,
    });
  }

  return {
    admin: admin.default,
    projectId,
    mode: "remote",
    credentialSource,
  };
}

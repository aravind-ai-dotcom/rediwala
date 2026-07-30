/**
 * Permanent RediWala RTDB seed roots (development).
 * Production project IDs are intentionally rejected.
 */

export const ALLOWED_PROJECT_IDS = Object.freeze(["rediwala-development"]);

export const DEFAULT_DATABASE_URL =
  process.env.FIREBASE_DATABASE_URL ||
  "https://rediwala-development-default-rtdb.asia-southeast1.firebasedatabase.app";

/** Current permanent schema roots written by the seed utility. */
export const SEED_ROOT_KEYS = Object.freeze([
  "metadata",
  "cities",
  "neighborhoods",
  "categoryGroups",
  "categories",
  "vendors",
  "vendor_status",
  "vendor_locations",
  "vendor_routes",
  "vendor_announcements",
  "vendorLiveSessions",
  "customers",
  "customer_favorites",
  "customer_settings",
  "customerRequests",
  "users",
  "demo_control",
]);

/**
 * Legacy roots from the earlier seller_* prototype.
 * Cleared during reset so development DBs do not keep stale trees.
 */
export const LEGACY_ROOT_KEYS = Object.freeze([
  "category_groups",
  "sellers",
  "seller_status",
  "seller_locations",
  "seller_routes",
  "announcements",
]);

export function assertDevelopmentProject(projectId) {
  if (!ALLOWED_PROJECT_IDS.includes(projectId)) {
    throw new Error(
      `Refusing to run against project "${projectId}". Allowed: ${ALLOWED_PROJECT_IDS.join(", ")}`
    );
  }
}

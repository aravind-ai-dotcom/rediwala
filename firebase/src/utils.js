/** Deterministic PRNG for repeatable synthetic coordinates. */
export function mulberry32(seed) {
  let t = seed >>> 0;
  return function next() {
    t += 0x6d2b79f5;
    let r = Math.imul(t ^ (t >>> 15), 1 | t);
    r ^= r + Math.imul(r ^ (r >>> 7), 61 | r);
    return ((r ^ (r >>> 14)) >>> 0) / 4294967296;
  };
}

export function jitter(rand, base, spread) {
  return Number((base + (rand() - 0.5) * spread).toFixed(6));
}

export function isoHoursAgo(hours, now = new Date()) {
  return new Date(now.getTime() - hours * 3600_000).toISOString();
}

export function todayDateString(now = new Date()) {
  return now.toISOString().slice(0, 10);
}

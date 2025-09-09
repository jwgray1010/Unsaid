#!/usr/bin/env node
/**
 * jobs/migrate_profile.mjs
 *
 * Advanced profile migration runner for CommunicatorProfile records.
 *
 * Features:
 * - Schema versioning with ordered migration steps
 * - Dry-run / plan mode (no writes)
 * - Concurrency control
 * - Filter which users to migrate (--user, --from-file)
 * - Backups to disk (JSON per user) + JSONL report
 * - Safe, idempotent transforms with per-step guards
 * - Optional metrics & structured logging
 *
 * Usage:
 *   node jobs/migrate_profile.mjs [--adapter inMemory|mongo|redis|firestore] \
 *       [--dry-run] [--plan] [--concurrency 8] [--backup-dir ./backups] \
 *       [--report ./migration-report.jsonl] [--user <id>] [--from-file ./ids.txt]
 *
 * Default adapter = inMemory (uses your current InMemoryProfileStorage)
 */

import fs from 'fs';
import path from 'path';
import os from 'os';
import { fileURLToPath, pathToFileURL } from 'url';
import crypto from 'crypto';

// ---------- Resolve __dirname (ESM) ----------
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// ---------- Optional logger & metrics ----------
let log = console;
try {
  const loggerMod = await import(pathToFileURL(path.join(__dirname, '../config/logger.js')));
  log = loggerMod.default || loggerMod; // support cjs default
  if (!log.info) log = console; // fallback
} catch { /* noop: fallback to console */ }

let metrics = null;
try {
  const m = await import(pathToFileURL(path.join(__dirname, '../config/metrics.js'))).catch(() => ({}));
  metrics = m || null;
} catch { /* noop */ }

// ---------- CLI args ----------
const args = parseArgs(process.argv.slice(2));
const {
  adapter = process.env.MIGRATE_ADAPTER || 'inMemory',
  dryRun = false,
  plan = false,
  concurrency = Number(process.env.MIGRATE_CONCURRENCY || 6),
  backupDir = process.env.MIGRATE_BACKUP_DIR || null,
  report = process.env.MIGRATE_REPORT || path.join(process.cwd(), `migration-report-${new Date().toISOString().replace(/[:.]/g,'-')}.jsonl`),
  user: singleUserId = null,
  fromFile = null,
  sample = null, // e.g., --sample 0.1 (10%)
} = args;

// ---------- Storage adapter loader ----------
const storage = await loadStorage(adapter);

// ---------- Migration schema/versioning ----------
// Define the "latest" schema version. Increment when you add a new step.
const LATEST_VERSION = 4;

/**
 * Minimal shape validator (non-crashing). You can swap for zod/ajv later.
 */
function normalizeProfile(p = {}, userId = 'unknown') {
  const out = { ...p };
  // Ensure essential fields
  out.userId = out.userId || userId;
  out.schemaVersion = Number(out.schemaVersion || 1);

  // v1 baseline fields
  out.scores = isObject(out.scores) ? { ...out.scores } : {};
  out.daysObserved = typeof out.daysObserved === 'number' ? out.daysObserved : 0;

  // sane defaults
  out.counters = isObject(out.counters) ? out.counters : {};
  out.flags = isObject(out.flags) ? out.flags : {};
  out.history = Array.isArray(out.history) ? out.history : [];

  return out;
}

/**
 * Ordered migration steps. Each step should be:
 *   (profile) => { changed: boolean, profile }
 * and must be idempotent (safe to run multiple times).
 */
const migrations = [
  // ---- v1 -> v2: ensure all 4 styles in scores ----
  function v1_to_v2(profile) {
    if (profile.schemaVersion >= 2) return { changed: false, profile };
    let changed = false;
    const styles = ['anxious', 'avoidant', 'disorganized', 'secure'];
    for (const s of styles) {
      if (typeof profile.scores[s] !== 'number') {
        profile.scores[s] = 0;
        changed = true;
      }
    }
    // Ensure daysObserved is a number
    if (typeof profile.daysObserved !== 'number') {
      profile.daysObserved = 0;
      changed = true;
    }
    if (changed) profile.schemaVersion = 2;
    return { changed, profile };
  },

  // ---- v2 -> v3: add normalized counters + lastUpdated ISO ----
  function v2_to_v3(profile) {
    if (profile.schemaVersion >= 3) return { changed: false, profile };
    let changed = false;
    if (!isObject(profile.counters)) {
      profile.counters = {};
      changed = true;
    }
    // seed common counters if missing
    for (const k of ['messagesAnalyzed', 'repairsSuggested', 'alertsSeen']) {
      if (typeof profile.counters[k] !== 'number') {
        profile.counters[k] = 0;
        changed = true;
      }
    }
    if (typeof profile.lastUpdated !== 'string') {
      profile.lastUpdated = new Date().toISOString();
      changed = true;
    }
    if (changed) profile.schemaVersion = 3;
    return { changed, profile };
  },

  // ---- v3 -> v4: add learning fields + cap history size ----
  function v3_to_v4(profile) {
    if (profile.schemaVersion >= 4) return { changed: false, profile };
    let changed = false;

    // Add/normalize learning signals
    if (!Array.isArray(profile.learningSignals)) {
      profile.learningSignals = [];
      changed = true;
    }

    // Cap history to last 500 events (configurable later)
    if (Array.isArray(profile.history) && profile.history.length > 500) {
      profile.history = profile.history.slice(-500);
      changed = true;
    }

    // Add attachmentStyle if not set, with neutral baseline
    const validStyles = ['anxious', 'avoidant', 'disorganized', 'secure'];
    if (!profile.attachmentStyle || !validStyles.includes(profile.attachmentStyle)) {
      profile.attachmentStyle = 'secure'; // neutral default
      changed = true;
    }

    // Touch lastUpdated
    profile.lastUpdated = new Date().toISOString();
    changed = true; // touching version

    profile.schemaVersion = 4;
    return { changed, profile };
  },
];

/**
 * Run all needed migrations to bring a profile to LATEST_VERSION.
 */
function migrateProfile(profile, userId) {
  const before = deepClone(profile);
  let changedTotal = false;
  let current = normalizeProfile(profile, userId);

  for (const step of migrations) {
    const { changed, profile: next } = step(current);
    current = next;
    changedTotal = changedTotal || changed;
  }

  // Ensure at target version
  if (current.schemaVersion !== LATEST_VERSION) {
    current.schemaVersion = LATEST_VERSION;
    changedTotal = true;
  }

  return { changed: changedTotal, before, after: current };
}

// ---------- Backup helpers ----------
async function backupProfile(dir, userId, data) {
  if (!dir) return;
  await fs.promises.mkdir(dir, { recursive: true });
  const p = path.join(dir, `${sanitize(userId)}.json`);
  await fs.promises.writeFile(p, JSON.stringify(data, null, 2), 'utf8');
}

function sanitize(s) {
  return String(s).replace(/[^\w.\-@]/g, '_');
}

// ---------- Reporting ----------
async function appendReportLine(reportPath, obj) {
  await fs.promises.mkdir(path.dirname(reportPath), { recursive: true });
  await fs.promises.appendFile(reportPath, JSON.stringify(obj) + '\n', 'utf8');
}

// ---------- Concurrency runner ----------
async function runWithConcurrency(items, limit, worker) {
  const results = [];
  let idx = 0;
  const total = items.length;
  const active = new Set();

  async function spawn() {
    if (idx >= total) return;
    const i = idx++;
    const item = items[i];
    const p = (async () => worker(item, i))()
      .then((r) => (results[i] = r))
      .catch((e) => (results[i] = { error: e }));
    active.add(p);
    p.finally(() => active.delete(p));
    if (active.size < limit && idx < total) await spawn();
  }

  // Prime pool
  const first = Math.min(limit, items.length);
  for (let k = 0; k < first; k++) await spawn();

  // Drain
  while (active.size) {
    await Promise.race([...active]);
    if (idx < total) await spawn();
  }
  return results;
}

// ---------- Main flow ----------
async function main() {
  banner();
  const startTs = Date.now();

  // 1) Resolve user IDs
  let userIds;
  if (singleUserId) {
    userIds = [singleUserId];
  } else if (fromFile) {
    const raw = await fs.promises.readFile(fromFile, 'utf8');
    userIds = raw.split(/\r?\n/).map((s) => s.trim()).filter(Boolean);
  } else {
    userIds = await storage.listUserIds();
  }

  if (sample) {
    const rate = Math.max(0, Math.min(1, Number(sample)));
    userIds = userIds.filter(() => Math.random() < rate);
  }

  log.info({ count: userIds.length, adapter }, 'starting profile migration');

  if (plan) {
    console.log('\n--- PLAN ---');
    console.log(`Would migrate ${userIds.length} profiles to schemaVersion=${LATEST_VERSION}`);
    console.log('No writes will be performed.');
    process.exit(0);
  }

  // 2) Report header
  await appendReportLine(report, { type: 'start', at: new Date().toISOString(), adapter, total: userIds.length });

  // 3) Process with concurrency
  const results = await runWithConcurrency(
    userIds,
    Math.max(1, concurrency),
    async (userId) => {
      const t0 = process.hrtime.bigint();
      try {
        const original = await storage.get(userId);
        if (!original) {
          await appendReportLine(report, { type: 'skip_missing', userId });
          return { userId, status: 'missing' };
        }

        const { changed, before, after } = migrateProfile(original, userId);
        if (!changed) {
          await appendReportLine(report, { type: 'unchanged', userId, version: after.schemaVersion });
          return { userId, status: 'unchanged' };
        }

        // Backup before write
        await backupProfile(backupDir, userId, before);

        // Optional adapter transaction
        let tx = null;
        if (storage.beginTransaction) tx = await storage.beginTransaction?.();

        if (!dryRun) {
          await storage.set(userId, after, { tx });
          if (storage.commit) await storage.commit?.(tx);
        } else {
          if (storage.rollback) await storage.rollback?.(tx);
        }

        const duration = Number(process.hrtime.bigint() - t0) / 1e9;

        await appendReportLine(report, {
          type: 'migrated',
          userId,
          from: before.schemaVersion || 1,
          to: after.schemaVersion,
          duration,
        });

        metrics?.inc?.(`${metricPrefix()}migrate_success_total`, { adapter });
        return { userId, status: 'migrated', from: before.schemaVersion, to: after.schemaVersion, duration };
      } catch (err) {
        const duration = Number(process.hrtime.bigint() - t0) / 1e9;
        log.error({ err, userId }, 'migration failed');
        await appendReportLine(report, { type: 'error', userId, message: err?.message, stack: err?.stack, duration });
        metrics?.inc?.(`${metricPrefix()}migrate_errors_total`, { adapter });
        return { userId, status: 'error', error: err?.message };
      }
    }
  );

  // 4) Summarize
  const summary = summarize(results);
  await appendReportLine(report, { type: 'summary', ...summary, at: new Date().toISOString() });
  log.info(summary, 'migration finished');

  const secs = ((Date.now() - startTs) / 1000).toFixed(2);
  console.log(`\n🎉 Migration complete in ${secs}s`);
  console.log(`Report: ${report}`);
  if (backupDir) console.log(`Backups: ${path.resolve(backupDir)}`);
}

// ---------- Utilities ----------
function parseArgs(argv) {
  const out = {};
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (!a.startsWith('--')) continue;
    const key = a.replace(/^--/, '');
    const next = argv[i + 1];
    const isBool = !next || next.startsWith('--');
    if (isBool) {
      out[key] = true;
    } else {
      out[key] = next;
      i++;
    }
  }
  return out;
}

function deepClone(x) {
  return x == null ? x : JSON.parse(JSON.stringify(x));
}

function isObject(o) {
  return o && typeof o === 'object' && !Array.isArray(o);
}

function summarize(results) {
  let migrated = 0, unchanged = 0, missing = 0, errors = 0;
  for (const r of results) {
    if (!r) continue;
    if (r.status === 'migrated') migrated++;
    else if (r.status === 'unchanged') unchanged++;
    else if (r.status === 'missing') missing++;
    else if (r.status === 'error') errors++;
  }
  return { counts: { migrated, unchanged, missing, errors }, total: results.length };
}

function banner() {
  console.log(`
==========================================================
  Unsaid: CommunicatorProfile Migration
  Adapter: ${adapter}   Dry-run: ${dryRun}   Concurrency: ${concurrency}
  Latest schema version: ${LATEST_VERSION}
==========================================================
`);
}

function metricPrefix() {
  return (process.env.METRICS_PREFIX || 'unsaid_');
}

// ---------- Adapter loader ----------
async function loadStorage(name) {
  switch (name) {
    case 'inMemory': {
      // Your existing adapter (CJS) – import via path
      const modUrl = pathToFileURL(path.join(__dirname, '../services/communicator_profile.js'));
      const m = await import(modUrl);
      const Impl = m.InMemoryProfileStorage || m.default?.InMemoryProfileStorage || m.default || m;
      // Normalize interface
      const store = new Impl();
      // Add listUserIds if missing
      if (!store.listUserIds && store.store && store.store.keys) {
        store.listUserIds = async () => Array.from(store.store.keys());
      } else if (!store.listUserIds) {
        store.listUserIds = async () => []; // fallback
      }
      // Ensure get/set
      if (!store.get) store.get = async (id) => store.store?.get(id) ?? null;
      if (!store.set) store.set = async (id, data) => store.store?.set(id, data);
      return store;
    }
    case 'mongo':
    case 'redis':
    case 'firestore':
      // Placeholder: wire your real adapters here
      throw new Error(`Adapter "${name}" not implemented yet. Provide a module in services/ and extend loadStorage().`);
    default:
      throw new Error(`Unknown adapter "${name}"`);
  }
}

// ---------- Signals ----------
process.on('SIGINT', () => {
  console.log('\n⛔ Interrupted (SIGINT). Exiting...');
  process.exit(130);
});

// ---------- Run ----------
main().catch((err) => {
  console.error('❌ Migration failed:', err);
  process.exit(1);
});

/**
 * api/health.js
 *
 * Comprehensive health + readiness checks for Unsaid API (Vercel-friendly).
 *
 * Routes:
 *   GET /health/live    -> liveness (fast)
 *   GET /health/ready   -> readiness (dependencies + data validated)
 *   GET /health/status  -> detailed report (for dashboards/alerts)
 *
 * Mount:
 *   app.use('/health', require('./api/health'));
 */

console.log('[DEBUG] health.js starting...');

const express = require('express');
const fs = require('fs');
const fsp = require('fs/promises');
const path = require('path');
const dns = require('dns').promises;

console.log('[DEBUG] health.js imports loaded...');

const router = express.Router();
const bootTime = Date.now();

console.log('[DEBUG] health.js router created...');

// ---------- Config ----------
const REQUIRED_ENVS = [
  // core
  'NODE_ENV',
  // add if you require them for prod gating:
  // 'JWT_PUBLIC_KEY', 'JWT_AUDIENCE', 'JWT_ISSUER',
  // storage/backends (optional – only “required” if your app truly needs them)
  // 'REDIS_URL', 'MONGODB_URI',
];

const DATA_FILES = [
  'learning_signals.json',
  'tone_triggerwords.json',
  'intensity_modifiers.json',
  'sarcasm_indicators.json',
  'negation_patterns.json',
  'context_classifier.json',
  'therapy_advice.json',
  'onboarding_playbook.json',
  'phrases_edges.json',
  'severity_collaboration.json',
  'weight_modifiers.json',
  // optional:
  'semantic_thesaurus.json',
  'profanity_lexicon.json',
];

const DATA_DIR = path.join(__dirname, '..', 'data');
const DEFAULT_CHECK_TIMEOUT_MS = 1500;

// ---------- Utilities ----------
async function withTimeout(name, fn, timeoutMs = DEFAULT_CHECK_TIMEOUT_MS) {
  let timer;
  try {
    const p = Promise.resolve().then(fn);
    const t = new Promise((_res, rej) => {
      timer = setTimeout(() => rej(new Error(`timeout:${name}`)), timeoutMs);
    });
    const result = await Promise.race([p, t]);
    clearTimeout(timer);
    return { name, ok: true, info: result ?? true };
  } catch (err) {
    clearTimeout(timer);
    return { name, ok: false, error: err?.message || String(err) };
  }
}

function summarize(results) {
  const ok = results.every(r => r.ok);
  const failing = results.filter(r => !r.ok).map(r => r.name);
  return { ok, failing };
}

function bytes(n) {
  const MB = 1024 * 1024;
  return Math.round((n / MB) * 10) / 10 + 'MB';
}

async function eventLoopDelaySample(sampleMs = 120) {
  // Simple event loop delay estimator
  const t0 = performance.now();
  await new Promise(res => setTimeout(res, sampleMs));
  const t1 = performance.now();
  const delay = Math.max(0, (t1 - t0) - sampleMs);
  return Math.round(delay);
}

// ---------- Individual Checks ----------
async function checkEnvVars() {
  const missing = REQUIRED_ENVS.filter(k => !process.env[k]);
  if (missing.length) throw new Error(`missing envs: ${missing.join(', ')}`);
  return { present: REQUIRED_ENVS };
}

async function checkDataFiles() {
  const results = [];
  for (const f of DATA_FILES) {
    const p = path.join(DATA_DIR, f);
    await fsp.access(p, fs.constants.R_OK);
    const raw = await fsp.readFile(p, 'utf8');
    try {
      JSON.parse(raw);
      results.push({ file: f, parsed: true });
    } catch (e) {
      throw new Error(`invalid JSON: ${f}`);
    }
  }
  return { files: results };
}

async function checkStorage(req) {
  // If you attached a storage on app (e.g., RedisProfileStorage), try to ping it.
  const storage = req.app.get('profileStorage');
  if (!storage) return { skipped: true, reason: 'no storage attached' };

  // Convention: if the adapter exposes .ping() use it; else try a get/set noop.
  if (typeof storage.ping === 'function') {
    const pong = await storage.ping();
    if (pong !== true && pong !== 'PONG') throw new Error('storage ping failed');
    return { pong: pong };
  }

  const key = '__health_probe__' + Date.now();
  try {
    if (typeof storage.set === 'function') await storage.set(key, { t: Date.now() });
    if (typeof storage.get === 'function') await storage.get(key);
    if (typeof storage.delete === 'function') await storage.delete(key);
    return { pong: true };
  } catch (e) {
    throw new Error('storage R/W failed: ' + e.message);
  }
}

async function checkDns() {
  // Validate that public DNS works (good general network sanity check)
  await dns.lookup('example.com');
  return { ok: true };
}

async function checkMemoryAndLoop() {
  const mem = process.memoryUsage();
  const loopDelayMs = await eventLoopDelaySample(100);
  return {
    rss: bytes(mem.rss),
    heapUsed: bytes(mem.heapUsed),
    heapTotal: bytes(mem.heapTotal),
    external: bytes(mem.external || 0),
    eventLoopDelayMs: loopDelayMs
  };
}

// ---------- Route Handlers ----------
router.get('/live', (_req, res) => {
  res.json({
    ok: true,
    service: 'unsaid-api',
    bootTimeISO: new Date(bootTime).toISOString(),
    now: new Date().toISOString()
  });
});

router.get('/ready', async (req, res) => {
  const checks = await Promise.all([
    withTimeout('env', () => checkEnvVars()),
    withTimeout('data', () => checkDataFiles()),
    withTimeout('storage', () => checkStorage(req)),
    withTimeout('dns', () => checkDns()),
    withTimeout('resources', () => checkMemoryAndLoop())
  ]);

  const { ok, failing } = summarize(checks);
  const status = ok ? 200 : 503;

  res.status(status).json({
    ok,
    failing,
    checks
  });
});

router.get('/status', async (req, res) => {
  const uptimeMs = Date.now() - bootTime;

  const checks = await Promise.all([
    withTimeout('env', () => checkEnvVars()),
    withTimeout('data', () => checkDataFiles()),
    withTimeout('storage', () => checkStorage(req)),
    withTimeout('dns', () => checkDns()),
    withTimeout('resources', () => checkMemoryAndLoop())
  ]);

  const { ok, failing } = summarize(checks);

  res.status(ok ? 200 : 207).json({
    ok,
    service: 'unsaid-api',
    node: process.version,
    env: process.env.NODE_ENV || 'development',
    uptime: {
      ms: uptimeMs,
      seconds: Math.floor(uptimeMs / 1000),
      minutes: Math.floor(uptimeMs / 60000)
    },
    timestamp: new Date().toISOString(),
    failing,
    checks
  });
});

module.exports = router;

/**
 * config/env.js
 *
 * Centralized environment management with validation and sane defaults.
 * - Supports type coercion (string/number/boolean/array/json)
 * - Clear errors for required variables
 * - Namespaced config blocks (jwt, db, redis, metrics, service)
 */

require('dotenv').config();

console.log('[DEBUG] env.js starting...');

// ---------- helpers ----------
function coerce(val, type) {
  if (val == null) return val;
  switch (type) {
    case 'number':
      return Number(val);
    case 'boolean':
      return val === 'true' || val === true;
    case 'array':
      return String(val)
        .split(',')
        .map((s) => s.trim())
        .filter(Boolean);
    case 'json':
      try {
        return JSON.parse(val);
      } catch {
        throw new Error(`Invalid JSON in env var: ${val}`);
      }
    default:
      return val;
  }
}

function getEnv(key, { fallback, required = false, type = 'string' } = {}) {
  const raw = process.env[key] ?? fallback;
  if (required && (raw === undefined || raw === null)) {
    throw new Error(`Missing required environment variable: ${key}`);
  }
  return coerce(raw, type);
}

console.log('[DEBUG] Helper functions defined...');

// ---------- exports ----------
console.log('[DEBUG] Creating exports...');
const nodeEnv = getEnv('NODE_ENV', { fallback: 'development' });
const isProd = nodeEnv === 'production';
const isTest = nodeEnv === 'test';
const isDev = !isProd && !isTest;

console.log('[DEBUG] Basic values created, nodeEnv:', nodeEnv);

const exports = {
  nodeEnv,
  isProd,
  isDev,
  isTest,

  service: {
    name: getEnv('SERVICE_NAME', { fallback: 'unsaid-api' }),
    version: getEnv('SERVICE_VERSION', { fallback: '0.0.0' }),
    port: getEnv('PORT', { fallback: 3000, type: 'number' }),
  },

  log: {
    level: getEnv('LOG_LEVEL', { fallback: 'info' }),
    pretty: getEnv('PRETTY_LOGS', { fallback: isDev ? 'true' : 'false', type: 'boolean' }),
  },

  jwt: {
    publicKey: getEnv('JWT_PUBLIC_KEY'),
    audience: getEnv('JWT_AUDIENCE'),
    issuer: getEnv('JWT_ISSUER'),
  },

  db: {
    url: getEnv('DATABASE_URL'),
    poolMin: getEnv('DB_POOL_MIN', { fallback: 2, type: 'number' }),
    poolMax: getEnv('DB_POOL_MAX', { fallback: 10, type: 'number' }),
  },

  redis: {
    url: getEnv('REDIS_URL'),
    prefix: getEnv('REDIS_PREFIX', { fallback: 'unsaid:' }),
  },

  metrics: {
    enabled: getEnv('METRICS_ENABLED', { fallback: 'true', type: 'boolean' }),
    token: getEnv('METRICS_TOKEN'),
    pushGateway: getEnv('PUSHGATEWAY_URL'),
  },

  // for feature flags or array configs
  features: getEnv('ENABLED_FEATURES', { type: 'array', fallback: '' }),
};

console.log('[DEBUG] Exports object created, keys:', Object.keys(exports));
console.log('[DEBUG] About to export...');
module.exports = exports;
console.log('[DEBUG] Module exported successfully!');

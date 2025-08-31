/**
 * config/logger.js
 *
 * Robust Pino logger:
 * - pretty in dev, structured JSON in prod
 * - default labels (service, env, version)
 * - safe redaction
 * - child logger factory
 */

const pino = require('pino');
const crypto = require('crypto');

const {
  nodeEnv = process.env.NODE_ENV || 'development',
  logLevel = process.env.LOG_LEVEL || 'info',
  isProd = nodeEnv === 'production',
  serviceName = process.env.SERVICE_NAME || 'unsaid-api',
  serviceVersion = process.env.SERVICE_VERSION || '0.0.0',
  prettyLogs = process.env.PRETTY_LOGS === '1' || !isProd,
} = require('./env-simple');

// Pretty transport only outside prod (or when PRETTY_LOGS=1)
const transport = prettyLogs
  ? {
      target: 'pino-pretty',
      options: {
        translateTime: 'SYS:standard',
        colorize: true,
        singleLine: false,
        ignore: 'pid,hostname',
      },
    }
  : undefined;

// Shared redaction list (extensible)
const REDACT_PATHS = [
  'req.headers.authorization',
  'req.headers.cookie',
  'req.body.password',
  'req.body.token',
  'req.body.accessToken',
  'user.token',
  'config.secrets',
  'meta.apiKey',
];

const baseLogger = pino(
  {
    level: logLevel,
    base: { service: serviceName, env: nodeEnv, version: serviceVersion },
    // Helpful for GCP/Loki/Grafana mappings if you need it:
    messageKey: 'message',
    timestamp: pino.stdTimeFunctions.isoTime, // stable ISO timestamps
    formatters: {
      level(label, number) {
        // add numeric level too (useful for some backends)
        return { level: label, lvl: number };
      },
      bindings(bindings) {
        // drop pid/hostname in prod to reduce noise
        const { pid, hostname, ...rest } = bindings;
        return rest;
      },
    },
    redact: { paths: REDACT_PATHS, censor: '[REDACTED]' },
  },
  transport
);

/**
 * Create a child logger with a module/context tag.
 * Usage: const log = logger.child({ module: 'routes/tone' })
 */
function withModule(moduleName, extra = {}) {
  return baseLogger.child({ module: moduleName, ...extra });
}

/**
 * Generate a stable-ish ID (used as fallback for request IDs, jobs, etc.)
 */
function genId(prefix = 'id') {
  return `${prefix}_${crypto.randomBytes(12).toString('base64url')}`;
}

module.exports = Object.assign(baseLogger, {
  withModule,
  genId,
});

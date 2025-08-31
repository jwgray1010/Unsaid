/**
 * middleware/requestLogger.js
 *
 * Robust request logger middleware.
 * - Adds requestId + per-request child logger (req.log)
 * - Logs method, route, status, duration, ip, ua, size
 * - Skips noisy routes (/health, /metrics, /favicon.ico)
 * - Warns on slow requests
 * - Supports sampling for success logs
 *
 * Requires: app.set('logger', logger) in app.js
 */

console.log('[DEBUG] requestLogger.js starting...');

const crypto = require('crypto');

console.log('[DEBUG] crypto loaded...');

const SLOW_MS = Number(process.env.REQUEST_SLOW_MS || 1000);
const SAMPLE_RATE = Number(process.env.REQUEST_LOG_SAMPLE_RATE || 1.0); // 0..1

function genRequestId() {
  return crypto.randomBytes(8).toString('hex');
}

function shouldLog(url) {
  if (!url) return true;
  if (url.startsWith('/health')) return false;
  if (url.startsWith('/metrics')) return false;
  if (url.startsWith('/favicon')) return false;
  return true;
}

module.exports = function requestLogger() {
  console.log('[DEBUG] requestLogger factory function called...');
  return (req, res, next) => {
    const baseLogger = req.app.get('logger') || console;
    const reqId =
      req.headers['x-request-id'] ||
      req.headers['x-correlation-id'] ||
      genRequestId();

    // attach per-request child logger
    req.id = reqId;
    req.log = baseLogger.child ? baseLogger.child({ reqId }) : baseLogger;

    const start = process.hrtime.bigint();

    res.on('finish', () => {
      if (!shouldLog(req.originalUrl)) return;

      const end = process.hrtime.bigint();
      const durationMs = Number(end - start) / 1e6;
      const status = res.statusCode;
      const info = {
        reqId,
        method: req.method,
        url: req.originalUrl,
        route: req.route?.path || req.baseUrl || undefined,
        status,
        duration: durationMs.toFixed(2),
        user: req.user?.id || 'anon',
        ip: req.ip,
        ua: req.headers['user-agent'],
        bytes: Number(res.getHeader('Content-Length')) || 0,
      };

      let level = 'info';
      if (status >= 500) level = 'error';
      else if (status >= 400) level = 'warn';
      else if (durationMs >= SLOW_MS) level = 'warn';

      // sample out some success logs
      if (status < 400 && SAMPLE_RATE < 1 && Math.random() > SAMPLE_RATE) {
        return;
      }

      if (req.log[level]) {
        req.log[level](info, 'HTTP request');
      } else {
        // fallback for console
        baseLogger.log(level.toUpperCase(), info);
      }
    });

    next();
  };
};

console.log('[DEBUG] requestLogger.js module.exports defined...');
console.log('[DEBUG] requestLogger.js finished loading.');

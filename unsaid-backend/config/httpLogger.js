/**
 * config/httpLogger.js
 *
 * Express middleware for robust HTTP request logging with Pino.
 */

const logger = require('./logger');
const crypto = require('crypto');

const SLOW_THRESHOLD_MS = Number(process.env.REQUEST_SLOW_MS || 1000);
const SAMPLE_RATE = Number(process.env.REQUEST_LOG_SAMPLE_RATE || 1.0); // 0..1

function genRequestId() {
  return crypto.randomBytes(8).toString('hex');
}

function shouldLog(url) {
  if (!url) return true;
  if (url.startsWith('/health') || url.startsWith('/metrics')) return false;
  return true;
}

function httpLogger(req, res, next) {
  const start = process.hrtime.bigint();
  const requestId =
    req.headers['x-request-id'] ||
    req.headers['x-correlation-id'] ||
    genRequestId();

  // Attach per-request logger
  req.id = requestId;
  req.log = logger.child({ reqId: requestId });

  res.on('finish', () => {
    if (!shouldLog(req.originalUrl)) return;

    const end = process.hrtime.bigint();
    const durationMs = Number(end - start) / 1e6;

    // basic request info
    const info = {
      reqId: requestId,
      method: req.method,
      url: req.originalUrl,
      route: req.route?.path || req.baseUrl || undefined,
      status: res.statusCode,
      duration: durationMs,
      user: req.user?.id || 'anon',
      ip: req.ip,
      ua: req.headers['user-agent'],
      bytes: Number(res.getHeader('Content-Length')) || 0,
    };

    // choose level
    let level = 'info';
    if (res.statusCode >= 500) level = 'error';
    else if (res.statusCode >= 400) level = 'warn';
    else if (durationMs >= SLOW_THRESHOLD_MS) level = 'warn';

    // sampling: keep all errors, sample successes
    if (res.statusCode < 400 && SAMPLE_RATE < 1) {
      if (Math.random() > SAMPLE_RATE) return;
    }

    req.log[level](info, 'HTTP request');
  });

  next();
}

module.exports = httpLogger;

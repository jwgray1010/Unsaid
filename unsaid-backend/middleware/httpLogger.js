/**
 * middleware/httpLogger.js
 *
 * Express middleware for HTTP logs:
 * - per-request child logger with requestId
 * - auto log on completion (method, route, status, ms, bytes)
 * - ignores /health and /metrics by default
 * - slow-request warning & optional sampling
 */

const pinoHttp = require('pino-http');
const logger = require('../config/logger');

// Use environment variables directly (simpler approach)
const REQUEST_LOG_SAMPLE_RATE = process.env.REQUEST_LOG_SAMPLE_RATE || '1.0';
const REQUEST_SLOW_MS = process.env.REQUEST_SLOW_MS || '800';

const sampleRate = Math.max(0, Math.min(1, Number(REQUEST_LOG_SAMPLE_RATE)));
const slowMs = Math.max(1, Number(REQUEST_SLOW_MS) || 800);

// Basic route filter (feel free to expand)
function shouldAutoLog(req) {
  const p = req.originalUrl || req.url || '';
  if (p.startsWith('/health') || p.startsWith('/metrics')) return false;
  return true;
}

// Request ID resolver
function getRequestId(req) {
  return (
    req.headers['x-request-id'] ||
    req.headers['x-correlation-id'] ||
    logger.genId('req')
  );
}

const httpLogger = pinoHttp({
  logger,
  genReqId: getRequestId,
  autoLogging: {
    ignore: (req) => !shouldAutoLog(req),
  },
  customLogLevel: (res, err) => {
    if (err) return 'error';
    const status = res.statusCode;
    if (status >= 500) return 'error';
    if (status >= 400) return 'warn';
    return 'info';
  },
  serializers: {
    // keep req small but useful
    req(req) {
      return {
        id: req.id,
        method: req.method,
        url: req.originalUrl || req.url,
        route: req.route?.path || req.baseUrl || undefined,
        remoteAddress: req.ip,
        userAgent: req.headers['user-agent'],
      };
    },
    res(res) {
      return {
        statusCode: res.statusCode,
        contentLength: res.getHeader('content-length'),
      };
    },
    err: pinoHttp.stdSerializers.err,
  },
  customSuccessMessage: function (res) {
    return `completed ${res.statusCode}`;
  },
  // runs after response finished
  customSuccessObject: function (req, res, val) {
    const duration = res.responseTime; // ms
    const route = req.route?.path || req.baseUrl || req.url;
    const msg = {
      ...val,
      route,
      duration,
    };

    // mark slow ones
    if (duration >= slowMs) {
      // emit a secondary warn with context
      req.log.warn(
        { route, duration, status: res.statusCode, method: req.method },
        'slow request'
      );
    }

    // sampling: drop some success logs if requested
    if (res.statusCode < 400 && sampleRate < 1) {
      if (Math.random() > sampleRate) {
        // instruct pino-http to skip writing this one
        return null;
      }
    }
    return msg;
  },
});

module.exports = httpLogger;

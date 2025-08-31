/**
 * middleware/rateLimiter.js
 *
 * Robust rate limiter middleware for Express.
 * - Per-IP or per-user keys
 * - Env-driven config
 * - Custom headers + logging
 * - Ready to swap to Redis or other stores
 */

console.log('[DEBUG] rateLimiter.js starting...');

const rateLimit = require('express-rate-limit');
console.log('[DEBUG] express-rate-limit loaded...');

const RedisStore = require('rate-limit-redis'); // optional, only if redis configured
console.log('[DEBUG] rate-limit-redis loaded...');

const logger = require('../config/logger');
console.log('[DEBUG] logger loaded...');

const {
  RATE_LIMIT_WINDOW = 15 * 60 * 1000, // 15 minutes
  RATE_LIMIT_MAX = 100,               // requests per window
  RATE_LIMIT_MESSAGE = 'Too many requests, please try again later.',
  RATE_LIMIT_REDIS_URL = process.env.REDIS_URL,
} = process.env;

module.exports = function rateLimiter(options = {}) {
  const {
    windowMs = Number(options.windowMs || RATE_LIMIT_WINDOW),
    max = Number(options.max || RATE_LIMIT_MAX),
    message = options.message || RATE_LIMIT_MESSAGE,
    standardHeaders = true, // add RateLimit-* headers
    legacyHeaders = false,  // disable deprecated X-RateLimit-* headers
    keyGenerator = (req) => req.user?.id || req.ip,
    skip = (req) => false, // optionally skip certain routes
  } = options;

  let store;
  if (RATE_LIMIT_REDIS_URL) {
    // If Redis is available, use it
    try {
      store = new RedisStore({
        sendCommand: async (...args) => {
          const { createClient } = await import('redis');
          const client = createClient({ url: RATE_LIMIT_REDIS_URL });
          if (!client.isOpen) await client.connect();
          return client.sendCommand(args);
        },
      });
    } catch (err) {
      logger.warn({ err }, 'Redis store unavailable, falling back to memory store');
    }
  }

  return rateLimit({
    windowMs,
    max,
    message,
    standardHeaders,
    legacyHeaders,
    keyGenerator,
    skip,
    store, // if undefined, defaults to in-memory
    handler: (req, res, next, opts) => {
      logger.warn(
        {
          key: keyGenerator(req),
          route: req.originalUrl,
          max: opts.max,
          windowMs: opts.windowMs,
        },
        'Rate limit exceeded'
      );
      res.status(opts.statusCode).json({
        error: true,
        message: opts.message,
        retryAfter: Math.ceil(opts.windowMs / 1000),
      });
    },
  });
};

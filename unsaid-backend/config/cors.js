/**
 * config/cors.js
 *
 * Robust CORS setup for Unsaid API.
 * - Allows multiple origins via list, regex, or "*"
 * - Configurable via env vars
 * - Supports credentials
 * - Logs or rejects disallowed origins
 */

const cors = require('cors');
const logger = require('./logger');

const {
  CORS_ORIGINS = 'https://myunsaidapp.com,https://www.api.myunsaidapp.com,http://localhost:3000',
  CORS_METHODS = 'GET,POST,PUT,PATCH,DELETE,OPTIONS',
  CORS_HEADERS = 'Content-Type,Authorization,X-Requested-With',
  CORS_CREDENTIALS = 'true',
  CORS_MAX_AGE = '600', // seconds for preflight cache
} = process.env;

// parse origins into array
const allowedOrigins = CORS_ORIGINS.split(',')
  .map((o) => o.trim())
  .filter(Boolean);

function isOriginAllowed(origin) {
  if (!origin) return false;
  if (allowedOrigins.includes('*')) return true;

  // support regex origins if written like `/regex/`
  for (const entry of allowedOrigins) {
    if (entry.startsWith('/') && entry.endsWith('/')) {
      try {
        const regex = new RegExp(entry.slice(1, -1));
        if (regex.test(origin)) return true;
      } catch (e) {
        logger.warn({ entry }, 'Invalid CORS regex entry');
      }
    }
  }

  return allowedOrigins.includes(origin);
}

module.exports = function corsConfig() {
  return cors({
    origin: function (origin, callback) {
      if (!origin) return callback(null, true); // allow server-to-server/no-origin requests

      if (isOriginAllowed(origin)) {
        return callback(null, true);
      }

      logger.warn({ origin }, 'Blocked by CORS');
      return callback(new Error('Not allowed by CORS'));
    },
    methods: CORS_METHODS.split(',').map((m) => m.trim()),
    allowedHeaders: CORS_HEADERS.split(',').map((h) => h.trim()),
    credentials: CORS_CREDENTIALS === 'true',
    maxAge: parseInt(CORS_MAX_AGE, 10),
    optionsSuccessStatus: 204, // some legacy browsers choke on 200
  });
};

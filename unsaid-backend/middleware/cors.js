/**
 * middleware/cors.js
 *
 * Robust CORS setup for Unsaid API.
 * - Allows multiple origins (list, regex, wildcard)
 * - Driven by environment variables
 * - Logs blocked origins
 */

console.log('[DEBUG] cors.js starting...');

const corsPackage = require('cors');
const logger = require('../config/logger');

console.log('[DEBUG] cors package loaded, logger loaded...');

const {
  CORS_ORIGINS = 'https://myunsaidapp.com,https://api.myunsaidapp.com,http://localhost:3000',
  CORS_METHODS = 'GET,POST,PUT,PATCH,DELETE,OPTIONS',
  CORS_HEADERS = 'Content-Type,Authorization,X-Requested-With',
  CORS_CREDENTIALS = 'true',
  CORS_MAX_AGE = '600', // seconds for preflight cache
} = process.env;

// parse comma-separated origins into array
const allowedOrigins = CORS_ORIGINS.split(',')
  .map(o => o.trim())
  .filter(Boolean);

function isOriginAllowed(origin) {
  if (!origin) return false;
  if (allowedOrigins.includes('*')) return true;

  for (const entry of allowedOrigins) {
    // regex support if written like `/pattern/`
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

module.exports = function corsMiddleware() {
  console.log('[DEBUG] corsMiddleware factory called...');
  return corsPackage({
    origin: function (origin, callback) {
      if (!origin) return callback(null, true); // allow non-browser requests

      if (isOriginAllowed(origin)) {
        return callback(null, true);
      }

      logger.warn({ origin }, 'CORS blocked origin');
      return callback(new Error('Not allowed by CORS'));
    },
    methods: CORS_METHODS.split(',').map(m => m.trim()),
    allowedHeaders: CORS_HEADERS.split(',').map(h => h.trim()),
    credentials: CORS_CREDENTIALS === 'true',
    maxAge: parseInt(CORS_MAX_AGE, 10),
    optionsSuccessStatus: 204, // legacy browser quirk
  });
};

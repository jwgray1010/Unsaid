/**
 * middleware/errorHandler.js
 *
 * Centralized error handler for Express.
 * - Distinguishes trusted vs unexpected errors
 * - Logs stack trace (only exposes in response if dev)
 * - Adds reqId for traceability
 * - Handles validation errors cleanly
 */

const { nodeEnv } = require('../config/env');

function isValidationError(err) {
  return err.name === 'ValidationError' || err.isJoi || err.keyword; // ajv/joi
}

module.exports = function errorHandler() {
  return (err, req, res, _next) => {
    const logger = req.app.get('logger') || console;
    const reqId = req.id || req.headers['x-request-id'];

    const status = err.status && Number.isInteger(err.status) ? err.status : 500;
    const code = err.code || (status === 500 ? 'ERR_INTERNAL' : 'ERR_GENERIC');

    // build response object
    const payload = {
      ok: false,
      error: err.message || 'Internal Server Error',
      code,
      reqId,
    };

    if (isValidationError(err)) {
      payload.code = 'ERR_VALIDATION';
      payload.details = err.details || err.errors || err.stack;
    }

    // Only include stack in non-prod
    if (nodeEnv !== 'production' && err.stack) {
      payload.stack = err.stack.split('\n');
    }

    // if headers already sent, delegate to express
    if (res.headersSent) {
      return _next(err);
    }

    // structured log
    logger.error(
      {
        err,
        reqId,
        path: req.originalUrl,
        method: req.method,
        status,
      },
      'Request failed'
    );

    res.status(status).json(payload);
  };
};

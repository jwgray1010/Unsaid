// middleware/index.js

const jwAuth = require('./jwAuth');  // Fixed to match actual filename
const requestLogger = require('./requestLogger');
const errorHandler = require('./errorHandler');
const rateLimiter = require('./rateLimiter');
const cors = require('./cors');

// Optional helper to assemble a default stack (use later in app.js if you want)
function coreMiddlewareStack(app, { requireJWT = false, rate = { windowMs: 15 * 60 * 1000, max: 100 } } = {}) {
  app.use(cors());
  app.use(requestLogger());
  if (requireJWT) app.use(jwAuth({ required: true }));
  app.use(rateLimiter(rate));
}

module.exports = {
  jwAuth,  // Export with corrected name
  jwtAuth: jwAuth,  // Also export with old name for compatibility
  requestLogger,
  errorHandler,
  rateLimiter,
  cors,
  coreMiddlewareStack,
};
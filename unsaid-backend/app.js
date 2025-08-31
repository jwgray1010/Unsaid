// app.js
const express = require('express');
const cookieParser = require('cookie-parser');
const compression = require('compression');

const logger = require('./config/logger');
const httpLogger = require('./middleware/httpLogger');
const requestLogger = require('./middleware/requestLogger');
const cors = require('./middleware/cors');
const rateLimiter = require('./middleware/rateLimiter');
const jwAuth = require('./middleware/jwAuth');
const { metricsMiddleware, metricsEndpoint } = require('./config/metrics');
const errorHandler = require('./middleware/errorHandler');

const healthRoutes = require('./api/health');
const toneRoutes = require('./api/tone');
const suggestionsRoutes = require('./api/suggestions');

const app = express();

// Base hardening
app.disable('x-powered-by');
app.set('logger', logger);
app.set('trust proxy', true);

// ---------- Global middleware (order matters) ----------
app.use(httpLogger);              // access logs (already configured)
app.use(requestLogger());         // req.id + req.log everywhere
app.use(cors());                  // CORS early
app.options('*', cors());         // handle preflight for all routes
app.use(compression());           // gzip responses
app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ extended: true }));
app.use(cookieParser());
app.use(metricsMiddleware);       // res.locals.metrics helpers

// Rate limit globally, but skip health/metrics (less noise, friendlier to monitors)
app.use(rateLimiter({
  skip: (req) => req.path.startsWith('/health') || req.path.startsWith('/metrics')
}));

// Public utility routes (no auth needed)
app.get('/metrics', metricsEndpoint);
app.use('/health', healthRoutes);
app.get('/version', (_req, res) => {
  res.json({
    ok: true,
    service: process.env.SERVICE_NAME || 'unsaid-api',
    version: process.env.SERVICE_VERSION || '0.0.0',
    env: process.env.NODE_ENV || 'development'
  });
});

// Auth (passthrough by default). Mount on /api space so public routes stay clean.
app.use('/api', jwAuth());

// ---------- API routes ----------
app.use('/api/tone', toneRoutes);

// Example: require auth (and scopes) just for premium suggestions
const premiumGuard = jwAuth({ required: true, requireScopes: ['suggestions:write'] });
app.use('/api/suggestions', premiumGuard, suggestionsRoutes);

// 404 handler
app.use((req, res) => {
  req.log?.warn({ path: req.originalUrl }, 'Not Found');
  res.status(404).json({ ok: false, error: 'Not Found', code: 'ERR_NOT_FOUND', reqId: req.id });
});

// Central error handler (keep last)
app.use(errorHandler());

module.exports = app;
/**
 * config/metrics.js
 *
 * Production-grade Prometheus metrics for an Express/Node service.
 * - Per-route HTTP request duration histogram
 * - In-flight requests gauge
 * - Request/response size histograms
 * - Error counter
 * - Helpers to time arbitrary async work (DB/cache/external calls)
 * - Optional Pushgateway publishing
 * - Optional bearer-token protection for /metrics
 */

const client = require('prom-client');
const zlib = require('zlib');

// ---- Load env directly (avoid circular deps) ----
require('dotenv').config();

const {
  metricsEnabled = process.env.METRICS_ENABLED !== 'false',
  metricsPrefix = 'unsaid_',
  metricsToken = process.env.METRICS_TOKEN || '',
  serviceName = process.env.SERVICE_NAME || 'unsaid-api',
  nodeEnv = process.env.NODE_ENV || 'development',
  serviceVersion = process.env.SERVICE_VERSION || '0.0.0',
  pushgatewayUrl = process.env.PUSHGATEWAY_URL || '',
  metricsBuckets = process.env.METRICS_BUCKETS || '',
} = {};

// ---- Registry & defaults ----
const register = new client.Registry();
client.register.clear(); // ensure clean in tests/reloads

register.setDefaultLabels({
  service: serviceName,
  env: nodeEnv,
  version: serviceVersion,
});

client.collectDefaultMetrics({
  register,
  prefix: metricsPrefix,
  gcDurationBuckets: [0.001, 0.01, 0.1, 1, 2, 5],
});

// ---- Common buckets ----
const defaultHttpBuckets = (metricsBuckets
  ? metricsBuckets.split(',').map(Number).filter(n => !Number.isNaN(n))
  : [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10]);

// ---- Core metrics ----
const httpRequestDuration = new client.Histogram({
  name: `${metricsPrefix}http_request_duration_seconds`,
  help: 'HTTP request duration in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: defaultHttpBuckets,
});

const httpRequestsTotal = new client.Counter({
  name: `${metricsPrefix}http_requests_total`,
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code'],
});

const httpErrorsTotal = new client.Counter({
  name: `${metricsPrefix}http_errors_total`,
  help: 'Total number of HTTP errors (status >= 500)',
  labelNames: ['method', 'route'],
});

const httpInFlight = new client.Gauge({
  name: `${metricsPrefix}http_in_flight_requests`,
  help: 'In-flight HTTP requests',
  labelNames: ['route'],
});

const requestSizeBytes = new client.Histogram({
  name: `${metricsPrefix}http_request_size_bytes`,
  help: 'Approximate size of incoming requests',
  labelNames: ['method', 'route'],
  buckets: [200, 500, 1_000, 5_000, 10_000, 50_000, 100_000, 500_000, 1_000_000],
});

const responseSizeBytes = new client.Histogram({
  name: `${metricsPrefix}http_response_size_bytes`,
  help: 'Approximate size of outgoing responses',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [200, 500, 1_000, 5_000, 10_000, 50_000, 100_000, 500_000, 1_000_000],
});

const upGauge = new client.Gauge({
  name: `${metricsPrefix}up`,
  help: '1 if the service is up',
});

register.registerMetric(httpRequestDuration);
register.registerMetric(httpRequestsTotal);
register.registerMetric(httpErrorsTotal);
register.registerMetric(httpInFlight);
register.registerMetric(requestSizeBytes);
register.registerMetric(responseSizeBytes);
register.registerMetric(upGauge);

// We keep a small map to lazily create custom counters/histograms
const counters = new Map();
const histograms = new Map();
const gauges = new Map();

// ---- Public helpers ----
function inc(name, labels = {}, help = `Counter for ${name}`, labelNames = []) {
  if (!metricsEnabled) return;
  let c = counters.get(name);
  if (!c) {
    c = new client.Counter({ name, help, labelNames });
    register.registerMetric(c);
    counters.set(name, c);
  }
  c.inc(labels);
}

function gaugeSet(name, value, labels = {}, help = `Gauge for ${name}`, labelNames = []) {
  if (!metricsEnabled) return;
  let g = gauges.get(name);
  if (!g) {
    g = new client.Gauge({ name, help, labelNames });
    register.registerMetric(g);
    gauges.set(name, g);
  }
  g.set(labels, value);
}

function observe(name, value, labels = {}, help = `Histogram for ${name}`, labelNames = [], buckets = undefined) {
  if (!metricsEnabled) return;
  let h = histograms.get(name);
  if (!h) {
    h = new client.Histogram({ name, help, labelNames, buckets });
    register.registerMetric(h);
    histograms.set(name, h);
  }
  h.observe(labels, value);
}

/**
 * Time an async function and record a histogram.
 * Usage:
 *   const result = await timeAsync('unsaid_db_query_seconds', { table: 'users' }, () => db.users.find(...))
 */
async function timeAsync(name, labels, fn, opts = {}) {
  if (!metricsEnabled) return fn();
  const start = process.hrtime.bigint();
  try {
    const out = await fn();
    const end = process.hrtime.bigint();
    const seconds = Number(end - start) / 1e9;
    observe(name, seconds, labels, opts.help || `Duration for ${name}`, opts.labelNames || Object.keys(labels || {}), opts.buckets);
    return out;
  } catch (err) {
    const end = process.hrtime.bigint();
    const seconds = Number(end - start) / 1e9;
    observe(name, seconds, { ...labels, error: '1' }, opts.help || `Duration for ${name}`, (opts.labelNames || Object.keys(labels || [])).concat('error'), opts.buckets);
    throw err;
  }
}

// ---- Express middleware ----
function metricsMiddleware(req, res, next) {
  if (!metricsEnabled) return next();

  // Route will be set after routing; default to req.path (may be raw)
  let route = req.route && req.route.path ? req.route.path : (req.baseUrl || req.path || 'unknown');
  const method = (req.method || 'GET').toUpperCase();

  // Approximate request size (headers + body length)
  try {
    const bodyLen = req.headers['content-length'] ? Number(req.headers['content-length']) : (req.rawBody ? Buffer.byteLength(req.rawBody) : 0);
    requestSizeBytes.observe({ method, route }, bodyLen || 0);
  } catch (_) {}

  httpInFlight.inc({ route });

  const endTimer = httpRequestDuration.startTimer({ method, route });

  // Recompute route after the handler (gives express pattern if available)
  res.on('finish', () => {
    // Try to resolve the route pattern if Express has set it
    try {
      route = res.req?.route?.path || res.req?.baseUrl || route || 'unknown';
    } catch (_) {}

    const status_code = res.statusCode;
    endTimer({ status_code, method, route });

    httpRequestsTotal.inc({ method, route, status_code });

    // Response size if available
    try {
      const length = Number(res.getHeader('Content-Length')) || 0;
      responseSizeBytes.observe({ method, route, status_code }, length);
    } catch (_) {}

    if (status_code >= 500) {
      httpErrorsTotal.inc({ method, route });
    }

    httpInFlight.dec({ route });
  });

  // helper access for downstream handlers
  res.locals.metrics = {
    inc,
    observe,
    gaugeSet,
    timeAsync,
  };

  next();
}

// ---- /metrics endpoint (optionally protected & gzip) ----
async function metricsEndpoint(req, res) {
  if (!metricsEnabled) {
    return res.status(404).send('metrics disabled');
  }

  if (metricsToken) {
    const hdr = req.headers.authorization || '';
    const token = hdr.startsWith('Bearer ') ? hdr.slice(7) : '';
    if (token !== metricsToken) return res.status(401).send('unauthorized');
  }

  upGauge.set(1);

  const payload = await register.metrics();
  res.set('Content-Type', register.contentType);

  // gzip if client accepts it
  const accept = `${req.headers['accept-encoding'] || ''}`.toLowerCase();
  if (accept.includes('gzip')) {
    zlib.gzip(payload, (err, buf) => {
      if (err) return res.status(500).send('compression error');
      res.set('Content-Encoding', 'gzip');
      res.end(buf);
    });
  } else {
    res.end(payload);
  }
}

// ---- Pushgateway (optional) ----
let pushInterval = null;
function startPushgateway(jobName = serviceName, intervalMs = 15000) {
  if (!pushgatewayUrl || !metricsEnabled) return;
  const gateway = new client.Pushgateway(pushgatewayUrl, {}, register);
  if (pushInterval) clearInterval(pushInterval);
  pushInterval = setInterval(() => {
    gateway.pushAdd({ jobName }, (err) => {
      if (err) console.error('Pushgateway error:', err.message);
    });
  }, intervalMs);
}

function stopPushgateway() {
  if (pushInterval) clearInterval(pushInterval);
  pushInterval = null;
}

module.exports = {
  register,
  metricsMiddleware,
  metricsEndpoint,
  inc,
  observe,
  gaugeSet,
  timeAsync,
  startPushgateway,
  stopPushgateway,
};

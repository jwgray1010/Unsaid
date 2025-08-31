// config/env-simple.js - Simplified working version
require('dotenv').config();

function getEnv(key, fallback = undefined, type = 'string') {
  const raw = process.env[key] ?? fallback;
  
  switch (type) {
    case 'number': return Number(raw);
    case 'boolean': return raw === 'true';
    default: return raw;
  }
}

const nodeEnv = getEnv('NODE_ENV', 'development');

module.exports = {
  nodeEnv,
  isProd: nodeEnv === 'production',
  isDev: nodeEnv === 'development',
  isTest: nodeEnv === 'test',

  service: {
    name: getEnv('SERVICE_NAME', 'unsaid-api'),
    version: getEnv('SERVICE_VERSION', '0.0.0'),
    port: getEnv('PORT', 3000, 'number'),
  },

  log: {
    level: getEnv('LOG_LEVEL', 'info'),
    pretty: getEnv('PRETTY_LOGS', 'true', 'boolean'),
  },

  jwt: {
    publicKey: getEnv('JWT_PUBLIC_KEY'),
    audience: getEnv('JWT_AUDIENCE'),
    issuer: getEnv('JWT_ISSUER'),
  },

  metrics: {
    enabled: getEnv('METRICS_ENABLED', 'true', 'boolean'),
    token: getEnv('METRICS_TOKEN'),
    pushGateway: getEnv('PUSHGATEWAY_URL'),
  },
};

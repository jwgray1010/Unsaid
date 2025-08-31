/**
 * config/index.js
 *
 * Barrel export for all config utilities.
 * Usage:
 *   const { env, logger, httpLogger, metrics, corsConfig } = require('./config');
 */

const env = require('./env');
const logger = require('./logger');
const httpLogger = require('./httpLogger');
const metrics = require('./metrics');
const corsConfig = require('./cors');

module.exports = {
  env,
  logger,
  httpLogger,
  metrics,
  corsConfig
};

// api/v1/health.ts
/**
 * Comprehensive health + readiness checks for Unsaid API (Vercel serverless).
 * 
 * Routes:
 *   GET /health?check=live    -> liveness (fast)
 *   GET /health?check=ready   -> readiness (dependencies + data validated)
 *   GET /health?check=status  -> detailed report (for dashboards/alerts)
 *   GET /health               -> default status check
 */

import { VercelRequest, VercelResponse } from '@vercel/node';
import { promises as fs } from 'fs';
import { promises as dns } from 'dns';
import { performance } from 'perf_hooks';
import path from 'path';
import { compose, withCors, withMethods, withErrorHandling, withLogging } from '../_lib/wrappers';
import { success, error } from '../_lib/http';
import { env } from '../_lib/env';
import { logger } from '../_lib/logger';

// ---------- Configuration ----------
const bootTime = Date.now();

const REQUIRED_ENVS = [
  'NODE_ENV',
  'FIREBASE_PROJECT_ID',
  'FIREBASE_API_KEY',
  'OPENAI_API_KEY',
  // Add other critical env vars as needed
];

const DATA_FILES = [
  'learning_signals.json',
  'tone_triggerwords.json',
  'intensity_modifiers.json',
  'sarcasm_indicators.json',
  'negation_patterns.json',
  'context_classifier.json',
  'therapy_advice.json',
  'onboarding_playbook.json',
  'phrases_edges.json',
  'severity_collaboration.json',
  'weight_modifiers.json',
  'semantic_thesaurus.json',
  'profanity_lexicon.json',
];

const DEFAULT_CHECK_TIMEOUT_MS = 1500;

// ---------- Types ----------
interface HealthCheck {
  name: string;
  ok: boolean;
  info?: any;
  error?: string;
}

interface HealthSummary {
  ok: boolean;
  failing: string[];
}

// ---------- Utilities ----------
async function withTimeout<T>(
  name: string, 
  fn: () => Promise<T>, 
  timeoutMs: number = DEFAULT_CHECK_TIMEOUT_MS
): Promise<HealthCheck> {
  let timer: NodeJS.Timeout;
  
  try {
    const promise = Promise.resolve().then(fn);
    const timeout = new Promise<never>((_resolve, reject) => {
      timer = setTimeout(() => reject(new Error(`timeout:${name}`)), timeoutMs);
    });
    
    const result = await Promise.race([promise, timeout]);
    clearTimeout(timer!);
    
    return { 
      name, 
      ok: true, 
      info: result ?? true 
    };
  } catch (err) {
    clearTimeout(timer!);
    return { 
      name, 
      ok: false, 
      error: err instanceof Error ? err.message : String(err) 
    };
  }
}

function summarize(results: HealthCheck[]): HealthSummary {
  const ok = results.every(r => r.ok);
  const failing = results.filter(r => !r.ok).map(r => r.name);
  return { ok, failing };
}

function formatBytes(bytes: number): string {
  const MB = 1024 * 1024;
  return Math.round((bytes / MB) * 10) / 10 + 'MB';
}

async function eventLoopDelaySample(sampleMs: number = 120): Promise<number> {
  const start = performance.now();
  await new Promise(resolve => setTimeout(resolve, sampleMs));
  const end = performance.now();
  const delay = Math.max(0, (end - start) - sampleMs);
  return Math.round(delay);
}

// ---------- Individual Health Checks ----------

async function checkEnvVars(): Promise<{ present: string[]; missing?: string[] }> {
  const missing = REQUIRED_ENVS.filter(key => !process.env[key]);
  if (missing.length > 0) {
    throw new Error(`missing envs: ${missing.join(', ')}`);
  }
  return { present: REQUIRED_ENVS };
}

async function checkDataFiles(): Promise<{ files: Array<{ file: string; parsed: boolean }> }> {
  const results: Array<{ file: string; parsed: boolean }> = [];
  const dataDir = path.join(process.cwd(), 'data');
  
  for (const file of DATA_FILES) {
    try {
      const filePath = path.join(dataDir, file);
      const content = await fs.readFile(filePath, 'utf8');
      JSON.parse(content); // Validate JSON
      results.push({ file, parsed: true });
    } catch (err) {
      // For optional files, log but don't fail
      if (file.includes('semantic_thesaurus') || file.includes('profanity_lexicon')) {
        logger.warn(`Optional data file missing: ${file}`);
        continue;
      }
      throw new Error(`invalid or missing JSON: ${file}`);
    }
  }
  
  return { files: results };
}

async function checkFirebaseConnection(): Promise<{ configured: boolean; projectId: string }> {
  // Basic Firebase configuration check
  if (!env.FIREBASE_PROJECT_ID || !env.FIREBASE_API_KEY) {
    throw new Error('Firebase configuration incomplete');
  }
  
  return {
    configured: true,
    projectId: env.FIREBASE_PROJECT_ID
  };
}

async function checkOpenAI(): Promise<{ configured: boolean; keyPresent: boolean }> {
  if (!env.OPENAI_API_KEY) {
    throw new Error('OpenAI API key not configured');
  }
  
  // Could add actual API test here if needed
  return {
    configured: true,
    keyPresent: !!env.OPENAI_API_KEY
  };
}

async function checkDns(): Promise<{ resolved: boolean }> {
  await dns.lookup('example.com');
  return { resolved: true };
}

async function checkMemoryAndEventLoop(): Promise<{
  rss: string;
  heapUsed: string;
  heapTotal: string;
  external: string;
  eventLoopDelayMs: number;
}> {
  const mem = process.memoryUsage();
  const loopDelayMs = await eventLoopDelaySample(100);
  
  return {
    rss: formatBytes(mem.rss),
    heapUsed: formatBytes(mem.heapUsed),
    heapTotal: formatBytes(mem.heapTotal),
    external: formatBytes(mem.external),
    eventLoopDelayMs: loopDelayMs
  };
}

// ---------- Route Handlers ----------

async function handleLiveness(): Promise<any> {
  return {
    ok: true,
    service: 'unsaid-api',
    bootTimeISO: new Date(bootTime).toISOString(),
    now: new Date().toISOString(),
    uptime: process.uptime()
  };
}

async function handleReadiness(): Promise<any> {
  const checks = await Promise.all([
    withTimeout('env', checkEnvVars),
    withTimeout('data', checkDataFiles),
    withTimeout('firebase', checkFirebaseConnection),
    withTimeout('openai', checkOpenAI),
    withTimeout('dns', checkDns),
    withTimeout('resources', checkMemoryAndEventLoop)
  ]);

  const { ok, failing } = summarize(checks);
  
  return {
    ok,
    failing,
    checks
  };
}

async function handleDetailedStatus(): Promise<any> {
  const uptimeMs = Date.now() - bootTime;
  
  const checks = await Promise.all([
    withTimeout('env', checkEnvVars),
    withTimeout('data', checkDataFiles),
    withTimeout('firebase', checkFirebaseConnection),
    withTimeout('openai', checkOpenAI),
    withTimeout('dns', checkDns),
    withTimeout('resources', checkMemoryAndEventLoop)
  ]);

  const { ok, failing } = summarize(checks);

  return {
    ok,
    service: 'unsaid-api',
    version: 'v1.0.0',
    node: process.version,
    env: env.NODE_ENV,
    uptime: {
      ms: uptimeMs,
      seconds: Math.floor(uptimeMs / 1000),
      minutes: Math.floor(uptimeMs / 60000)
    },
    timestamp: new Date().toISOString(),
    failing,
    checks,
    features: {
      enabledFeatures: env.ENABLED_FEATURES?.split(',') || [],
      cors: env.CORS_ORIGINS,
      rateLimit: {
        window: env.RATE_LIMIT_WINDOW,
        max: env.RATE_LIMIT_MAX
      }
    },
    firebase: {
      projectId: env.FIREBASE_PROJECT_ID,
      configured: true
    },
    openai: {
      configured: !!env.OPENAI_API_KEY
    }
  };
}

// ---------- Main Handler ----------
const handler = async (req: VercelRequest, res: VercelResponse) => {
  try {
    const checkType = req.query.check as string || 'status';
    let result: any;
    let statusCode = 200;

    switch (checkType) {
      case 'live':
        result = await handleLiveness();
        break;
        
      case 'ready':
        result = await handleReadiness();
        statusCode = result.ok ? 200 : 503;
        break;
        
      case 'status':
      default:
        result = await handleDetailedStatus();
        statusCode = result.ok ? 200 : 207; // 207 Multi-Status for partial failures
        break;
    }

    res.status(statusCode).json({
      success: result.ok !== false,
      data: result,
      timestamp: new Date().toISOString(),
      version: 'v1'
    });
    
  } catch (err) {
    logger.error('Health check failed', err);
    error(res, 'Health check failed', 500);
  }
};

export default withErrorHandling(
  withLogging(
    withCors(
      withMethods(['GET'], handler)
    )
  )
);

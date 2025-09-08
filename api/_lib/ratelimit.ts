// api/_lib/ratelimit.ts
import { VercelRequest, VercelResponse } from '@vercel/node';
import { logger } from './logger';

interface RateLimitConfig {
  windowMs: number;
  maxRequests: number;
  keyGenerator?: (req: VercelRequest) => string;
  skipSuccessfulRequests?: boolean;
  skipFailedRequests?: boolean;
  skip?: (req: VercelRequest) => boolean;
  standardHeaders?: boolean;
  legacyHeaders?: boolean;
  message?: string;
}

interface RateLimitStore {
  [key: string]: {
    count: number;
    resetTime: number;
    firstRequest: number;
  };
}

// Simple in-memory store (in production, use Redis or similar)
const store: RateLimitStore = {};

// Cleanup expired entries periodically
setInterval(() => {
  const now = Date.now();
  Object.keys(store).forEach(key => {
    if (store[key].resetTime < now) {
      delete store[key];
    }
  });
}, 60000); // Cleanup every minute

export function createRateLimit(config: RateLimitConfig) {
  const {
    windowMs = 15 * 60 * 1000, // 15 minutes
    maxRequests = 100,
    keyGenerator = (req) => {
      // Better key generation matching Express patterns
      return req.headers['x-forwarded-for'] as string || 
             req.headers['x-real-ip'] as string ||
             req.connection?.remoteAddress || 
             'unknown';
    },
    skipSuccessfulRequests = false,
    skipFailedRequests = false,
    skip = () => false,
    standardHeaders = true,
    legacyHeaders = false,
    message = 'Too many requests, please try again later.'
  } = config;

  return (req: VercelRequest, res: VercelResponse, next: () => void) => {
    // Skip rate limiting if configured
    if (skip(req)) {
      return next();
    }

    const key = keyGenerator(req);
    const now = Date.now();

    // Clean up expired entries for this specific key
    if (store[key] && store[key].resetTime < now) {
      delete store[key];
    }

    // Initialize or get current count
    if (!store[key]) {
      store[key] = { 
        count: 0, 
        resetTime: now + windowMs,
        firstRequest: now
      };
    }

    const entry = store[key];
    const isWithinWindow = (now - entry.firstRequest) < windowMs;

    // Reset if window has expired
    if (!isWithinWindow) {
      entry.count = 0;
      entry.resetTime = now + windowMs;
      entry.firstRequest = now;
    }

    // Check if limit exceeded
    if (entry.count >= maxRequests) {
      const timeUntilReset = Math.ceil((entry.resetTime - now) / 1000);
      
      // Set standard rate limit headers (like express-rate-limit)
      if (standardHeaders) {
        res.setHeader('RateLimit-Limit', maxRequests);
        res.setHeader('RateLimit-Remaining', 0);
        res.setHeader('RateLimit-Reset', new Date(entry.resetTime).toISOString());
      }

      // Set legacy headers for backwards compatibility
      if (legacyHeaders) {
        res.setHeader('X-RateLimit-Limit', maxRequests);
        res.setHeader('X-RateLimit-Remaining', 0);
        res.setHeader('X-RateLimit-Reset', timeUntilReset);
      }
      
      logger.warn('Rate limit exceeded', { 
        key, 
        count: entry.count, 
        limit: maxRequests,
        resetIn: timeUntilReset,
        route: req.url,
        method: req.method,
        userAgent: req.headers['user-agent']
      });
      
      res.status(429).json({
        error: true,
        message,
        retryAfter: timeUntilReset,
        limit: maxRequests,
        remaining: 0,
        reset: new Date(entry.resetTime).toISOString()
      });
      return;
    }

    // Increment counter (before processing request)
    entry.count++;

    // Track the response to potentially skip counting
    const originalSend = res.send;
    res.send = function(body) {
      const statusCode = res.statusCode;
      
      // Optionally skip counting based on response
      if ((skipSuccessfulRequests && statusCode < 400) ||
          (skipFailedRequests && statusCode >= 400)) {
        entry.count--; // Decrement since we don't want to count this
      }
      
      return originalSend.call(this, body);
    };

    // Set rate limit headers
    const remaining = Math.max(0, maxRequests - entry.count);
    const resetTime = new Date(entry.resetTime);
    
    if (standardHeaders) {
      res.setHeader('RateLimit-Limit', maxRequests);
      res.setHeader('RateLimit-Remaining', remaining);
      res.setHeader('RateLimit-Reset', resetTime.toISOString());
    }

    if (legacyHeaders) {
      res.setHeader('X-RateLimit-Limit', maxRequests);
      res.setHeader('X-RateLimit-Remaining', remaining);
      res.setHeader('X-RateLimit-Reset', Math.ceil((entry.resetTime - now) / 1000));
    }

    next();
  };
}

// Default rate limiters (matching JavaScript version patterns)
export const defaultRateLimit = createRateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  maxRequests: 100,
  message: 'Too many requests from this IP, please try again later.'
});

export const strictRateLimit = createRateLimit({
  windowMs: 60 * 1000, // 1 minute
  maxRequests: 10,
  message: 'Rate limit exceeded. Please slow down your requests.'
});

export const authRateLimit = createRateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  maxRequests: 5,
  keyGenerator: (req) => `auth:${req.headers['x-forwarded-for'] || req.connection?.remoteAddress || 'unknown'}`,
  message: 'Too many authentication attempts, please try again later.'
});

// API-specific rate limiters
export const apiRateLimit = createRateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  maxRequests: 1000, // Higher limit for API usage
  message: 'API rate limit exceeded. Please upgrade your plan for higher limits.',
  skipSuccessfulRequests: false,
  skipFailedRequests: true // Don't count failed requests against the limit
});

export const uploadRateLimit = createRateLimit({
  windowMs: 60 * 1000, // 1 minute
  maxRequests: 5, // Limited uploads per minute
  message: 'Upload rate limit exceeded. Please wait before uploading again.'
});

// Rate limiter for different user tiers
export function createTieredRateLimit(userTier: 'free' | 'premium' | 'enterprise' = 'free') {
  const limits = {
    free: { windowMs: 15 * 60 * 1000, maxRequests: 100 },
    premium: { windowMs: 15 * 60 * 1000, maxRequests: 1000 },
    enterprise: { windowMs: 15 * 60 * 1000, maxRequests: 10000 }
  };

  const config = limits[userTier];
  return createRateLimit({
    ...config,
    message: `${userTier} tier rate limit exceeded. Consider upgrading for higher limits.`,
    keyGenerator: (req) => {
      // Include user tier in the key for separate buckets
      const ip = req.headers['x-forwarded-for'] || req.connection?.remoteAddress || 'unknown';
      return `${userTier}:${ip}`;
    }
  });
}

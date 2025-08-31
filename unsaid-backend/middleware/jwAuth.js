/**
 * middleware/jwAuth.js
 *
 * Robust JWT auth for Express.
 * - RS256 via JWKS (Auth0/Okta) or HS256 shared secret
 * - Multiple issuers/audiences
 * - Scope/role checks (403 on insufficient permissions)
 * - Clock tolerance, maxAge, and KID rotation with caching
 * - Optional passthrough mode (required=false)
 *
 * Env tips:
 *   JWT_PUBLIC_KEY        // PEM for RS256 (if not using JWKS)
 *   JWT_SECRET            // shared secret for HS256 (alternative)
 *   JWT_AUDIENCE          // comma list or single
 *   JWT_ISSUER            // comma list or single
 *   JWKS_URI              // e.g., https://YOUR_DOMAIN/.well-known/jwks.json
 */

const jwt = require('jsonwebtoken');
const jwksRsa = require('jwks-rsa');
const logger = require('../config/logger');

function arr(v) {
  if (!v) return undefined;
  if (Array.isArray(v)) return v;
  return String(v).split(',').map(s => s.trim()).filter(Boolean);
}

module.exports = function jwAuth(options = {}) {
  const {
    // key sources
    secretOrPublicKey = process.env.JWT_PUBLIC_KEY || process.env.JWT_SECRET || null,
    algorithms = arr(process.env.JWT_ALGOS) || ['RS256'], // explicitly set to avoid alg confusion
    jwksUri = process.env.JWKS_URI, // when present, use JWKS auto-rotation

    // claims
    audience = arr(options.audience || process.env.JWT_AUDIENCE),
    issuer = arr(options.issuer || process.env.JWT_ISSUER),

    // behavior
    required = false,               // if true, 401 on any auth failure
    clockTolerance = Number(process.env.JWT_CLOCK_TOLERANCE || 60), // seconds
    maxAge = process.env.JWT_MAX_AGE,   // e.g., "1h"
    ignoreExpiration = false,

    // authorization helpers
    requireScopes = [],             // e.g., ['read:messages']
    scopesClaim = options.scopesClaim || 'scope', // can be 'scope' (string) or 'permissions' (array)
    requireRoles = [],              // e.g., ['admin']
    rolesClaim = options.rolesClaim || 'roles',

    // token sources
    tokenFrom = options.tokenFrom || ['header'], // 'header' | 'cookie' | 'query'
    cookieName = options.cookieName || 'token',
    queryName = options.queryName || 'token',

    // hook: async (decoded, req) => boolean
    isRevoked = null,               // return true to reject as revoked
  } = options;

  // JWKS client (if configured)
  const useJwks = Boolean(jwksUri);
  const jwksClient = useJwks
    ? jwksRsa({
        jwksUri,
        cache: true,
        cacheMaxEntries: 5,
        cacheMaxAge: 10 * 60 * 1000, // 10m
        rateLimit: true,
        jwksRequestsPerMinute: 10,
      })
    : null;

  if (!useJwks && !secretOrPublicKey) {
    logger.warn('jwAuth: No JWKS_URI or JWT key configured; running in passthrough mode.');
  }

  // Token extractors
  function extractToken(req) {
    let token;
    if (tokenFrom.includes('header')) {
      const h = req.headers.authorization;
      if (h && h.startsWith('Bearer ')) token = h.slice(7).trim();
    }
    if (!token && tokenFrom.includes('cookie')) {
      token = req.cookies?.[cookieName];
    }
    if (!token && tokenFrom.includes('query')) {
      token = req.query?.[queryName];
    }
    return token || null;
  }

  // For jsonwebtoken: dynamic key resolver when using JWKS
  const getKey = useJwks
    ? (header, cb) => {
        if (!header || !header.kid) return cb(new Error('No KID in token header'));
        jwksClient.getSigningKey(header.kid, (err, key) => {
          if (err) return cb(err);
          const signingKey = key.getPublicKey();
          cb(null, signingKey);
        });
      }
    : null;

  // Normalize scopes & roles
  function hasRequiredScopes(decoded) {
    if (!requireScopes.length) return true;
    let provided = [];
    const claim = decoded[scopesClaim];
    if (Array.isArray(claim)) provided = claim;
    else if (typeof claim === 'string') provided = claim.split(' ').filter(Boolean);
    return requireScopes.every(s => provided.includes(s));
    }
  function hasRequiredRoles(decoded) {
    if (!requireRoles.length) return true;
    const claimed = decoded[rolesClaim];
    const provided = Array.isArray(claimed) ? claimed : [];
    return requireRoles.every(r => provided.includes(r));
  }

  // Middleware fn
  return async (req, res, next) => {
    try {
      const token = extractToken(req);
      if (!token) {
        if (required) return res.status(401).json({ ok: false, error: 'Missing token' });
        return next();
      }

      // Build verify options
      const verifyOpts = {
        algorithms,
        audience,
        issuer,
        clockTolerance,
        ignoreExpiration,
      };
      if (maxAge) verifyOpts.maxAge = maxAge;

      // Verify token
      const onVerified = async (err, decoded) => {
        if (err) {
          if (required) return res.status(401).json({ ok: false, error: 'Invalid token' });
          return next();
        }

        // Optional revocation hook
        if (isRevoked && (await Promise.resolve(isRevoked(decoded, req)))) {
          if (required) return res.status(401).json({ ok: false, error: 'Token revoked' });
          return next();
        }

        // Authorization checks (403 if authenticated but lacks perms)
        if (!hasRequiredScopes(decoded)) {
          return res.status(403).json({ ok: false, error: 'Insufficient scope' });
        }
        if (!hasRequiredRoles(decoded)) {
          return res.status(403).json({ ok: false, error: 'Insufficient role' });
        }

        // Attach
        req.user = {
          id: decoded.sub || decoded.user_id || decoded.uid || 'unknown',
          ...decoded,
        };
        req.auth = { token, header: req.headers.authorization ? 'bearer' : (tokenFrom.includes('cookie') ? 'cookie' : 'query') };
        return next();
      };

      if (useJwks) {
        jwt.verify(token, getKey, verifyOpts, onVerified);
      } else {
        // Local key path: supports RS256 public key (PEM) or HS256 shared secret
        jwt.verify(token, secretOrPublicKey, verifyOpts, onVerified);
      }
    } catch (e) {
      logger.warn({ err: e?.message }, 'jwAuth middleware error');
      if (required) return res.status(401).json({ ok: false, error: 'Unauthorized' });
      return next();
    }
  };
};

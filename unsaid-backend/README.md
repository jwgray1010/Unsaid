# Unsaid API

Backend for **Unsaid** — an AI-powered communication & tone analysis service.  
Built with **Express.js**, deployed serverlessly on **Vercel**, with robust middleware and JSON-driven NLP knowledge bases.

---

## 🚀 Features

- **Express.js** API with modular middleware:
  - Structured logging (`pino`, `httpLogger`, `requestLogger`)
  - Secure JWT authentication (`jwtAuth`) with JWKS/HS256 support
  - IP/user rate limiting (`rateLimiter`) with optional Redis store
  - CORS with environment-based whitelist & regex support
  - Prometheus metrics endpoint (`/metrics`) with optional token protection
  - Centralized error handling (`errorHandler`)
- **Routes**
  - `GET /health/healthz` — liveness probe
  - `GET /health/readyz` — readiness probe
  - `GET /metrics` — Prometheus metrics
  - `GET /version` — service metadata
  - `POST /api/tone` — tone analysis
  - `POST /api/suggestions` — communication suggestions (premium gated)
- **Data-driven NLP** (see `/data/*.json`):
  - `tone_triggerwords.json`, `intensity_modifiers.json`, `context_classifier.json`, etc.
- **Jobs**
  - `jobs/migrate_profile.mjs` — schema migration for communicator profiles
  - `jobs/validate_data.mjs` — validates JSON files against schemas

---

## 📦 Project Structure
---

## ⚙️ Environment Variables

All variables are defined in [`.env.example`](./.env.example).  
Set them in **Vercel Dashboard → Project → Settings → Environment Variables**.

Key vars:
- `NODE_ENV`, `LOG_LEVEL`, `PRETTY_LOGS`
- `JWT_PUBLIC_KEY` / `JWT_SECRET`, `JWKS_URI`, `JWT_AUDIENCE`, `JWT_ISSUER`
- `CORS_ORIGINS`, `CORS_METHODS`, `CORS_HEADERS`
- `METRICS_ENABLED`, `METRICS_TOKEN`
- `RATE_LIMIT_WINDOW`, `RATE_LIMIT_MAX`, `REDIS_URL`

---

## 🛠 Development

> ⚠️ On Vercel, you don’t need a `server.js`. Locally you can run `server.js` if desired, but by default everything runs serverlessly via `api/index.js`.

### Run Data Validators & Migrations
```bash
npm run data:validate
npm run data:migrate:plan
npm run data:migrate -- --dry-run
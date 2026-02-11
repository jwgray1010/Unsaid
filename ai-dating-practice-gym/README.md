# AI Dating Practice Gym (MVP)

Production-ready MVP for realistic dating conversation practice with AI personas, post-date coaching, subscription billing, and safety guardrails.

## Stack

- Next.js (App Router) + TypeScript
- Tailwind CSS
- Supabase (Auth + Postgres + RLS)
- Stripe subscriptions
- OpenAI Chat Completions API

## Features Included

- Auth (email/password via Supabase)
- Required profile completion after login
- Persona and setting selection
- Pre-date tips from local rules
- Session chat simulation with transcript persistence
- End-date coaching report with strengths, improvements, and rewrites
- Billing gate with prototype toggle:
  - `BILLING_ENFORCED=false` (default) allows unlimited testing
  - `BILLING_ENFORCED=true` enforces free-tier + subscription gating
- Stripe checkout + webhook + billing portal
- Safety layer:
  - explicit-content boundary handling (PG-13 fade-to-black)
  - self-harm keyword detection + 988 support messaging
- RLS policies for user-scoped data access
- Basic in-memory API rate limiting

## Routes

- `/` Landing
- `/login` Auth
- `/app` Dashboard
- `/app/profile` Profile form
- `/app/personas` Persona picker
- `/app/settings` Setting picker
- `/app/tips` Pre-date tips
- `/app/session/[id]` Simulation chat
- `/app/session/[id]/coach` Coaching report
- `/app/billing` Upgrade / subscription management
- `/api/simulate` POST
- `/api/coach` POST
- `/api/stripe/checkout` POST
- `/api/stripe/webhook` POST
- `/api/stripe/portal` POST

## Local Setup

### 1) Install

```bash
npm install
```

### 2) Environment

Copy `.env.example` to `.env.local` and fill values:

```bash
cp .env.example .env.local
```

Required variables:

- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`
- `OPENAI_API_KEY`
- `STRIPE_SECRET_KEY`
- `STRIPE_WEBHOOK_SECRET`
- `NEXT_PUBLIC_STRIPE_PRICE_ID`
- `NEXT_PUBLIC_APP_URL` (local: `http://localhost:3000`)

Optional:

- `OPENAI_MODEL_SIMULATION` (default `gpt-4.1-mini`)
- `OPENAI_MODEL_COACHING` (default `gpt-4.1-mini`)
- `BILLING_ENFORCED` (default `false` for prototype testing)

### 3) Supabase setup

1. Create a Supabase project.
2. In SQL Editor, run:
   - `supabase/schema.sql`
   - `supabase/seed.sql`
3. In Authentication:
   - Enable Email + Password provider.
4. Copy project URL + anon key + service role key into `.env.local`.

### 4) Stripe setup

1. Create a recurring monthly Price in Stripe.
2. Put its id in `NEXT_PUBLIC_STRIPE_PRICE_ID`.
3. Run Stripe webhook forwarding locally:

```bash
stripe listen --forward-to localhost:3000/api/stripe/webhook
```

4. Copy webhook signing secret into `STRIPE_WEBHOOK_SECRET`.
5. In Stripe Dashboard, set Customer Portal configuration (or use defaults).

### 5) Run app

```bash
npm run dev
```

Open `http://localhost:3000`.

## Supabase SQL Files

- Schema + RLS policies: `supabase/schema.sql`
- Seed personas/settings: `supabase/seed.sql`

## Notes on Production Safety

- OpenAI and Stripe keys are server-only.
- All user-content tables have RLS enabled.
- API endpoints enforce auth and ownership checks.
- Chat and coaching endpoints have basic rate limiting.
- Safety response interrupts normal flow on self-harm keywords and surfaces 988 resources.

## Deploy (Vercel)

1. Import repo into Vercel.
2. Set all environment variables in Vercel project settings.
3. Deploy.
4. Configure Stripe webhook endpoint to:
   - `https://<your-domain>/api/stripe/webhook`

`vercel.json` includes a function setting for the webhook route.

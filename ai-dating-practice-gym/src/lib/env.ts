const requiredServerVars = [
  "OPENAI_API_KEY",
  "STRIPE_SECRET_KEY",
  "STRIPE_WEBHOOK_SECRET",
  "SUPABASE_SERVICE_ROLE_KEY",
] as const;

const requiredPublicVars = [
  "NEXT_PUBLIC_SUPABASE_URL",
  "NEXT_PUBLIC_SUPABASE_ANON_KEY",
  "NEXT_PUBLIC_STRIPE_PRICE_ID",
  "NEXT_PUBLIC_APP_URL",
] as const;

type ServerVar = (typeof requiredServerVars)[number];
type PublicVar = (typeof requiredPublicVars)[number];

export function getServerEnv(name: ServerVar): string {
  const value = process.env[name];
  if (!value) {
    throw new Error(`Missing required server env var: ${name}`);
  }
  return value;
}

export function getPublicEnv(name: PublicVar): string {
  const value = process.env[name];
  if (!value) {
    throw new Error(`Missing required public env var: ${name}`);
  }
  return value;
}

export function assertServerEnv(): void {
  for (const key of requiredServerVars) {
    getServerEnv(key);
  }
  for (const key of requiredPublicVars) {
    getPublicEnv(key);
  }
}

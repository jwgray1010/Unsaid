// api/_lib/env.ts
import { z } from 'zod';

const envSchema = z.object({
  NODE_ENV: z.string().trim().pipe(z.enum(['development', 'test', 'production'])).default('development'),
  
  // Firebase Configuration
  FIREBASE_PROJECT_ID: z.string().trim().min(1),
  FIREBASE_API_KEY: z.string().trim().min(1),
  FIREBASE_AUTH_DOMAIN: z.string().trim().min(1),
  FIREBASE_STORAGE_BUCKET: z.string().trim().min(1),
  FIREBASE_MESSAGING_SENDER_ID: z.string().trim().min(1),
  FIREBASE_APP_ID: z.string().trim().min(1),
  
  // OpenAI Configuration
  OPENAI_API_KEY: z.string().trim().min(1),
  
  // Security
  JWT_SECRET: z.string().trim().min(32).optional(),
  JWT_AUDIENCE: z.string().trim().optional(),
  JWT_ISSUER: z.string().trim().optional(),
  
  // CORS
  CORS_ORIGINS: z.string().trim().default('*'),
  
  // Rate Limiting
  RATE_LIMIT_WINDOW: z.coerce.number().default(900000), // 15 minutes
  RATE_LIMIT_MAX: z.coerce.number().default(100),
  
  // Features
  ENABLED_FEATURES: z.string().trim().default('tone,suggestions,advice'),
  
  // Logging
  LOG_LEVEL: z.string().trim().pipe(z.enum(['trace', 'debug', 'info', 'warn', 'error', 'fatal'])).default('info'),
});

export type Env = z.infer<typeof envSchema>;

let cachedEnv: Env | null = null;

export function getEnv(): Env {
  if (cachedEnv) return cachedEnv;
  
  try {
    cachedEnv = envSchema.parse(process.env);
    return cachedEnv;
  } catch (error) {
    console.error('Environment validation failed:', error);
    throw new Error('Invalid environment configuration');
  }
}

export const env = getEnv();

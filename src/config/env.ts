import { z } from 'zod';

/**
 * Environment variable validation schema
 * Validates all required environment variables at startup
 */
const envSchema = z.object({
  // Node Environment
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),

  // Application URLs
  NEXT_PUBLIC_APP_URL: z.string().url().min(1),

  // Database
  DATABASE_URL: z.string().min(1),
  DIRECT_URL: z.string().min(1),

  // Authentication
  AUTH_SECRET: z.string().min(32, 'AUTH_SECRET must be at least 32 characters'),

  // Supabase
  NEXT_PUBLIC_SUPABASE_URL: z.string().url().min(1),
  NEXT_PUBLIC_SUPABASE_ANON_KEY: z.string().min(1),
  SUPABASE_SERVICE_ROLE_KEY: z.string().min(1),

  // Storage
  PRODUCT_IMAGE_BUCKET: z.string().default('products'),

  // Payment
  PAYMENT_PROVIDER: z.string().default('manual_vietqr'),
  PAYMENT_WEBHOOK_SECRET: z.string().optional(),

  // Store Configuration
  STORE_NAME: z.string().default('Nhiên'),
  STORE_CURRENCY: z.string().default('VND'),
  STORE_BANK_NAME: z.string().optional(),
  STORE_BANK_ACCOUNT_NUMBER: z.string().optional(),
  STORE_BANK_ACCOUNT_HOLDER: z.string().optional(),
});

/**
 * Parse and validate environment variables
 * Throws an error if validation fails
 */
function validateEnv() {
  try {
    const parsed = envSchema.parse({
      NODE_ENV: process.env.NODE_ENV,
      NEXT_PUBLIC_APP_URL: process.env.NEXT_PUBLIC_APP_URL,
      DATABASE_URL: process.env.DATABASE_URL,
      DIRECT_URL: process.env.DIRECT_URL,
      AUTH_SECRET: process.env.AUTH_SECRET,
      NEXT_PUBLIC_SUPABASE_URL: process.env.NEXT_PUBLIC_SUPABASE_URL,
      NEXT_PUBLIC_SUPABASE_ANON_KEY: process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY,
      SUPABASE_SERVICE_ROLE_KEY: process.env.SUPABASE_SERVICE_ROLE_KEY,
      PRODUCT_IMAGE_BUCKET: process.env.PRODUCT_IMAGE_BUCKET,
      PAYMENT_PROVIDER: process.env.PAYMENT_PROVIDER,
      PAYMENT_WEBHOOK_SECRET: process.env.PAYMENT_WEBHOOK_SECRET,
      STORE_NAME: process.env.STORE_NAME,
      STORE_CURRENCY: process.env.STORE_CURRENCY,
      STORE_BANK_NAME: process.env.STORE_BANK_NAME,
      STORE_BANK_ACCOUNT_NUMBER: process.env.STORE_BANK_ACCOUNT_NUMBER,
      STORE_BANK_ACCOUNT_HOLDER: process.env.STORE_BANK_ACCOUNT_HOLDER,
    });

    return parsed;
  } catch (error) {
    if (error instanceof z.ZodError) {
      const missingVars = error.issues.map((issue) => `  - ${issue.path.join('.')}: ${issue.message}`);
      throw new Error(
        `❌ Invalid environment variables:\n${missingVars.join('\n')}\n\nPlease check your .env.local file.`
      );
    }
    throw error;
  }
}

/**
 * Validated environment variables
 * Use this export instead of process.env for type safety
 */
export const env = validateEnv();

/**
 * Type-safe environment variables
 */
export type Env = z.infer<typeof envSchema>;

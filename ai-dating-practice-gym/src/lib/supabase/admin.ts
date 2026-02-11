import { createClient } from "@supabase/supabase-js";

import { getPublicEnv, getServerEnv } from "@/lib/env";

export function createSupabaseAdminClient() {
  return createClient(
    getPublicEnv("NEXT_PUBLIC_SUPABASE_URL"),
    getServerEnv("SUPABASE_SERVICE_ROLE_KEY"),
    {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    },
  );
}

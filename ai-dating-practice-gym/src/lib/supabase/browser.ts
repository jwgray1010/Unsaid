"use client";

import { createBrowserClient } from "@supabase/ssr";

import { getPublicEnv } from "@/lib/env";

export function createSupabaseBrowserClient() {
  return createBrowserClient(
    getPublicEnv("NEXT_PUBLIC_SUPABASE_URL"),
    getPublicEnv("NEXT_PUBLIC_SUPABASE_ANON_KEY"),
  );
}

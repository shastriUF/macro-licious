import { createClient, type SupabaseClient } from '@supabase/supabase-js';

import { env } from '../config/env';

let cachedPublicClient: SupabaseClient | null = null;
let cachedAdminClient: SupabaseClient | null = null;

export function getSupabasePublicClient(): SupabaseClient {
  if (!env.SUPABASE_URL || !env.SUPABASE_PUBLISHABLE_KEY) {
    throw new Error('Supabase public client is not configured. Set SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY.');
  }

  if (!cachedPublicClient) {
    cachedPublicClient = createClient(env.SUPABASE_URL, env.SUPABASE_PUBLISHABLE_KEY, {
      auth: {
        autoRefreshToken: false,
        persistSession: false
      }
    });
  }

  return cachedPublicClient;
}

export function getSupabaseAdminClient(): SupabaseClient {
  if (!env.SUPABASE_URL || !env.SUPABASE_SECRET_KEY) {
    throw new Error('Supabase admin client is not configured. Set SUPABASE_URL and SUPABASE_SECRET_KEY.');
  }

  if (!cachedAdminClient) {
    cachedAdminClient = createClient(env.SUPABASE_URL, env.SUPABASE_SECRET_KEY, {
      auth: {
        autoRefreshToken: false,
        persistSession: false
      }
    });
  }

  return cachedAdminClient;
}

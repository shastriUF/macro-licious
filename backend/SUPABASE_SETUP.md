# Supabase Setup Guide (Staged Auth + Backend DB)

This guide configures Supabase for MacroLicious in a staged way:
- keep current dev auth flow working (`AUTH_PROVIDER=dev`),
- enable real provider auth when ready (`AUTH_PROVIDER=supabase`),
- prepare database schema for profile + ingredients persistence.

## 1) Create Supabase project
1. Go to https://supabase.com and create a new project.
2. Save:
   - `Project URL`
  - `Publishable key`
  - `Secret key`

## 2) Configure Auth (magic links)
In Supabase dashboard:
1. `Authentication` -> `Providers` -> `Email`
2. Enable email provider and magic link flow.
3. Set `Site URL` to your app/web callback root (for staging, can be temporary).
4. Add Redirect URL(s) used during sign-in (example placeholders):
   - `macrolicious://auth/callback`
   - `https://your-staging-domain.example.com/auth/callback`

## 3) Add backend environment values
In `backend/.env`:

```dotenv
AUTH_PROVIDER=supabase
SUPABASE_URL=https://<your-project-ref>.supabase.co
SUPABASE_PUBLISHABLE_KEY=<your-publishable-key>
SUPABASE_SECRET_KEY=<your-secret-key>
SUPABASE_EMAIL_REDIRECT_URL=macrolicious://auth/callback
```

For local dev fallback, switch back to:

```dotenv
AUTH_PROVIDER=dev
```

## 4) Apply database schema (prepared for backend persistence)
Open Supabase SQL Editor and run:

```sql
create table if not exists public.user_profiles (
  id uuid primary key default gen_random_uuid(),
  email text unique not null,
  calories_target numeric not null default 2000,
  carbs_target numeric not null default 250,
  protein_target numeric not null default 120,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.ingredients (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.user_profiles(id) on delete cascade,
  name text not null,
  brand text,
  barcode text,
  calories_per_100g numeric not null,
  carbs_per_100g numeric not null,
  protein_per_100g numeric not null,
  fat_per_100g numeric not null,
  archived boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists ingredients_user_id_idx on public.ingredients(user_id);
create index if not exists ingredients_barcode_idx on public.ingredients(barcode);
```

## 5) Staged auth behavior in current backend
Current implementation supports two auth modes:

- `AUTH_PROVIDER=dev`
  - `/auth/magic-link/request` returns a dev token directly
  - `/auth/magic-link/verify` consumes that single-use token

- `AUTH_PROVIDER=supabase`
  - `/auth/magic-link/request` triggers Supabase magic-link email
  - `/auth/magic-link/verify` currently expects a Supabase access token in the `token` field, then issues backend session token

This is intentional staging so you can migrate safely without breaking current local testing.

## 6) Production hardening checklist (next step)
- Move backend persistence from in-memory stores to Supabase Postgres tables
- Replace token-paste staged verify with full deep-link callback exchange in iOS
- Add Row Level Security policies and service-role boundary checks
- Add provider-specific audit logging for auth events
- Rotate all secrets and set environment values in Render dashboard

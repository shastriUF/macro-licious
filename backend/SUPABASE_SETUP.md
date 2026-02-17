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

## 4) Apply schema using a versioned migration flow (recommended)

Use the migration in source control instead of ad-hoc SQL edits:
- `supabase/migrations/202602160001_initial_schema.sql`

### Option A (Supabase CLI, recommended)
1. Install CLI (one-time):
   - `brew install supabase/tap/supabase`
2. From repo root:
   - `supabase link --project-ref <your-project-ref>`
   - `supabase db push`

This applies all migration files in `supabase/migrations` in order.

### Option B (Dashboard SQL Editor, fallback)
If you do not want to install CLI yet, open the migration file and run it manually in SQL Editor.

Future schema changes:
1. Add a new migration file in `supabase/migrations` (timestamped filename)
2. Commit it
3. Apply with `supabase db push`

Do not edit production schema manually without a migration file.

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

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

create table if not exists public.meal_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.user_profiles(id) on delete cascade,
  log_date date not null,
  meal_type text not null check (meal_type in ('breakfast', 'lunch', 'dinner', 'snack')),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.meal_log_items (
  id uuid primary key default gen_random_uuid(),
  meal_log_id uuid not null references public.meal_logs(id) on delete cascade,
  ingredient_id uuid references public.ingredients(id) on delete set null,
  ingredient_name text not null,
  quantity_value numeric not null,
  quantity_unit text not null check (quantity_unit in ('g', 'oz', 'lb', 'ml', 'tsp', 'tbsp', 'cup')),
  consumed_grams numeric not null,
  calories numeric not null,
  carbs numeric not null,
  protein numeric not null,
  fat numeric not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists meal_logs_user_date_idx on public.meal_logs(user_id, log_date);
create index if not exists meal_log_items_meal_log_id_idx on public.meal_log_items(meal_log_id);

alter table public.meal_logs enable row level security;
alter table public.meal_log_items enable row level security;

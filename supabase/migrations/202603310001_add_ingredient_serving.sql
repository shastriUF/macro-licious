-- Add serving size (grams per count unit) and default quantity unit to ingredients.
alter table public.ingredients
  add column if not exists serving_size_grams numeric,
  add column if not exists default_quantity_unit text;

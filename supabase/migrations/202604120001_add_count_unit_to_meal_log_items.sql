-- Add 'count' to the quantity_unit check constraint on meal_log_items.
-- The count unit was introduced in e3a2584 but the DB constraint was not updated.

alter table public.meal_log_items
  drop constraint if exists meal_log_items_quantity_unit_check;

alter table public.meal_log_items
  add constraint meal_log_items_quantity_unit_check
  check (quantity_unit in ('g', 'oz', 'lb', 'ml', 'tsp', 'tbsp', 'cup', 'count'));

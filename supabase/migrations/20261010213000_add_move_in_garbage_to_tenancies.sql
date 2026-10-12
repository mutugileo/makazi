-- Move-in garbage fee override on a tenancy.
-- When a new tenant is onboarded, the admin can specify an initial garbage fee
-- (e.g. 0 if garbage collection has not started yet or starts on the next billing cycle).
-- When null, billing engines fallback to the property's standard monthly garbage rate.

alter table public.tenancies
  add column if not exists move_in_garbage integer check (move_in_garbage is null or move_in_garbage >= 0);

-- Who is coming to fix a repair, and when. Staff fill these in when they
-- assign a ticket; the tenant sees them inside the request in the app.
--   assigned_to     (existing) the fundi's or staff member's name
--   assigned_phone  their mobile, +2547XXXXXXXX / +2541XXXXXXXX
--   visit_at        when they're expected (optional)

alter table public.repair_tickets
  add column if not exists assigned_phone text
    check (assigned_phone ~ '^\+254[17]\d{8}$'),
  add column if not exists visit_at timestamptz;

-- Staff set them through the existing update policies (admin for the whole
-- company, caretakers for their properties). Tenants can't: there is no
-- insert grant on these columns, and tenants have no update policy.
grant update (assigned_phone, visit_at) on public.repair_tickets to authenticated;

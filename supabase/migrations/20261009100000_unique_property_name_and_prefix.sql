-- A company cannot have two properties with the same name (ignoring case) or
-- the same paybill account prefix. The admin checks this before saving; these
-- indexes are the guard that holds even when two saves race.
--
-- Checked against the live database before writing this: no company has
-- duplicates today, so the indexes can be created without changing data.

create unique index if not exists properties_company_name_key
  on public.properties (company_id, lower(name));

create unique index if not exists properties_company_prefix_key
  on public.properties (company_id, upper(account_prefix));

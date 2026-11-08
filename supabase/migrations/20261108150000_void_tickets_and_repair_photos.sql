-- 1. Allow 'voided' in repair_tickets status check constraint
alter table public.repair_tickets drop constraint if exists repair_tickets_status_check;
alter table public.repair_tickets add constraint repair_tickets_status_check
  check (status in ('open', 'in_progress', 'resolved', 'voided'));

-- 2. Add photo_url column to repair_tickets
alter table public.repair_tickets add column if not exists photo_url text;
grant insert (photo_url), update (photo_url) on public.repair_tickets to authenticated;

-- 3. Tenant can update photo_url on their own active tickets
drop policy if exists repair_tickets_tenant_update_photo on public.repair_tickets;
create policy repair_tickets_tenant_update_photo on public.repair_tickets for update to authenticated
  using (tenancy_id in (select app.tenant_current_tenancy_ids()))
  with check (tenancy_id in (select app.tenant_current_tenancy_ids()));

-- 4. Storage configuration & RLS for repair-photos
insert into storage.buckets (id, name, public)
values ('repair-photos', 'repair-photos', true)
on conflict (id) do update set public = true;

drop policy if exists "Authenticated users can upload repair photos" on storage.objects;
create policy "Authenticated users can upload repair photos"
on storage.objects for insert to authenticated
with check (bucket_id = 'repair-photos');

drop policy if exists "Authenticated users can update repair photos" on storage.objects;
create policy "Authenticated users can update repair photos"
on storage.objects for update to authenticated
with check (bucket_id = 'repair-photos');

drop policy if exists "Public can view repair photos" on storage.objects;
create policy "Public can view repair photos"
on storage.objects for select to public
using (bucket_id = 'repair-photos');


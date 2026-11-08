-- Ensure repair-photos bucket is public and properly configured
insert into storage.buckets (id, name, public)
values ('repair-photos', 'repair-photos', true)
on conflict (id) do update set public = true;

-- Storage policies for repair-photos
drop policy if exists "Scoped repair photo uploads" on storage.objects;
drop policy if exists "Authenticated users can upload repair photos" on storage.objects;
drop policy if exists "Authenticated users can update repair photos" on storage.objects;
drop policy if exists "Public can view repair photos" on storage.objects;

create policy "Authenticated users can upload repair photos"
on storage.objects for insert to authenticated
with check (bucket_id = 'repair-photos');

create policy "Authenticated users can update repair photos"
on storage.objects for update to authenticated
with check (bucket_id = 'repair-photos');

create policy "Public can view repair photos"
on storage.objects for select to public
using (bucket_id = 'repair-photos');

-- Allow authenticated users (tenants and staff) to set photo_url and has_photo
grant insert (photo_url), update (photo_url, has_photo) on public.repair_tickets to authenticated;

drop policy if exists repair_tickets_tenant_update_photo on public.repair_tickets;
create policy repair_tickets_tenant_update_photo on public.repair_tickets for update to authenticated
  using (
    tenancy_id in (select app.tenant_current_tenancy_ids())
    or company_id in (select app.admin_company_ids())
  )
  with check (
    tenancy_id in (select app.tenant_current_tenancy_ids())
    or company_id in (select app.admin_company_ids())
  );

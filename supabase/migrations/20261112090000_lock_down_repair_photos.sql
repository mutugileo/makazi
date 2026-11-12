-- 20261108163000 opened repair photos to every signed-in user: any tenant of
-- any landlord could upload or overwrite anywhere in the bucket, and set a
-- ticket's photo_url to any link. Released apps upload with upsert and write
-- photo_url directly, so both paths stay, scoped:

-- Uploads and overwrites only under <company>/<tenancy>/... for the uploader's
-- own current tenancy, or under their own company for staff.
drop policy if exists "Authenticated users can upload repair photos" on storage.objects;
drop policy if exists "Authenticated users can update repair photos" on storage.objects;
drop policy if exists "Scoped repair photo uploads" on storage.objects;

create or replace function app.can_write_repair_photo(p_name text)
returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.tenancies t
    where t.id = (storage.foldername(p_name))[2]
      and t.company_id = (storage.foldername(p_name))[1]
      and t.id in (select app.tenant_current_tenancy_ids())
  )
  or (storage.foldername(p_name))[1] in (select app.admin_company_ids());
$$;
revoke all on function app.can_write_repair_photo(text) from public;
grant execute on function app.can_write_repair_photo(text) to authenticated;

create policy "Scoped repair photo uploads"
on storage.objects for insert to authenticated
with check (bucket_id = 'repair-photos' and app.can_write_repair_photo(name));

create policy "Scoped repair photo overwrites"
on storage.objects for update to authenticated
using (bucket_id = 'repair-photos' and app.can_write_repair_photo(name))
with check (bucket_id = 'repair-photos' and app.can_write_repair_photo(name));

-- photo_url may only be this ticket's own photo in the bucket: the storage
-- path, or its public URL. Never a link somewhere else.
alter table public.repair_tickets
  add constraint repair_tickets_photo_url_own check (
    photo_url is null
    or photo_url ~ (
      '^(https://gdapdyvgppatnjksbdco\.supabase\.co/storage/v1/object/public/repair-photos/)?'
      || company_id || '/' || tenancy_id || '/' || id || '\.[A-Za-z0-9]{1,5}$'
    )
  );

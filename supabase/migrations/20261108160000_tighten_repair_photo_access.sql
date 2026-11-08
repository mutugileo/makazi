-- The broad tenant UPDATE policy let tenants touch status/assignee/notes on
-- their tickets. Replace it with an RPC that only records the photo path.
drop policy if exists repair_tickets_tenant_update_photo on public.repair_tickets;
revoke update (photo_url) on public.repair_tickets from authenticated;
revoke insert (photo_url) on public.repair_tickets from authenticated;

-- photo_url holds a storage path inside the repair-photos bucket:
-- <company_id>/<tenancy_id>/<ticket_id>.<ext>. Never a free-form URL.
create or replace function public.set_repair_ticket_photo(p_ticket_id text, p_path text)
returns void
language plpgsql security definer set search_path = '' as $$
declare
  t record;
begin
  select company_id, tenancy_id into t
  from public.repair_tickets
  where id = p_ticket_id
    and tenancy_id in (select app.tenant_current_tenancy_ids());
  if not found then
    raise exception 'Ticket not found' using errcode = '42501';
  end if;
  if p_path !~ ('^' || t.company_id || '/' || t.tenancy_id || '/' || p_ticket_id || '\.[A-Za-z0-9]{1,5}$') then
    raise exception 'Invalid photo path' using errcode = '22023';
  end if;
  update public.repair_tickets
     set photo_url = p_path, has_photo = true
   where company_id = t.company_id and id = p_ticket_id;
end $$;
revoke all on function public.set_repair_ticket_photo(text, text) from public;
grant execute on function public.set_repair_ticket_photo(text, text) to authenticated;

-- Uploads only into the uploader's own tenancy folder (tenants) or company folder (staff).
drop policy if exists "Authenticated users can upload repair photos" on storage.objects;
drop policy if exists "Authenticated users can update repair photos" on storage.objects;
create policy "Scoped repair photo uploads"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'repair-photos'
  and (
    (storage.foldername(name))[2] in (select x::text from app.tenant_current_tenancy_ids() x)
    or (storage.foldername(name))[1] in (select y::text from app.admin_company_ids() y)
  )
);


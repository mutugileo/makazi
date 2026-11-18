-- Harden RLS on repair_tickets, lock down repair-photos bucket to private,
-- revoke anon execute on set_repair_ticket_photo and trigger functions.

-- 1. Remove broad tenant UPDATE policy and direct photo_url/has_photo column writes.
drop policy if exists repair_tickets_tenant_update_photo on public.repair_tickets;
revoke update (photo_url, has_photo) on public.repair_tickets from authenticated;
revoke insert (photo_url) on public.repair_tickets from authenticated;

-- 2. Harden app.guard_ticket_update() so tenants cannot update repair_tickets directly,
--    while caretakers can only update status/assignment/resolution fields.
create or replace function app.guard_ticket_update() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if auth.uid() is not null
     and new.company_id not in (select app.admin_company_ids()) then
    if new.property_id not in (select app.caretaker_property_ids()) then
      raise exception 'Only staff can update repair tickets' using errcode = '42501';
    end if;
    if (new.category, new.priority, new.title, new.description, new.has_photo, new.photo_url)
        is distinct from (old.category, old.priority, old.title, old.description, old.has_photo, old.photo_url) then
      raise exception 'Only a manager can change the request itself' using errcode = '42501';
    end if;
  end if;
  return new;
end $$;

-- 3. Revoke anon execute on set_repair_ticket_photo and trigger functions.
revoke all on function public.set_repair_ticket_photo(text, text) from public, anon;
grant execute on function public.set_repair_ticket_photo(text, text) to authenticated;

revoke all on function app.fill_receipt_number() from public, anon, authenticated;
revoke all on function app.fill_ticket() from public, anon, authenticated;
revoke all on function app.guard_ticket_update() from public, anon, authenticated;
revoke all on function app.stamp_message() from public, anon, authenticated;

-- 4. Make repair-photos bucket private and restrict reads to the ticket's tenancy or company staff.
update storage.buckets
set public = false,
    file_size_limit = 5242880,
    allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp', 'image/heic']
where id = 'repair-photos';

drop policy if exists "Public can view repair photos" on storage.objects;
drop policy if exists "Scoped repair photo reads" on storage.objects;

create policy "Scoped repair photo reads"
on storage.objects for select to authenticated
using (
  bucket_id = 'repair-photos'
  and (
    (storage.foldername(name))[2] in (select x::text from app.tenant_tenancy_ids() x)
    or (storage.foldername(name))[1] in (select y::text from app.admin_company_ids() y)
  )
);

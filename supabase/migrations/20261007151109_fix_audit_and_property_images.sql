-- Fix app.audit() trigger so updating tenancies does not error on new.phone
create or replace function app.audit() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if tg_table_name = 'tenants' then
    if new.phone is distinct from old.phone then
      insert into public.audit_log (company_id, actor, action, target, detail)
      values (new.company_id, auth.uid(), 'phone_changed', new.id, jsonb_build_object('from', old.phone, 'to', new.phone));
    end if;
  elsif tg_table_name = 'tenancies' then
    if new.move_out is distinct from old.move_out then
      insert into public.audit_log (company_id, actor, action, target, detail)
      values (new.company_id, auth.uid(), 'move_out', new.id, jsonb_build_object('from', old.move_out, 'to', new.move_out));
    end if;
    if new.deposit_refund is distinct from old.deposit_refund then
      insert into public.audit_log (company_id, actor, action, target, detail)
      values (new.company_id, auth.uid(), 'deposit_refund', new.id, coalesce(new.deposit_refund, '{}'));
    end if;
    if new.opening_balance is distinct from old.opening_balance then
      insert into public.audit_log (company_id, actor, action, target, detail)
      values (new.company_id, auth.uid(), 'balance_corrected', new.id,
              jsonb_build_object('from', old.opening_balance, 'to', new.opening_balance));
    end if;
  end if;
  return new;
end $$;

-- Add image_url to properties
alter table public.properties add column if not exists image_url text;

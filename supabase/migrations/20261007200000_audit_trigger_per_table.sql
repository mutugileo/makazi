-- One audit trigger function per table.
--
-- app.audit() was shared by tenants and tenancies and read new.phone, which
-- tenancies don't have, so every move-out failed with
--   record "new" has no field "phone".
-- 20261007151109 nested the checks; this replaces the shared function with
-- one per table so no column of one table is ever read on the other.

create or replace function app.audit_tenants() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if new.phone is distinct from old.phone then
    insert into public.audit_log (company_id, actor, action, target, detail)
    values (new.company_id, auth.uid(), 'phone_changed', new.id,
            jsonb_build_object('from', old.phone, 'to', new.phone));
  end if;
  return new;
end $$;

create or replace function app.audit_tenancies() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if new.move_out is distinct from old.move_out then
    insert into public.audit_log (company_id, actor, action, target, detail)
    values (new.company_id, auth.uid(), 'move_out', new.id,
            jsonb_build_object('from', old.move_out, 'to', new.move_out));
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
  return new;
end $$;

revoke all on function app.audit_tenants() from public;
revoke all on function app.audit_tenancies() from public;

drop trigger if exists tenants_audit on public.tenants;
drop trigger if exists tenancies_audit on public.tenancies;
create trigger tenants_audit after update on public.tenants
  for each row execute function app.audit_tenants();
create trigger tenancies_audit after update on public.tenancies
  for each row execute function app.audit_tenancies();

drop function if exists app.audit();

-- Disable password_pending lockout for PIN-based logins so tenants can access their home
delete from app.pending_passwords;

create or replace function app.password_pending() returns boolean
language sql stable security definer set search_path = '' as $$
  select false;
$$;

create or replace function public.account_status() returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object(
    'mustChangePassword', false,
    'oneTimePasswordExpired', false
  );
$$;

create or replace function public.complete_password_change() returns boolean
language plpgsql security definer set search_path = '' as $$
declare
  cleared boolean;
  v_company_id text;
  v_phone text;
  v_tenant_name text;
begin
  delete from app.pending_passwords where user_id = auth.uid()
  returning true into cleared;

  select company_id, phone, name into v_company_id, v_phone, v_tenant_name
  from public.tenants
  where auth_user_id = auth.uid()
  limit 1;

  insert into public.audit_log (
    company_id,
    action,
    target,
    actor,
    detail,
    at
  ) values (
    coalesce(v_company_id, (select raw_user_meta_data->>'company_id' from auth.users where id = auth.uid()), 'unknown'),
    'password_activated',
    coalesce(v_phone, auth.uid()::text),
    auth.uid(),
    jsonb_build_object(
      'name', coalesce(v_tenant_name, 'Tenant'),
      'event', 'PIN set/changed; account active.'
    ),
    now()
  );

  return true;
end $$;

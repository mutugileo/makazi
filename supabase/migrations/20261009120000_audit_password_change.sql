-- Log password activation to public.audit_log when complete_password_change clears the gate.
create or replace function public.complete_password_change() returns boolean
language plpgsql security definer set search_path = '' as $$
declare
  cleared boolean;
  v_company_id text;
  v_phone text;
  v_tenant_name text;
begin
  delete from app.pending_passwords p
   using auth.users u
   where p.user_id = auth.uid() and u.id = p.user_id
     and u.encrypted_password is distinct from p.password_hash
     and p.expires_at >= now()
  returning true into cleared;

  if coalesce(cleared, false) then
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
        'event', 'Temporary password replaced with permanent password; account gate unlocked.'
      ),
      now()
    );
  end if;

  return coalesce(cleared, false);
end $$;

revoke all on function public.complete_password_change() from public, anon;
grant execute on function public.complete_password_change() to authenticated;

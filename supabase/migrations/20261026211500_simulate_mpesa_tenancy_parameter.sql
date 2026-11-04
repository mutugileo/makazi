-- Support specifying tenancy_id in simulate_mpesa_payment so tenants with multiple
-- units or leases have their payments credited to the tenancy being viewed,
-- rather than arbitrarily picking a tenancy via move_in desc limit 1.

drop function if exists public.simulate_mpesa_payment(integer);

create or replace function public.simulate_mpesa_payment(
  p_amount integer,
  p_tenancy_id text default null
) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_tenancy public.tenancies%rowtype;
  v_enabled boolean;
  v_now timestamp := now() at time zone 'Africa/Nairobi';
  v_reference text := 'SIM' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 7));
  v_receipt text;
begin
  if p_amount is null or p_amount < 1 or p_amount > 250000 then
    raise exception 'Amount must be between KES 1 and KES 250,000' using errcode = '22023';
  end if;

  if p_tenancy_id is not null and p_tenancy_id <> '' then
    select t.* into v_tenancy
    from public.tenancies t
    where t.id = p_tenancy_id and t.id in (select app.tenant_current_tenancy_ids())
    limit 1;
    if v_tenancy.id is null then
      raise exception 'Specified tenancy is not active for this account' using errcode = '42501';
    end if;
  else
    select t.* into v_tenancy
    from public.tenancies t
    where t.id in (select app.tenant_current_tenancy_ids())
    order by t.move_in desc
    limit 1;
    if v_tenancy.id is null then
      raise exception 'No current tenancy for this account' using errcode = '42501';
    end if;
  end if;

  select coalesce((c.settings ->> 'mpesaSimulation')::boolean, false) into v_enabled
  from public.companies c where c.id = v_tenancy.company_id;
  if not v_enabled then
    raise exception 'M-Pesa test mode is off' using errcode = '42501';
  end if;

  if (select count(*) from public.payments p
      where p.tenancy_id = v_tenancy.id and p.simulated and p.created_at > now() - interval '1 day') >= 10 then
    raise exception 'Too many test payments today' using errcode = '54000';
  end if;

  insert into public.payments (company_id, tenancy_id, amount, date, time, method, reference, simulated)
  values (v_tenancy.company_id, v_tenancy.id, p_amount, v_now::date, to_char(v_now, 'HH24:MI'), 'M-Pesa', v_reference, true)
  returning receipt_number into v_receipt;

  return jsonb_build_object(
    'receiptNumber', v_receipt,
    'reference', v_reference,
    'tenancyId', v_tenancy.id,
    'amount', p_amount,
    'date', v_now::date,
    'time', to_char(v_now, 'HH24:MI')
  );
end $$;

revoke all on function public.simulate_mpesa_payment(integer, text) from public, anon;
grant execute on function public.simulate_mpesa_payment(integer, text) to authenticated;

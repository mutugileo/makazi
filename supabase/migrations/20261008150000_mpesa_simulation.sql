-- M-Pesa test mode: until Daraja (real STK push) is connected, a company can
-- let its tenants run a simulated STK push from the app that records a real
-- payment row, flagged as simulated, so balances, receipts and reports can
-- be tried end to end.
--
-- Safety:
--   * Off unless the company turns it on (companies.settings.mpesaSimulation).
--   * Tenants still can't insert payments. Only this function writes them,
--     only for the caller's own current tenancy, only within M-Pesa limits.
--   * Every row is flagged simulated = true and its reference starts "SIM",
--     so the admin and the app label it, and it can be found and removed.
--   * At most 10 simulated payments per tenancy per day.

alter table public.payments
  add column if not exists simulated boolean not null default false;

create function public.simulate_mpesa_payment(p_amount integer) returns jsonb
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

  select t.* into v_tenancy
  from public.tenancies t
  where t.id in (select app.tenant_current_tenancy_ids())
  order by t.move_in desc
  limit 1;
  if v_tenancy.id is null then
    raise exception 'No current tenancy for this account' using errcode = '42501';
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

revoke all on function public.simulate_mpesa_payment(integer) from public, anon;
grant execute on function public.simulate_mpesa_payment(integer) to authenticated;

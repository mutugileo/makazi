-- Reject non-payment messages in submit_payment_claim by requiring both a
-- parsed transaction reference and a parsed amount.
create or replace function public.submit_payment_claim(p_tenancy_id text, p_message text)
returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_message text := trim(coalesce(p_message, ''));
  v_tenancy public.tenancies%rowtype;
  v_parsed record;
  v_claim public.payment_claims%rowtype;
begin
  if char_length(v_message) < 20 then
    raise exception 'Paste the whole confirmation message' using errcode = '22023';
  end if;
  if char_length(v_message) > 1000 then
    raise exception 'That message is too long. Paste only the confirmation message.' using errcode = '22023';
  end if;

  select t.* into v_tenancy
  from public.tenancies t
  where t.id = p_tenancy_id and t.id in (select app.tenant_current_tenancy_ids());
  if v_tenancy.id is null then
    raise exception 'No current tenancy for this account' using errcode = '42501';
  end if;

  if (select count(*) from public.payment_claims c
      where c.tenancy_id = v_tenancy.id and c.created_at > now() - interval '1 day') >= 10 then
    raise exception 'Too many payment messages today. Try again tomorrow.' using errcode = '54000';
  end if;

  select * into v_parsed from app.parse_payment_message(v_message);

  if v_parsed.reference is null or v_parsed.amount is null then
    raise exception 'Paste the full M-Pesa or bank confirmation message, including the reference and amount.' using errcode = '22023';
  end if;

  if exists (select 1 from public.payments p
             where p.company_id = v_tenancy.company_id and upper(p.reference) = v_parsed.reference) then
    raise exception 'This payment is already recorded' using errcode = '23505';
  end if;

  begin
    insert into public.payment_claims
      (company_id, tenancy_id, message, reference, amount, paid_date, paid_time, payer)
    values
      (v_tenancy.company_id, v_tenancy.id, v_message, v_parsed.reference, v_parsed.amount,
       v_parsed.paid_date, v_parsed.paid_time, v_parsed.payer)
    returning * into v_claim;
  exception when unique_violation then
    raise exception 'This message was already sent' using errcode = '23505';
  end;

  return to_jsonb(v_claim);
end $$;

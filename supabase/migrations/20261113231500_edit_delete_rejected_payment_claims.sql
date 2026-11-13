-- Allow tenants to edit/resubmit or delete their own rejected payment claims,
-- and notify tenants when staff confirm or reject a payment claim.

create or replace function public.update_payment_claim(p_claim_id uuid, p_message text)
returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_message text := trim(coalesce(p_message, ''));
  v_claim public.payment_claims%rowtype;
  v_parsed record;
begin
  if char_length(v_message) < 20 then
    raise exception 'Paste the whole confirmation message' using errcode = '22023';
  end if;
  if char_length(v_message) > 1000 then
    raise exception 'That message is too long. Paste only the confirmation message.' using errcode = '22023';
  end if;

  select c.* into v_claim
  from public.payment_claims c
  where c.id = p_claim_id and c.tenancy_id in (select app.tenant_current_tenancy_ids())
  for update;

  if v_claim.id is null then
    raise exception 'Payment message not found' using errcode = 'P0002';
  end if;
  if v_claim.status <> 'rejected' then
    raise exception 'Only rejected payment messages can be edited' using errcode = '55000';
  end if;

  select * into v_parsed from app.parse_payment_message(v_message);

  if v_parsed.reference is null or v_parsed.amount is null then
    raise exception 'Paste the full M-Pesa or bank confirmation message, including the reference and amount.' using errcode = '22023';
  end if;

  if exists (select 1 from public.payments p
             where p.company_id = v_claim.company_id and upper(p.reference) = v_parsed.reference) then
    raise exception 'This payment is already recorded' using errcode = '23505';
  end if;

  begin
    update public.payment_claims
    set message = v_message,
        reference = v_parsed.reference,
        amount = v_parsed.amount,
        paid_date = v_parsed.paid_date,
        paid_time = v_parsed.paid_time,
        payer = v_parsed.payer,
        status = 'pending',
        review_note = null,
        reviewed_by = null,
        reviewed_at = null,
        created_at = now()
    where id = v_claim.id
    returning * into v_claim;
  exception when unique_violation then
    raise exception 'This message was already sent' using errcode = '23505';
  end;

  return to_jsonb(v_claim);
end $$;

revoke all on function public.update_payment_claim(uuid, text) from public, anon;
grant execute on function public.update_payment_claim(uuid, text) to authenticated;

create or replace function public.delete_payment_claim(p_claim_id uuid)
returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_deleted uuid;
begin
  delete from public.payment_claims c
  where c.id = p_claim_id
    and c.tenancy_id in (select app.tenant_current_tenancy_ids())
    and c.status = 'rejected'
  returning c.id into v_deleted;

  if v_deleted is null then
    raise exception 'Rejected payment message not found' using errcode = 'P0002';
  end if;
end $$;

revoke all on function public.delete_payment_claim(uuid) from public, anon;
grant execute on function public.delete_payment_claim(uuid) to authenticated;

-- Also emit an in-app notification when staff confirm or reject a payment claim.
create or replace function public.review_payment_claim(
  p_company_id text,
  p_claim_id uuid,
  p_action text,
  p_reviewer text,
  p_reference text default null,
  p_amount integer default null,
  p_date date default null,
  p_time text default null,
  p_method text default null,
  p_note text default null
)
returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_claim public.payment_claims%rowtype;
  v_reference text := upper(trim(coalesce(p_reference, '')));
  v_note text := nullif(trim(coalesce(p_note, '')), '');
  v_receipt text;
begin
  select c.* into v_claim
  from public.payment_claims c
  where c.id = p_claim_id and c.company_id = p_company_id
  for update;
  if v_claim.id is null then
    raise exception 'Payment message not found' using errcode = 'P0002';
  end if;
  if v_claim.status <> 'pending' then
    raise exception 'This payment message was already reviewed' using errcode = '55000';
  end if;

  if p_action = 'reject' then
    if v_note is null then
      raise exception 'Give a reason so the tenant knows what to do' using errcode = '22023';
    end if;
    update public.payment_claims
    set status = 'rejected', review_note = left(v_note, 300), reviewed_by = p_reviewer, reviewed_at = now()
    where id = v_claim.id;

    insert into public.notifications (company_id, tenancy_id, kind, title, body)
    values (
      v_claim.company_id,
      v_claim.tenancy_id,
      'general',
      'Payment message not confirmed',
      left(v_note, 900)
    );

    return jsonb_build_object('status', 'rejected', 'tenancyId', v_claim.tenancy_id);
  end if;

  if p_action <> 'confirm' then
    raise exception 'Unknown action' using errcode = '22023';
  end if;
  if v_reference !~ '^[A-Z0-9]{6,20}$' then
    raise exception 'Enter the transaction reference (6 to 20 letters and digits)' using errcode = '22023';
  end if;
  if p_amount is null or p_amount < 1 or p_amount > 1000000 then
    raise exception 'Enter the amount received' using errcode = '22023';
  end if;
  if p_date is null or p_date > (now() at time zone 'Africa/Nairobi')::date then
    raise exception 'Enter the date the money was received' using errcode = '22023';
  end if;
  if coalesce(p_time, '') !~ '^([01]\d|2[0-3]):[0-5]\d$' then
    raise exception 'Enter the time as HH:MM' using errcode = '22023';
  end if;
  if p_method not in ('M-Pesa', 'Bank') then
    raise exception 'Choose M-Pesa or Bank' using errcode = '22023';
  end if;
  if exists (select 1 from public.payments p
             where p.company_id = v_claim.company_id and upper(p.reference) = v_reference) then
    raise exception 'A payment with this reference is already recorded' using errcode = '23505';
  end if;

  insert into public.payments (company_id, tenancy_id, amount, date, time, method, reference)
  values (v_claim.company_id, v_claim.tenancy_id, p_amount, p_date, p_time, p_method, v_reference)
  returning receipt_number into v_receipt;

  begin
    update public.payment_claims
    set status = 'confirmed', reference = v_reference, amount = p_amount, paid_date = p_date,
        paid_time = p_time, receipt_number = v_receipt, review_note = left(v_note, 300),
        reviewed_by = p_reviewer, reviewed_at = now()
    where id = v_claim.id;
  exception when unique_violation then
    raise exception 'Another payment message already has this reference' using errcode = '23505';
  end;

  insert into public.notifications (company_id, tenancy_id, kind, title, body)
  values (
    v_claim.company_id,
    v_claim.tenancy_id,
    'general',
    'Payment confirmed',
    format('KES %s (%s) confirmed. Receipt %s is ready in Payments.',
      to_char(p_amount, 'FM999,999,999'), v_reference, v_receipt)
  );

  return jsonb_build_object('status', 'confirmed', 'tenancyId', v_claim.tenancy_id, 'receiptNumber', v_receipt);
end $$;

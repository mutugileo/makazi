-- Payment claims replace M-Pesa test mode. M-Pesa is not connected, so a
-- tenant pastes the confirmation message they received; staff match its
-- reference and amount against the Paybill or bank statement and confirm it,
-- which records the payment. A claim never changes a balance on its own.
--
-- Also: the landlord enters the rent for a move-in part-cycle
-- (tenancies.move_in_rent) instead of the engine prorating it.

-- ---------------------------------------------------------------------------
-- Move-in rent

-- Rent on the move-in bill. Null means a full month's rent (moved in on the
-- first day of a billing cycle).
alter table public.tenancies
  add column move_in_rent integer check (move_in_rent >= 0);

-- Existing tenancies keep what they were billed: the old rule prorated a
-- mid-month move-in by the days left in the calendar month, counting the
-- move-in day, rounded to the shilling.
update public.tenancies t
set move_in_rent = round(
  t.rent * (d.days_in_month - extract(day from t.move_in) + 1) / d.days_in_month
)::integer
from (
  select id,
         extract(day from date_trunc('month', move_in) + interval '1 month - 1 day') as days_in_month
  from public.tenancies
) d
where d.id = t.id and extract(day from t.move_in) > 1;

-- ---------------------------------------------------------------------------
-- M-Pesa test mode is gone. Recorded test payments keep payments.simulated.

drop function if exists public.simulate_mpesa_payment(integer, text);
update public.companies set settings = settings - 'mpesaSimulation' where settings ? 'mpesaSimulation';

-- ---------------------------------------------------------------------------
-- Payment claims

create table public.payment_claims (
  id uuid primary key default gen_random_uuid(),
  company_id text not null references public.companies (id),
  tenancy_id text not null,
  -- What the tenant pasted, as sent.
  message text not null check (char_length(message) between 20 and 1000),
  -- Read from the message; staff correct them when confirming.
  reference text,
  amount integer check (amount > 0),
  paid_date date,
  paid_time text check (paid_time ~ '^([01]\d|2[0-3]):[0-5]\d$'),
  payer text,
  status text not null default 'pending' check (status in ('pending', 'confirmed', 'rejected')),
  -- Why staff rejected it (shown to the tenant), or a note on confirming.
  review_note text check (char_length(review_note) <= 300),
  -- The payment a confirmed claim recorded.
  receipt_number text,
  reviewed_by text,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  foreign key (company_id, tenancy_id) references public.tenancies (company_id, id) on delete cascade
);

-- One live claim per transaction code; a rejected one can be sent again.
create unique index payment_claims_open_reference
  on public.payment_claims (company_id, reference)
  where reference is not null and status <> 'rejected';
create index payment_claims_queue on public.payment_claims (company_id, status, created_at desc);
create index payment_claims_tenancy on public.payment_claims (tenancy_id, created_at desc);

alter table public.payment_claims enable row level security;
revoke all on public.payment_claims from anon, authenticated;
-- Writes go through submit_payment_claim (tenants) and review_payment_claim
-- (the admin server); signed-in users only read.
grant select on public.payment_claims to authenticated;
create policy payment_claims_read on public.payment_claims for select to authenticated using (
  company_id in (select app.admin_company_ids())
  or tenancy_id in (select app.tenant_tenancy_ids())
);

-- Reads reference, amount, date, time and payer from an M-Pesa or bank
-- confirmation. Handles both sides:
--   received: "Confirmed. You have received KES 31200.00 for Account 404020
--              from AUGUSTINE MUSA. # Mpesa Ref:UKA1D18L3S on 10-11-2026 13:34Hrs"
--   sent:     "UKA1D18L3S Confirmed. Ksh31,200.00 sent to THE PHOENIX for
--              account 404020 on 10/11/26 at 1:34 PM New M-PESA balance ..."
-- Anything it can't read stays null for staff to fill in.
create or replace function app.parse_payment_message(
  p_message text,
  out reference text,
  out amount integer,
  out paid_date date,
  out paid_time text,
  out payer text
)
language plpgsql immutable set search_path = '' as $$
declare
  v text := regexp_replace(coalesce(p_message, ''), '\s+', ' ', 'g');
  m text[];
  v_amount numeric;
  v_hour integer;
  v_year integer;
begin
  -- A 10-character transaction code: labelled "Ref", leading "... Confirmed",
  -- or failing that the first code with both letters and digits.
  m := regexp_match(v, 'ref(?:erence)?\s*[:.#-]?\s*([A-Za-z0-9]{10})\M', 'i');
  if m is null then
    m := regexp_match(v, '\m([A-Za-z0-9]{10})\M\s*confirmed', 'i');
  end if;
  if m is null then
    m := regexp_match(v, '\m((?=[A-Z0-9]*[0-9])(?=[A-Z0-9]*[A-Z])[A-Z0-9]{10})\M');
  end if;
  reference := upper(m[1]);

  -- The first amount (a balance or charge comes after it).
  m := regexp_match(v, '(?:KES|KSH)\.?\s*([0-9][0-9,]*(?:\.[0-9]{1,2})?)', 'i');
  if m is not null then
    v_amount := round(replace(m[1], ',', '')::numeric);
    if v_amount between 1 and 1000000 then
      amount := v_amount::integer;
    end if;
  end if;

  -- Day first: 10-11-2026 or 10/11/26.
  m := regexp_match(v, '\m(\d{1,2})[-/](\d{1,2})[-/](\d{4}|\d{2})\M');
  if m is not null then
    v_year := case when length(m[3]) = 2 then 2000 + m[3]::integer else m[3]::integer end;
    begin
      paid_date := make_date(v_year, m[2]::integer, m[1]::integer);
    exception when others then
      paid_date := null;
    end;
  end if;

  -- 13:34 or 1:34 PM.
  m := regexp_match(v, '\m(\d{1,2}):([0-5]\d)\s*(AM|PM)?', 'i');
  if m is not null then
    v_hour := m[1]::integer;
    if upper(m[3]) = 'PM' and v_hour < 12 then
      v_hour := v_hour + 12;
    elsif upper(m[3]) = 'AM' and v_hour = 12 then
      v_hour := 0;
    end if;
    if v_hour < 24 then
      paid_time := lpad(v_hour::text, 2, '0') || ':' || m[2];
    end if;
  end if;

  -- Who paid, on a received confirmation: up to "#" or " on <date>".
  m := regexp_match(v, '\mfrom\s+([^#]+)', 'i');
  payer := nullif(left(regexp_replace(regexp_replace(m[1], '\s+on\s.*$', '', 'i'), '[\s.]+$', ''), 120), '');
end $$;

revoke all on function app.parse_payment_message(text) from public;

-- A signed-in tenant sends a confirmation message for their current tenancy.
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

  if v_parsed.reference is not null then
    if exists (select 1 from public.payments p
               where p.company_id = v_tenancy.company_id and upper(p.reference) = v_parsed.reference) then
      raise exception 'This payment is already recorded' using errcode = '23505';
    end if;
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

revoke all on function public.submit_payment_claim(text, text) from public, anon;
grant execute on function public.submit_payment_claim(text, text) to authenticated;

-- Staff confirm (records the payment) or reject (with a reason) a pending
-- claim. Called by the admin server only, which checks the staff member's
-- role and passes their company.
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

  return jsonb_build_object('status', 'confirmed', 'tenancyId', v_claim.tenancy_id, 'receiptNumber', v_receipt);
end $$;

revoke all on function public.review_payment_claim(text, uuid, text, text, text, integer, date, text, text, text)
  from public, anon, authenticated;
grant execute on function public.review_payment_claim(text, uuid, text, text, text, integer, date, text, text, text)
  to service_role;

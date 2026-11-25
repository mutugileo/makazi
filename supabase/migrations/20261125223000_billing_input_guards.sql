-- Audit 2026-11-25: stop bad dates and readings reaching the ledger, add the
-- missing foreign-key indexes and two integrity checks. Additive only.

-- 1. Payments: never in the future, and never before an uploaded tenancy's
--    opening cycle (the sheet balance is already net of those payments, so
--    counting them again would cut the balance twice). Covers the admin's
--    record-payment and review_payment_claim alike.
create or replace function app.guard_payment_date() returns trigger
language plpgsql set search_path = '' as $$
declare
  v_opening text;
  v_cycle_start date;
begin
  if new.date > (now() at time zone 'Africa/Nairobi')::date then
    raise exception 'A payment can''t be dated in the future.' using errcode = '22023';
  end if;
  select opening_balance_month into v_opening from public.tenancies where id = new.tenancy_id;
  if v_opening is not null then
    -- Cycles start on the 4th from December 2026, on the 1st before.
    v_cycle_start := case when v_opening >= '2026-12' then (v_opening || '-04')::date
                          else (v_opening || '-01')::date end;
    if new.date < v_cycle_start then
      raise exception 'This payment is dated before the tenant''s opening balance (%). It is already counted in that balance.',
        to_char(v_cycle_start, 'DD Mon YYYY') using errcode = '22023';
    end if;
  end if;
  return new;
end $$;

drop trigger if exists payments_guard_date on public.payments;
create trigger payments_guard_date before insert or update of date, tenancy_id on public.payments
  for each row execute function app.guard_payment_date();

-- 2. Meter readings: no future cycle, and a meter only counts up.
create or replace function app.guard_meter_reading() returns trigger
language plpgsql set search_path = '' as $$
declare v_prev int; v_next int;
begin
  if new.month !~ '^\d{4}-(0[1-9]|1[0-2])$' then
    raise exception 'Reading month must look like 2026-12.' using errcode = '22023';
  end if;
  if new.value < 0 then
    raise exception 'A meter reading can''t be negative.' using errcode = '22023';
  end if;
  if new.month > to_char((now() at time zone 'Africa/Nairobi') + interval '1 month', 'YYYY-MM') then
    raise exception 'Readings can''t be saved for a future billing cycle.' using errcode = '22023';
  end if;
  select value into v_prev from public.meter_readings
   where unit_id = new.unit_id and month < new.month order by month desc limit 1;
  if v_prev is not null and new.value < v_prev then
    raise exception 'A reading of % is below the last one (%).', new.value, v_prev using errcode = '22023';
  end if;
  select value into v_next from public.meter_readings
   where unit_id = new.unit_id and month > new.month order by month limit 1;
  if v_next is not null and new.value > v_next then
    raise exception 'A reading of % is above the next saved one (%).', new.value, v_next using errcode = '22023';
  end if;
  return new;
end $$;

drop trigger if exists meter_readings_guard on public.meter_readings;
create trigger meter_readings_guard before insert or update on public.meter_readings
  for each row execute function app.guard_meter_reading();

-- 3. Indexes for composite foreign keys the advisor flagged.
create index if not exists payment_claims_company_tenancy_idx on public.payment_claims (company_id, tenancy_id);
create index if not exists messages_company_staff_idx on public.messages (company_id, staff_id);
create index if not exists properties_company_manager_idx on public.properties (company_id, manager_id);
create index if not exists property_enquiries_company_unit_idx on public.property_enquiries (company_id, unit_id);
create index if not exists repair_tickets_company_tenancy_unit_idx on public.repair_tickets (company_id, tenancy_id, unit_id);

-- 4. Integrity checks (no current violations).
alter table public.tenancies drop constraint if exists tenancies_lease_order;
alter table public.tenancies add constraint tenancies_lease_order check (lease_end >= lease_start);
alter table public.payment_claims drop constraint if exists payment_claims_confirmed_complete;
alter table public.payment_claims add constraint payment_claims_confirmed_complete
  check (status <> 'confirmed' or (receipt_number is not null and reviewed_at is not null));

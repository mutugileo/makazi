-- Plans and gating, enforced in the database so neither the admin nor any
-- future client can bypass them:
--   * platform_plans: the one source of plans, prices, limits and features
--     (the super-admin already reads it; until now it fell back to code).
--   * app.company_entitlements(): what a company may do right now.
--   * Suspended/cancelled companies are read-only for every landlord write
--     (properties, units, tenants, tenancies, payments, readings, staff,
--     repair ticket updates; other writes are refused by the admin itself).
--   * Staff seats are a hard limit.
--   * companies.subscription changes only through
--     public.superadmin_set_subscription() (service role only), audited.
-- Units over the plan limit are allowed and billed as overage (pricing says
-- "KES x / additional unit"), so units are not blocked here.

create table if not exists public.platform_plans (
  id text primary key check (id in ('starter', 'growth', 'enterprise', 'custom')),
  name text not null,
  description text not null default '',
  monthly_price_kes integer not null check (monthly_price_kes >= 0),
  annual_price_kes integer not null check (annual_price_kes >= 0),
  unit_limit integer not null check (unit_limit >= 0),
  extra_unit_rate_kes integer not null check (extra_unit_rate_kes >= 0),
  staff_limit integer not null check (staff_limit >= 1),
  is_popular boolean not null default false,
  -- Marketing bullets shown on pricing screens.
  features jsonb not null default '[]'::jsonb check (jsonb_typeof(features) = 'array'),
  -- Feature switches the apps enforce, e.g. {"property_payment_details": true}.
  entitlements jsonb not null default '{}'::jsonb check (jsonb_typeof(entitlements) = 'object'),
  sort_order integer not null default 0,
  updated_at timestamptz not null default now()
);

-- An older pricing_tiers migration may have created the table without these.
alter table public.platform_plans add column if not exists entitlements jsonb not null default '{}'::jsonb;
alter table public.platform_plans add column if not exists sort_order integer not null default 0;

alter table public.platform_plans enable row level security;
revoke all on public.platform_plans from anon, authenticated;

insert into public.platform_plans
  (id, name, description, monthly_price_kes, annual_price_kes, unit_limit, extra_unit_rate_kes, staff_limit, is_popular, features, entitlements, sort_order)
values
  ('starter', 'Starter', 'For independent landlords with one or two blocks.', 2000, 20000, 30, 50, 2, false,
   '["Up to 30 rental units", "2 staff seats", "KES 50 per extra unit a month", "Payment messages and receipts", "Water readings and billing", "Tenant mobile app", "Arrears tracking and reminders"]',
   '{"property_payment_details": false}', 1),
  ('growth', 'Growth', 'For agencies managing several properties.', 6500, 65000, 150, 40, 5, true,
   '["Up to 150 rental units", "5 staff seats", "KES 40 per extra unit a month", "Payment details per property", "Arrears ageing and reminders", "Statements and receipts"]',
   '{"property_payment_details": true}', 2),
  ('enterprise', 'Enterprise', 'For large portfolios and institutional managers.', 15000, 150000, 450, 30, 20, false,
   '["Up to 450 rental units", "20 staff seats", "KES 30 per extra unit a month", "Payment details per property", "Priority support"]',
   '{"property_payment_details": true}', 3),
  ('custom', 'Custom', 'Tailored terms for very large portfolios.', 30000, 300000, 1200, 20, 50, false,
   '["1,200+ rental units", "50 staff seats", "KES 20 per extra unit a month", "Payment details per property", "Dedicated account manager"]',
   '{"property_payment_details": true}', 4)
on conflict (id) do nothing;

-- What a company may do right now. Subscription values override plan
-- defaults (a negotiated limit); an expired trial counts as past due.
create or replace function app.company_entitlements(p_company_id text)
returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object(
    'plan', coalesce(c.subscription->>'plan', 'starter'),
    'planName', coalesce(p.name, initcap(coalesce(c.subscription->>'plan', 'starter'))),
    'status', case
      when c.subscription->>'status' in ('suspended', 'cancelled') then c.subscription->>'status'
      when coalesce((c.subscription->>'billingExempt')::boolean, false) then 'active'
      when c.subscription->>'status' = 'trial'
        and nullif(c.subscription->>'trialEndsAt', '') is not null
        and (c.subscription->>'trialEndsAt')::timestamptz < now() then 'past_due'
      else coalesce(c.subscription->>'status', 'active')
    end,
    'readOnly', coalesce(c.subscription->>'status', 'active') in ('suspended', 'cancelled'),
    'unitLimit', coalesce((c.subscription->>'unitLimit')::int, p.unit_limit, 30),
    'staffLimit', coalesce((c.subscription->>'staffLimit')::int, p.staff_limit, 2),
    'extraUnitRateKes', coalesce((c.subscription->>'extraUnitRateKes')::int, p.extra_unit_rate_kes, 0),
    'trialEndsAt', nullif(c.subscription->>'trialEndsAt', ''),
    'billingExempt', coalesce((c.subscription->>'billingExempt')::boolean, false),
    'features', coalesce(p.entitlements, '{}'::jsonb) || coalesce(c.subscription->'featureOverrides', '{}'::jsonb)
  )
  from public.companies c
  left join public.platform_plans p on p.id = c.subscription->>'plan'
  where c.id = p_company_id
$$;

revoke all on function app.company_entitlements(text) from public, anon, authenticated;

-- Readable by the server (admin and super-admin) through PostgREST.
create or replace function public.company_entitlements(p_company_id text)
returns jsonb
language sql stable security definer set search_path = ''
as $$ select app.company_entitlements(p_company_id) $$;

revoke all on function public.company_entitlements(text) from public, anon, authenticated;
grant execute on function public.company_entitlements(text) to service_role;

-- Suspended or cancelled: every landlord write is refused. Tenants' own
-- writes (payment messages, chat, repair requests) are untouched.
create or replace function app.guard_company_writable()
returns trigger
language plpgsql security definer set search_path = ''
as $$
declare
  v_company text := coalesce(new.company_id, old.company_id);
begin
  if coalesce((app.company_entitlements(v_company)->>'readOnly')::boolean, false) then
    raise exception 'This Makazi account is suspended. Contact Makazi support to restore access.'
      using errcode = '22023';
  end if;
  return coalesce(new, old);
end $$;

do $$
declare t text;
begin
  foreach t in array array['properties', 'units', 'tenants', 'tenancies', 'payments', 'meter_readings', 'staff'] loop
    execute format('drop trigger if exists %I on public.%I', 'zz_guard_company_writable', t);
    execute format(
      'create trigger %I before insert or update or delete on public.%I for each row execute function app.guard_company_writable()',
      'zz_guard_company_writable', t);
  end loop;
end $$;

drop trigger if exists zz_guard_company_writable on public.repair_tickets;
create trigger zz_guard_company_writable before update on public.repair_tickets
  for each row execute function app.guard_company_writable();

-- Staff seats are a hard limit.
create or replace function app.guard_staff_seats()
returns trigger
language plpgsql security definer set search_path = ''
as $$
declare
  v_limit int := coalesce((app.company_entitlements(new.company_id)->>'staffLimit')::int, 2);
  v_count int;
begin
  -- One seat check at a time per company, so two adds can't both pass.
  perform pg_advisory_xact_lock(hashtext('staff_seats:' || new.company_id));
  select count(*) into v_count from public.staff where company_id = new.company_id;
  if v_count >= v_limit then
    raise exception 'Your plan includes % staff seat%. Ask Makazi support to change your plan to add another.',
      v_limit, case when v_limit = 1 then '' else 's' end
      using errcode = '22023';
  end if;
  return new;
end $$;

drop trigger if exists zz_guard_staff_seats on public.staff;
create trigger zz_guard_staff_seats before insert on public.staff
  for each row execute function app.guard_staff_seats();

-- Subscriptions change only through the super-admin function below.
create or replace function app.guard_subscription_writes()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  if new.subscription is distinct from old.subscription
     and coalesce(current_setting('makazi.subscription_writer', true), '') <> 'superadmin' then
    raise exception 'A company''s plan can only be changed by Makazi support.' using errcode = '42501';
  end if;
  return new;
end $$;

drop trigger if exists zz_guard_subscription_writes on public.companies;
create trigger zz_guard_subscription_writes before update of subscription on public.companies
  for each row execute function app.guard_subscription_writes();

-- The one way to change a plan: whitelisted keys, validated, audited.
create or replace function public.superadmin_set_subscription(p_company_id text, p_changes jsonb, p_actor text)
returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_current jsonb;
  v_next jsonb;
  v_allowed text[] := array['plan', 'status', 'billingCycle', 'unitLimit', 'staffLimit', 'priceKes',
    'extraUnitRateKes', 'trialEndsAt', 'billingExempt', 'exemptionReason', 'featureOverrides'];
  v_key text;
begin
  if p_changes is null or jsonb_typeof(p_changes) <> 'object' then
    raise exception 'Changes must be an object.' using errcode = '22023';
  end if;
  for v_key in select jsonb_object_keys(p_changes) loop
    if not v_key = any (v_allowed) then
      raise exception 'Unknown subscription field: %', v_key using errcode = '22023';
    end if;
  end loop;

  select subscription into v_current from public.companies where id = p_company_id for update;
  if not found then
    raise exception 'Company not found.' using errcode = 'P0002';
  end if;
  v_next := coalesce(v_current, '{}'::jsonb) || p_changes;

  if not exists (select 1 from public.platform_plans where id = v_next->>'plan') then
    raise exception 'Unknown plan: %', v_next->>'plan' using errcode = '22023';
  end if;
  if coalesce(v_next->>'status', 'active') not in ('trial', 'active', 'past_due', 'suspended', 'cancelled') then
    raise exception 'Unknown status: %', v_next->>'status' using errcode = '22023';
  end if;
  if coalesce(v_next->>'billingCycle', 'monthly') not in ('monthly', 'annual', 'lifetime_exempt') then
    raise exception 'Unknown billing cycle: %', v_next->>'billingCycle' using errcode = '22023';
  end if;
  foreach v_key in array array['unitLimit', 'staffLimit', 'priceKes', 'extraUnitRateKes'] loop
    if v_next ? v_key and (jsonb_typeof(v_next->v_key) <> 'number' or (v_next->>v_key)::numeric < 0) then
      raise exception '% must be a number of 0 or more.', v_key using errcode = '22023';
    end if;
  end loop;
  if coalesce((v_next->>'staffLimit')::int, 1) < 1 then
    raise exception 'staffLimit must be at least 1.' using errcode = '22023';
  end if;
  if v_next ? 'featureOverrides' and jsonb_typeof(v_next->'featureOverrides') <> 'object' then
    raise exception 'featureOverrides must be an object.' using errcode = '22023';
  end if;

  perform set_config('makazi.subscription_writer', 'superadmin', true);
  update public.companies set subscription = v_next where id = p_company_id;
  perform set_config('makazi.subscription_writer', '', true);

  insert into public.audit_log (company_id, action, target, detail)
  values (p_company_id, 'subscription_updated', p_company_id,
          jsonb_build_object('changes', p_changes, 'by', p_actor, 'before', v_current));

  return app.company_entitlements(p_company_id);
end $$;

revoke all on function public.superadmin_set_subscription(text, jsonb, text) from public, anon, authenticated;
grant execute on function public.superadmin_set_subscription(text, jsonb, text) to service_role;

-- Makazi Platform Pricing Tiers (Kenya Market Blueprint)
--
-- Configures Starter, Growth, Enterprise, and Custom SaaS plans with base unit allowances,
-- overage rates, staff seat limits, and annual billing discounts for Codzure SaaS governance.

create table if not exists public.platform_plans (
  id text primary key check (id in ('starter', 'growth', 'enterprise', 'custom')),
  name text not null,
  description text not null,
  monthly_price_kes integer not null check (monthly_price_kes >= 0),
  annual_price_kes integer not null check (annual_price_kes >= 0),
  unit_limit integer not null check (unit_limit > 0),
  extra_unit_rate_kes integer not null check (extra_unit_rate_kes >= 0),
  staff_limit integer not null check (staff_limit > 0),
  is_popular boolean not null default false,
  features jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now()
);

-- Seed recommended Kenya market tiers
insert into public.platform_plans (
  id, name, description, monthly_price_kes, annual_price_kes, unit_limit, extra_unit_rate_kes, staff_limit, is_popular, features
) values
(
  'starter',
  'Starter',
  'Ideal for independent landlords with 1–2 residential blocks.',
  4500,
  45000,
  50,
  90,
  2,
  false,
  '[
    "Up to 50 active rental units",
    "2 staff seats (Owner + Caretaker)",
    "KES 90 / extra unit / mo past 50",
    "Automated M-Pesa Paybill matching",
    "Water meter readings & billing",
    "Tenant self-service mobile app",
    "Basic arrears tracking & notices"
  ]'::jsonb
),
(
  'growth',
  'Growth',
  'For professional property management agencies with growing multi-property portfolios.',
  12500,
  125000,
  200,
  70,
  5,
  true,
  '[
    "Up to 200 active rental units",
    "5 manager & caretaker seats",
    "KES 70 / extra unit / mo past 200",
    "Multi-property & dedicated Paybill / Till support",
    "Automated rent reminders & arrears ageing",
    "Full financial statements & KRA PIN receipts",
    "Priority Daraja webhook support",
    "PDF statement & invoice downloads"
  ]'::jsonb
),
(
  'enterprise',
  'Enterprise',
  'Large-scale real estate corporations, SACCOs, and institutional asset managers.',
  35000,
  350000,
  500,
  50,
  20,
  false,
  '[
    "500+ active rental units",
    "20+ staff seats with role-based MFA",
    "KES 50 / extra unit / mo past 500",
    "Multiple Paybill and bank settlement routes",
    "KRA eTIMS invoice synchronization ready",
    "Custom ERP & accounting ledger export",
    "Dedicated Codzure support engineer & SLA",
    "Custom domain & dedicated company slug"
  ]'::jsonb
),
(
  'custom',
  'Custom',
  'Tailored enterprise deployments with bespoke integrations, high unit volumes, and custom SLAs.',
  50000,
  500000,
  1000,
  40,
  50,
  false,
  '[
    "1,000+ rental units with bespoke volume discounts",
    "50+ staff accounts & fine-grained permission roles",
    "KES 40 / extra unit / mo",
    "Dedicated database instance & VPC peering",
    "Custom accounting system integration",
    "24/7 dedicated account manager"
  ]'::jsonb
)
on conflict (id) do update set
  name = excluded.name,
  description = excluded.description,
  monthly_price_kes = excluded.monthly_price_kes,
  annual_price_kes = excluded.annual_price_kes,
  unit_limit = excluded.unit_limit,
  extra_unit_rate_kes = excluded.extra_unit_rate_kes,
  staff_limit = excluded.staff_limit,
  is_popular = excluded.is_popular,
  features = excluded.features;

-- Enable RLS
alter table public.platform_plans enable row level security;

-- Everyone authenticated (or public client) can read platform pricing
create policy platform_plans_read on public.platform_plans for select to authenticated, anon using (true);

-- Only service role can modify plans
revoke all on public.platform_plans from anon, authenticated;
grant select on public.platform_plans to anon, authenticated;
grant all on public.platform_plans to service_role;

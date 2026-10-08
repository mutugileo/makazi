-- Makazi: Paybills & Suspense Payments Queue
--
-- Supports multi-shortcode routing for landlords with their own Safaricom
-- Paybill / Till numbers, plus a suspense table for unmatched transactions
-- (e.g. mistyped unit codes).

create table if not exists public.suspense_payments (
  id text primary key default gen_random_uuid()::text,
  company_id text not null references public.companies (id),
  trans_id text not null,
  amount integer not null check (amount > 0),
  msisdn text not null,
  bill_ref_number text not null,
  shortcode text not null,
  raw_payload jsonb not null default '{}',
  status text not null default 'unresolved' check (status in ('unresolved', 'resolved', 'refunded')),
  resolved_tenancy_id text references public.tenancies (id),
  resolved_by text,
  resolved_at timestamptz,
  created_at timestamptz not null default now(),
  unique (shortcode, trans_id)
);

create index if not exists suspense_payments_company_idx on public.suspense_payments (company_id, status);
create index if not exists suspense_payments_trans_idx on public.suspense_payments (trans_id);

-- Grants
grant select, insert, update on public.suspense_payments to service_role;
grant select on public.suspense_payments to authenticated;

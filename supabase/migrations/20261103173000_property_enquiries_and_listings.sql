-- Migration: property_enquiries and unit listing fields
-- Supports bulk property onboarding, vacancy tracking, and enquiry pipeline CRM.

alter table public.units
  add column if not exists is_listed boolean not null default false,
  add column if not exists listed_rent integer check (listed_rent is null or listed_rent > 0),
  add column if not exists listing_notes text not null default '';

create table if not exists public.property_enquiries (
  id text primary key default gen_random_uuid()::text,
  company_id text not null references public.companies (id) on delete cascade,
  property_id text not null,
  unit_id text,
  name text not null check (length(name) between 1 and 120),
  phone text not null,
  email text not null default '',
  source text not null default 'walk_in' check (source in ('walk_in', 'website', 'referral', 'signboard', 'whatsapp', 'social')),
  status text not null default 'new' check (status in ('new', 'viewing_scheduled', 'vetted', 'converted', 'archived')),
  viewing_at timestamptz,
  notes text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  foreign key (company_id, property_id) references public.properties (company_id, id) on delete cascade,
  foreign key (company_id, unit_id) references public.units (company_id, id) on delete set null
);

create index if not exists idx_enquiries_company_status on public.property_enquiries (company_id, status);
create index if not exists idx_enquiries_property on public.property_enquiries (company_id, property_id);

alter table public.property_enquiries enable row level security;

create policy property_enquiries_admin_read on public.property_enquiries for select to authenticated using (
  company_id in (select app.admin_company_ids())
);

create policy property_enquiries_admin_insert on public.property_enquiries for insert to authenticated
  with check (company_id in (select app.admin_company_ids()));

create policy property_enquiries_admin_update on public.property_enquiries for update to authenticated
  using (company_id in (select app.admin_company_ids()))
  with check (company_id in (select app.admin_company_ids()));

create policy property_enquiries_admin_delete on public.property_enquiries for delete to authenticated
  using (company_id in (select app.admin_company_ids()));


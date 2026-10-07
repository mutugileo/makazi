-- Makazi: initial schema, access rules and helpers.
--
-- Column names match what both apps read (PropAdmin/src/lib/supabase-data.ts
-- and lib/core/data/supabase_rows.dart). Every table carries company_id, and
-- child rows point at their parent through (company_id, id) so a row can never
-- reference another company's property, unit, tenant or tenancy.
--
-- Who sees what (see shared/AUTH.md):
--   owner / manager  whole company, on the admin site (MFA can be required:
--                    update app.settings set require_staff_mfa = true)
--   caretaker        their properties' units, meter readings and repairs only;
--                    no money, no tenant phone numbers
--   tenant           their own tenancy only; nothing while a one-time
--                    password is still unchanged; read-only after move-out and
--                    nothing once the company's retention period has passed
--   service role     the M-Pesa callback and onboarding Edge Functions
--
-- Nothing is deleted from a client: records are kept for statements.

-- ---------------------------------------------------------------------------
-- Private schema for helpers. Not exposed by the Data API.

create schema if not exists app;
revoke all on schema app from public;
grant usage on schema app to authenticated;

create table app.settings (
  id boolean primary key default true check (id),
  -- Turn on once the admin's authenticator-app step is live.
  require_staff_mfa boolean not null default false
);
insert into app.settings default values;

-- One-time passwords that haven't been changed yet. While a row exists for a
-- user, every access rule returns nothing for them.
create table app.pending_passwords (
  user_id uuid primary key references auth.users (id) on delete cascade,
  password_hash text not null,
  expires_at timestamptz not null
);

-- ---------------------------------------------------------------------------
-- Tables

create table public.companies (
  id text primary key check (id ~ '^[a-z0-9-]+$'),
  slug text not null unique check (slug ~ '^[a-z0-9-]+$'),
  name text not null check (length(name) between 1 and 120),
  kra_pin text not null default '',
  mpesa_paybill text not null default '',
  bank_name text not null default '',
  bank_account text not null default '',
  settings jsonb not null check (
    settings ?& array['ledgerStartMonth', 'dueDay', 'graceDay', 'depositSchedule', 'recordRetentionMonths']
  ),
  sequences jsonb not null default '{"receipt": 0, "repairTicket": 0}' check (
    sequences ?& array['receipt', 'repairTicket']
  ),
  -- Plans are stored and shown, not billed (Codzure sets them).
  subscription jsonb not null check (
    subscription ?& array['plan', 'status', 'unitLimit', 'staffLimit', 'trialEndsAt']
  ),
  created_at timestamptz not null default now()
);

-- Staff doubles as the membership table: one row per person per company.
-- user_id links the row to a login; only the onboarding function sets it.
create table public.staff (
  id text primary key default gen_random_uuid()::text,
  company_id text not null references public.companies (id),
  user_id uuid references auth.users (id) on delete set null,
  name text not null check (length(name) between 1 and 120),
  role text not null check (role in ('owner', 'manager', 'caretaker')),
  phone text,
  property_ids text[] not null default '{}',
  unique (company_id, id),
  unique (company_id, user_id)
);

create table public.properties (
  id text primary key default gen_random_uuid()::text,
  company_id text not null references public.companies (id),
  manager_id text not null,
  name text not null check (length(name) between 1 and 120),
  type text not null check (type in ('apartments', 'houses')),
  address text not null default '',
  account_prefix text not null,
  -- Current rates; rate_history keeps every change with the month it applies from.
  water_rate integer not null check (water_rate >= 0),
  garbage_fee integer not null check (garbage_fee >= 0),
  rate_history jsonb not null default '[]' check (jsonb_typeof(rate_history) = 'array'),
  unique (company_id, id),
  foreign key (company_id, manager_id) references public.staff (company_id, id)
);

create table public.units (
  id text primary key default gen_random_uuid()::text,
  company_id text not null references public.companies (id),
  property_id text not null,
  label text not null check (length(label) between 1 and 40),
  bedrooms smallint not null check (bedrooms between 0 and 10),
  unique (company_id, id),
  unique (property_id, label),
  foreign key (company_id, property_id) references public.properties (company_id, id)
);

create table public.tenants (
  id text primary key default gen_random_uuid()::text,
  company_id text not null references public.companies (id),
  -- The tenant's login. One person can rent from two landlords with one login.
  auth_user_id uuid references auth.users (id) on delete set null,
  name text not null check (length(name) between 1 and 120),
  phone text not null,
  email text not null default '',
  unique (company_id, id),
  unique (company_id, phone),
  unique (company_id, auth_user_id)
);

create table public.tenancies (
  id text primary key default gen_random_uuid()::text,
  company_id text not null references public.companies (id),
  tenant_id text not null,
  unit_id text not null,
  rent integer not null check (rent > 0),
  deposit integer not null check (deposit >= 0),
  move_in date not null,
  move_out date check (move_out is null or move_out >= move_in),
  lease_start date not null,
  lease_end date not null,
  -- Balance carried in from before the ledger started (+ owed, - credit).
  opening_balance integer not null default 0,
  opening_reading integer check (opening_reading >= 0),
  renewal jsonb,
  move_out_note text,
  deposit_refund jsonb,
  unique (company_id, id),
  unique (company_id, id, unit_id),
  foreign key (company_id, tenant_id) references public.tenants (company_id, id),
  foreign key (company_id, unit_id) references public.units (company_id, id)
);
-- A unit has at most one tenant who hasn't moved out.
create unique index tenancies_one_current_per_unit on public.tenancies (unit_id) where move_out is null;

-- The caretaker's reading for a unit at the end of a month (the "token").
create table public.meter_readings (
  company_id text not null references public.companies (id),
  unit_id text not null,
  month text not null check (month ~ '^\d{4}-(0[1-9]|1[0-2])$'),
  value integer not null check (value >= 0),
  recorded_by uuid default auth.uid(),
  recorded_at timestamptz not null default now(),
  primary key (unit_id, month),
  foreign key (company_id, unit_id) references public.units (company_id, id)
);

create table public.payments (
  company_id text not null references public.companies (id),
  -- Filled from companies.sequences when left out: RCT-YYMM-NNNN.
  receipt_number text not null,
  tenancy_id text not null,
  amount integer not null check (amount > 0),
  date date not null,
  time text not null check (time ~ '^([01]\d|2[0-3]):[0-5]\d$'),
  method text not null check (method in ('M-Pesa', 'Bank')),
  reference text not null,
  created_at timestamptz not null default now(),
  primary key (company_id, receipt_number),
  -- M-Pesa retries its callback; a transaction code is recorded once.
  unique (company_id, method, reference),
  foreign key (company_id, tenancy_id) references public.tenancies (company_id, id)
);

create table public.repair_tickets (
  company_id text not null references public.companies (id),
  -- Filled from companies.sequences when left out: MT-NNNN.
  id text not null,
  tenancy_id text not null,
  unit_id text not null,
  category text not null check (category in ('plumbing', 'electrical', 'carpentry', 'appliance', 'security')),
  priority text not null default 'medium' check (priority in ('low', 'medium', 'high')),
  status text not null default 'open' check (status in ('open', 'in_progress', 'resolved')),
  title text not null check (length(title) between 1 and 120),
  description text not null default '' check (length(description) <= 2000),
  has_photo boolean not null default false,
  created_at timestamptz not null default now(),
  resolved_at timestamptz,
  -- Who's fixing it: a staff member or an outside fundi, as written by staff.
  assigned_to text check (length(assigned_to) <= 120),
  resolution_note text check (length(resolution_note) <= 2000),
  primary key (company_id, id),
  -- The unit must be the tenancy's unit.
  foreign key (company_id, tenancy_id, unit_id) references public.tenancies (company_id, id, unit_id)
);

-- One thread per tenancy.
create table public.messages (
  id text primary key default gen_random_uuid()::text,
  company_id text not null references public.companies (id),
  tenancy_id text not null,
  sender text not null check (sender in ('tenant', 'staff')),
  staff_id text,
  body text not null check (length(body) between 1 and 2000),
  sent_at timestamptz not null default now(),
  read_by_staff_at timestamptz,
  check ((sender = 'staff') = (staff_id is not null)),
  foreign key (company_id, tenancy_id) references public.tenancies (company_id, id),
  foreign key (company_id, staff_id) references public.staff (company_id, id)
);

-- Who did what, for password resets, phone changes, move-outs, deposit
-- refunds and balance corrections. Written by triggers only.
create table public.audit_log (
  id bigint generated always as identity primary key,
  company_id text not null references public.companies (id),
  actor uuid,
  action text not null,
  target text not null,
  detail jsonb not null default '{}',
  at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Indexes for the access rules and the per-company reads both apps make.
-- (Primary keys and unique constraints above already cover id lookups.)

create index staff_user_id_idx on public.staff (user_id);
create index properties_company_idx on public.properties (company_id);
create index units_company_property_idx on public.units (company_id, property_id);
create index tenants_auth_user_idx on public.tenants (auth_user_id);
create index tenancies_company_unit_idx on public.tenancies (company_id, unit_id);
create index tenancies_company_tenant_idx on public.tenancies (company_id, tenant_id);
create index meter_readings_company_unit_idx on public.meter_readings (company_id, unit_id, month);
create index payments_company_tenancy_idx on public.payments (company_id, tenancy_id, date);
create index repair_tickets_company_tenancy_idx on public.repair_tickets (company_id, tenancy_id);
create index repair_tickets_company_status_idx on public.repair_tickets (company_id, status);
create index messages_company_tenancy_idx on public.messages (company_id, tenancy_id, sent_at);
create index audit_log_company_idx on public.audit_log (company_id, at desc);

-- ---------------------------------------------------------------------------
-- Access helpers. SECURITY DEFINER so they can read the membership tables
-- without tripping the very rules they serve; each only ever answers about
-- the signed-in user (auth.uid()).

create function app.staff_mfa_ok() returns boolean
language sql stable security definer set search_path = '' as $$
  select not coalesce((select s.require_staff_mfa from app.settings s), false)
      or coalesce(auth.jwt() ->> 'aal', '') = 'aal2';
$$;

-- Companies the user runs on the admin site (owner or manager).
create function app.admin_company_ids() returns setof text
language sql stable security definer set search_path = '' as $$
  select s.company_id from public.staff s
  where s.user_id = auth.uid() and s.role in ('owner', 'manager') and app.staff_mfa_ok();
$$;

create function app.owner_company_ids() returns setof text
language sql stable security definer set search_path = '' as $$
  select s.company_id from public.staff s
  where s.user_id = auth.uid() and s.role = 'owner' and app.staff_mfa_ok();
$$;

-- Properties the user looks after as a caretaker.
create function app.caretaker_property_ids() returns setof text
language sql stable security definer set search_path = '' as $$
  select unnest(s.property_ids) from public.staff s
  where s.user_id = auth.uid() and s.role = 'caretaker';
$$;

create function app.password_pending() returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from app.pending_passwords p where p.user_id = auth.uid());
$$;

-- The signed-in tenant's tenancies, current and former, until the company's
-- record-retention period after move-out has passed.
create function app.tenant_tenancy_ids() returns setof text
language sql stable security definer set search_path = '' as $$
  select t.id
  from public.tenancies t
  join public.tenants tn on tn.company_id = t.company_id and tn.id = t.tenant_id
  join public.companies c on c.id = t.company_id
  where tn.auth_user_id = auth.uid()
    and not app.password_pending()
    and (
      t.move_out is null
      or t.move_out + make_interval(months => coalesce((c.settings ->> 'recordRetentionMonths')::int, 6))
         >= (now() at time zone 'Africa/Nairobi')::date
    );
$$;

-- Tenancies that can still raise repairs and send messages (not moved out).
create function app.tenant_current_tenancy_ids() returns setof text
language sql stable security definer set search_path = '' as $$
  select t.id from public.tenancies t
  where t.id in (select app.tenant_tenancy_ids())
    and (t.move_out is null or t.move_out >= (now() at time zone 'Africa/Nairobi')::date);
$$;

create function app.tenant_unit_ids() returns setof text
language sql stable security definer set search_path = '' as $$
  select t.unit_id from public.tenancies t where t.id in (select app.tenant_tenancy_ids());
$$;

create function app.tenant_property_ids() returns setof text
language sql stable security definer set search_path = '' as $$
  select u.property_id from public.units u where u.id in (select app.tenant_unit_ids());
$$;

create function app.tenant_company_ids() returns setof text
language sql stable security definer set search_path = '' as $$
  select t.company_id from public.tenancies t where t.id in (select app.tenant_tenancy_ids());
$$;

create function app.caretaker_company_ids() returns setof text
language sql stable security definer set search_path = '' as $$
  select s.company_id from public.staff s where s.user_id = auth.uid() and s.role = 'caretaker';
$$;

revoke all on all functions in schema app from public;
grant execute on all functions in schema app to authenticated;

-- ---------------------------------------------------------------------------
-- Receipt and repair numbers come from the company's own sequence, so two
-- landlords never share a counter and a tenant can raise a request without
-- being able to write to companies.

create function app.next_sequence(p_company text, p_key text) returns integer
language plpgsql security definer set search_path = '' as $$
declare n integer;
begin
  update public.companies
     set sequences = jsonb_set(sequences, array[p_key], to_jsonb(coalesce((sequences ->> p_key)::int, 0) + 1))
   where id = p_company
  returning (sequences ->> p_key)::int into n;
  if n is null then raise exception 'Unknown company %', p_company; end if;
  return n;
end $$;
revoke all on function app.next_sequence(text, text) from public, authenticated;

create function app.fill_receipt_number() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if new.receipt_number is null then
    new.receipt_number := 'RCT-' || to_char(new.date, 'YYMM') || '-'
      || lpad(app.next_sequence(new.company_id, 'receipt')::text, 4, '0');
  end if;
  return new;
end $$;
create trigger payments_fill_receipt_number before insert on public.payments
  for each row execute function app.fill_receipt_number();

create function app.fill_ticket() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if new.id is null then
    new.id := 'MT-' || lpad(app.next_sequence(new.company_id, 'repairTicket')::text, 4, '0');
  end if;
  -- Signed-in users can't backdate a request.
  if auth.uid() is not null then new.created_at := now(); end if;
  return new;
end $$;
create trigger repair_tickets_fill before insert on public.repair_tickets
  for each row execute function app.fill_ticket();

create function app.stamp_message() returns trigger
language plpgsql set search_path = '' as $$
begin
  if auth.uid() is not null then new.sent_at := now(); end if;
  return new;
end $$;
create trigger messages_stamp before insert on public.messages
  for each row execute function app.stamp_message();

-- Caretakers may move a repair along (status, who's on it, the fix) but not
-- re-categorise, re-prioritise or reword the tenant's request.
create function app.guard_ticket_update() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if auth.uid() is not null
     and new.company_id not in (select app.admin_company_ids())
     and (new.category, new.priority, new.title, new.description, new.has_photo)
         is distinct from (old.category, old.priority, old.title, old.description, old.has_photo) then
    raise exception 'Only a manager can change the request itself' using errcode = '42501';
  end if;
  return new;
end $$;
create trigger repair_tickets_guard before update on public.repair_tickets
  for each row execute function app.guard_ticket_update();

-- ---------------------------------------------------------------------------
-- Audit log triggers.

create function app.audit() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if tg_table_name = 'tenants' and new.phone is distinct from old.phone then
    insert into public.audit_log (company_id, actor, action, target, detail)
    values (new.company_id, auth.uid(), 'phone_changed', new.id, jsonb_build_object('from', old.phone, 'to', new.phone));
  elsif tg_table_name = 'tenancies' then
    if new.move_out is distinct from old.move_out then
      insert into public.audit_log (company_id, actor, action, target, detail)
      values (new.company_id, auth.uid(), 'move_out', new.id, jsonb_build_object('from', old.move_out, 'to', new.move_out));
    end if;
    if new.deposit_refund is distinct from old.deposit_refund then
      insert into public.audit_log (company_id, actor, action, target, detail)
      values (new.company_id, auth.uid(), 'deposit_refund', new.id, coalesce(new.deposit_refund, '{}'));
    end if;
    if new.opening_balance is distinct from old.opening_balance then
      insert into public.audit_log (company_id, actor, action, target, detail)
      values (new.company_id, auth.uid(), 'balance_corrected', new.id,
              jsonb_build_object('from', old.opening_balance, 'to', new.opening_balance));
    end if;
  end if;
  return new;
end $$;
create trigger tenants_audit after update on public.tenants for each row execute function app.audit();
create trigger tenancies_audit after update on public.tenancies for each row execute function app.audit();

-- ---------------------------------------------------------------------------
-- Privileges: an explicit allow-list. anon gets nothing; deletes are never
-- allowed from a client; payments and the audit log are read-only.

revoke all on all tables in schema public from anon, authenticated;
grant select on all tables in schema public to authenticated;

grant update (name, kra_pin, mpesa_paybill, bank_name, bank_account, settings) on public.companies to authenticated;
grant insert (id, company_id, name, role, phone, property_ids) on public.staff to authenticated;
grant update (name, role, phone, property_ids) on public.staff to authenticated;
grant insert, update (manager_id, name, type, address, account_prefix, water_rate, garbage_fee, rate_history)
  on public.properties to authenticated;
grant insert, update (label, bedrooms) on public.units to authenticated;
grant insert (id, company_id, name, phone, email) on public.tenants to authenticated;
grant update (name, phone, email) on public.tenants to authenticated;
grant insert, update (rent, deposit, move_in, move_out, lease_start, lease_end, opening_balance, opening_reading,
  renewal, move_out_note, deposit_refund) on public.tenancies to authenticated;
grant insert (company_id, unit_id, month, value), update (value) on public.meter_readings to authenticated;
grant insert (company_id, tenancy_id, unit_id, category, priority, title, description, has_photo, assigned_to)
  on public.repair_tickets to authenticated;
grant update (category, priority, status, title, description, has_photo, resolved_at, assigned_to, resolution_note)
  on public.repair_tickets to authenticated;
grant insert (company_id, tenancy_id, sender, staff_id, body) on public.messages to authenticated;
grant update (read_by_staff_at) on public.messages to authenticated;

-- Tables created later in public don't get Supabase's default "all to anon".
alter default privileges in schema public revoke all on tables from anon;

-- ---------------------------------------------------------------------------
-- Row-level security. (select fn()) is evaluated once per query, not per row.

alter table public.companies enable row level security;
alter table public.staff enable row level security;
alter table public.properties enable row level security;
alter table public.units enable row level security;
alter table public.tenants enable row level security;
alter table public.tenancies enable row level security;
alter table public.meter_readings enable row level security;
alter table public.payments enable row level security;
alter table public.repair_tickets enable row level security;
alter table public.messages enable row level security;
alter table public.audit_log enable row level security;

-- companies
create policy companies_read on public.companies for select to authenticated using (
  id in (select app.admin_company_ids())
  or id in (select app.caretaker_company_ids())
  or id in (select app.tenant_company_ids())
);
create policy companies_owner_update on public.companies for update to authenticated
  using (id in (select app.owner_company_ids()))
  with check (id in (select app.owner_company_ids()));

-- staff
create policy staff_read on public.staff for select to authenticated using (
  company_id in (select app.admin_company_ids())
  or user_id = auth.uid()
  -- A tenant sees only their property's manager (name for the chat header).
  or id in (select p.manager_id from public.properties p where p.id in (select app.tenant_property_ids()))
);
create policy staff_owner_insert on public.staff for insert to authenticated
  with check (company_id in (select app.owner_company_ids()));
create policy staff_owner_update on public.staff for update to authenticated
  using (company_id in (select app.owner_company_ids()))
  with check (company_id in (select app.owner_company_ids()));

-- properties
create policy properties_read on public.properties for select to authenticated using (
  company_id in (select app.admin_company_ids())
  or id in (select app.caretaker_property_ids())
  or id in (select app.tenant_property_ids())
);
create policy properties_admin_insert on public.properties for insert to authenticated
  with check (company_id in (select app.admin_company_ids()));
create policy properties_admin_update on public.properties for update to authenticated
  using (company_id in (select app.admin_company_ids()))
  with check (company_id in (select app.admin_company_ids()));

-- units
create policy units_read on public.units for select to authenticated using (
  company_id in (select app.admin_company_ids())
  or property_id in (select app.caretaker_property_ids())
  or id in (select app.tenant_unit_ids())
);
create policy units_admin_insert on public.units for insert to authenticated
  with check (company_id in (select app.admin_company_ids()));
create policy units_admin_update on public.units for update to authenticated
  using (company_id in (select app.admin_company_ids()))
  with check (company_id in (select app.admin_company_ids()));

-- tenants (phone numbers: staff who run the company, and the tenant themself)
create policy tenants_read on public.tenants for select to authenticated using (
  company_id in (select app.admin_company_ids())
  or (auth_user_id = auth.uid() and not app.password_pending())
);
create policy tenants_admin_insert on public.tenants for insert to authenticated
  with check (company_id in (select app.admin_company_ids()));
create policy tenants_admin_update on public.tenants for update to authenticated
  using (company_id in (select app.admin_company_ids()))
  with check (company_id in (select app.admin_company_ids()));

-- tenancies (money: not caretakers)
create policy tenancies_read on public.tenancies for select to authenticated using (
  company_id in (select app.admin_company_ids())
  or id in (select app.tenant_tenancy_ids())
);
create policy tenancies_admin_insert on public.tenancies for insert to authenticated
  with check (company_id in (select app.admin_company_ids()));
create policy tenancies_admin_update on public.tenancies for update to authenticated
  using (company_id in (select app.admin_company_ids()))
  with check (company_id in (select app.admin_company_ids()));

-- meter_readings
create policy meter_readings_read on public.meter_readings for select to authenticated using (
  company_id in (select app.admin_company_ids())
  or unit_id in (select u.id from public.units u where u.property_id in (select app.caretaker_property_ids()))
  or unit_id in (select app.tenant_unit_ids())
);
create policy meter_readings_staff_insert on public.meter_readings for insert to authenticated with check (
  company_id in (select app.admin_company_ids())
  or unit_id in (select u.id from public.units u where u.property_id in (select app.caretaker_property_ids()))
);
create policy meter_readings_staff_update on public.meter_readings for update to authenticated
  using (
    company_id in (select app.admin_company_ids())
    or unit_id in (select u.id from public.units u where u.property_id in (select app.caretaker_property_ids()))
  )
  with check (
    company_id in (select app.admin_company_ids())
    or unit_id in (select u.id from public.units u where u.property_id in (select app.caretaker_property_ids()))
  );

-- payments: read-only for everyone signed in; written by the service role.
create policy payments_read on public.payments for select to authenticated using (
  company_id in (select app.admin_company_ids())
  or tenancy_id in (select app.tenant_tenancy_ids())
);

-- repair_tickets
create policy repair_tickets_read on public.repair_tickets for select to authenticated using (
  company_id in (select app.admin_company_ids())
  or unit_id in (select u.id from public.units u where u.property_id in (select app.caretaker_property_ids()))
  or tenancy_id in (select app.tenant_tenancy_ids())
);
create policy repair_tickets_admin_insert on public.repair_tickets for insert to authenticated
  with check (company_id in (select app.admin_company_ids()));
-- A current tenant raises a plain request for their own unit; staff triage it.
create policy repair_tickets_tenant_insert on public.repair_tickets for insert to authenticated with check (
  tenancy_id in (select app.tenant_current_tenancy_ids())
  and priority = 'medium' and status = 'open'
  and assigned_to is null and resolved_at is null and resolution_note is null
);
create policy repair_tickets_staff_update on public.repair_tickets for update to authenticated
  using (
    company_id in (select app.admin_company_ids())
    or unit_id in (select u.id from public.units u where u.property_id in (select app.caretaker_property_ids()))
  )
  with check (
    company_id in (select app.admin_company_ids())
    or unit_id in (select u.id from public.units u where u.property_id in (select app.caretaker_property_ids()))
  );

-- messages
create policy messages_read on public.messages for select to authenticated using (
  company_id in (select app.admin_company_ids())
  or tenancy_id in (select app.tenant_tenancy_ids())
);
create policy messages_staff_insert on public.messages for insert to authenticated with check (
  company_id in (select app.admin_company_ids())
  and sender = 'staff'
  and staff_id in (select s.id from public.staff s where s.user_id = auth.uid() and s.company_id = messages.company_id)
);
create policy messages_tenant_insert on public.messages for insert to authenticated with check (
  tenancy_id in (select app.tenant_current_tenancy_ids())
  and sender = 'tenant' and staff_id is null and read_by_staff_at is null
);
create policy messages_staff_mark_read on public.messages for update to authenticated
  using (company_id in (select app.admin_company_ids()))
  with check (company_id in (select app.admin_company_ids()));

-- audit_log
create policy audit_log_read on public.audit_log for select to authenticated
  using (company_id in (select app.owner_company_ids()));

-- ---------------------------------------------------------------------------
-- One-time passwords (shared/AUTH.md, tenant journey).

-- Called by the onboarding / reset Edge Function (service role) right after it
-- sets a one-time password: until the user picks their own, they see nothing.
create function public.mark_password_pending(p_user uuid, p_hours integer default 72) returns void
language plpgsql security definer set search_path = '' as $$
begin
  insert into app.pending_passwords (user_id, password_hash, expires_at)
  select u.id, u.encrypted_password, now() + make_interval(hours => p_hours)
  from auth.users u where u.id = p_user
  on conflict (user_id) do update
    set password_hash = excluded.password_hash, expires_at = excluded.expires_at;
end $$;
revoke all on function public.mark_password_pending(uuid, integer) from public, anon, authenticated;
grant execute on function public.mark_password_pending(uuid, integer) to service_role;

-- What the app asks right after sign-in.
create function public.account_status() returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object(
    'mustChangePassword', p.user_id is not null,
    'oneTimePasswordExpired', coalesce(p.expires_at < now(), false)
  )
  from (select auth.uid() as uid) me
  left join app.pending_passwords p on p.user_id = me.uid;
$$;
revoke all on function public.account_status() from public, anon;
grant execute on function public.account_status() to authenticated;

-- Called by the app after supabase.auth.updateUser({ password }). Clears the
-- gate only if the password really changed and the one-time one hadn't expired.
create function public.complete_password_change() returns boolean
language plpgsql security definer set search_path = '' as $$
declare cleared boolean;
begin
  delete from app.pending_passwords p
   using auth.users u
   where p.user_id = auth.uid() and u.id = p.user_id
     and u.encrypted_password is distinct from p.password_hash
     and p.expires_at >= now()
  returning true into cleared;
  return coalesce(cleared, false);
end $$;
revoke all on function public.complete_password_change() from public, anon;
grant execute on function public.complete_password_change() to authenticated;

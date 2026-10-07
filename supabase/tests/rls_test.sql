-- Access-rule tests. Run after the migration and supabase/seed.sql, as the
-- database owner. Every test runs in a transaction that is rolled back, so the
-- seed is unchanged afterwards. Any failure stops the run with "FAIL: …".
--
-- Local:    see supabase/tests/run_local.sh
-- Supabase: paste into the SQL editor after seeding (skip the stub file).

\set ON_ERROR_STOP on
set client_min_messages = warning;

-- ---------------------------------------------------------------------------
-- Test helpers and demo logins

create schema tests;
grant usage on schema tests to anon, authenticated, service_role;

create table tests.users (name text primary key, id uuid not null);
insert into tests.users values
  ('hr_owner',   '00000000-0000-0000-0000-000000000001'),
  ('hr_manager', '00000000-0000-0000-0000-000000000002'),
  ('hr_caretaker', '00000000-0000-0000-0000-000000000003'),
  ('sv_owner',   '00000000-0000-0000-0000-000000000004'),
  ('david',      '00000000-0000-0000-0000-000000000005'),
  ('joseph',     '00000000-0000-0000-0000-000000000006'),
  ('naliaka',    '00000000-0000-0000-0000-000000000007'),
  ('stranger',   '00000000-0000-0000-0000-000000000008');
grant select on tests.users to anon, authenticated, service_role;

insert into auth.users (id, email, encrypted_password)
select id, name || '@test.local', 'hash-' || name from tests.users;

update public.staff s set user_id = u.id from tests.users u
 where (s.id, u.name) in (('s-owner', 'hr_owner'), ('s-njoki', 'hr_manager'), ('s-otieno', 'hr_caretaker'), ('s-sv-owner', 'sv_owner'));
update public.tenants t set auth_user_id = u.id from tests.users u
 where (t.id, u.name) in (('t-david', 'david'), ('t-joseph', 'joseph'), ('t-naliaka', 'naliaka'));

-- Sign in as a demo user for the rest of the transaction.
create function tests.login(p_name text, p_aal text default 'aal1') returns void
language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object(
    'sub', (select id from tests.users where name = p_name), 'role', 'authenticated', 'aal', p_aal)::text, true);
  execute 'set local role authenticated';
end $$;

create function tests.eq(p_sql text, p_expected bigint, p_label text) returns void
language plpgsql as $$
declare n bigint;
begin
  execute p_sql into n;
  if n is distinct from p_expected then
    raise exception 'FAIL: % (got %, expected %)', p_label, n, p_expected;
  end if;
end $$;

-- The statement must be refused (permission or access rule).
create function tests.denied(p_sql text, p_label text) returns void
language plpgsql as $$
begin
  begin
    execute p_sql;
  -- Refused by RLS, a check, or the composite keys that tie a row to its tenancy.
  exception when insufficient_privilege or check_violation or foreign_key_violation then
    return;
  end;
  raise exception 'FAIL: % was allowed', p_label;
end $$;

-- The statement runs but touches no rows (filtered out by the access rules).
create function tests.no_rows(p_sql text, p_label text) returns void
language plpgsql as $$
declare n bigint;
begin
  execute p_sql;
  get diagnostics n = row_count;
  if n <> 0 then raise exception 'FAIL: % changed % rows', p_label, n; end if;
end $$;

grant execute on all functions in schema tests to anon, authenticated, service_role;

-- What each company and demo tenant should see, counted as the owner of the
-- database (no access rules).
create table tests.expected as
  select 'companies' as tbl, id as company_id, 1::bigint as n from public.companies
  union all select 'staff', company_id, count(*) from public.staff group by 2
  union all select 'properties', company_id, count(*) from public.properties group by 2
  union all select 'units', company_id, count(*) from public.units group by 2
  union all select 'tenants', company_id, count(*) from public.tenants group by 2
  union all select 'tenancies', company_id, count(*) from public.tenancies group by 2
  union all select 'meter_readings', company_id, count(*) from public.meter_readings group by 2
  union all select 'payments', company_id, count(*) from public.payments group by 2
  union all select 'repair_tickets', company_id, count(*) from public.repair_tickets group by 2
  union all select 'messages', company_id, count(*) from public.messages group by 2;
grant select on tests.expected to authenticated;

create function tests.sees_exactly_company(p_company text) returns void
language plpgsql as $$
declare t text; want bigint;
begin
  foreach t in array array['companies', 'staff', 'properties', 'units', 'tenants', 'tenancies',
                           'meter_readings', 'payments', 'repair_tickets', 'messages'] loop
    select coalesce(sum(n), 0) into want from tests.expected where tbl = t and company_id = p_company;
    perform tests.eq(format('select count(*) from public.%I', t), want, format('%s rows for %s', t, p_company));
    perform tests.eq(format('select count(*) from public.%I where %s <> %L', t,
                            case when t = 'companies' then 'id' else 'company_id' end, p_company),
                     0, format('%s rows from another company', t));
  end loop;
end $$;
grant execute on function tests.sees_exactly_company(text) to authenticated;

-- ---------------------------------------------------------------------------
-- Not signed in: nothing at all.

begin;
set local role anon;
select tests.denied('select * from public.companies', 'anon reading companies');
select tests.denied('select * from public.payments', 'anon reading payments');
select tests.denied('select public.account_status()', 'anon calling account_status');
rollback;

-- Signed in but not linked to any company or tenancy: nothing.
begin;
select tests.login('stranger');
select tests.eq('select count(*) from public.companies', 0, 'stranger sees companies');
select tests.eq('select count(*) from public.tenancies', 0, 'stranger sees tenancies');
select tests.eq('select count(*) from public.staff', 0, 'stranger sees staff');
rollback;

-- ---------------------------------------------------------------------------
-- Owner: their whole company, nobody else's.

begin;
select tests.login('hr_owner');
select tests.sees_exactly_company('harborridge');
select tests.eq('select count(*) from public.audit_log where company_id <> ''harborridge''', 0, 'owner audit scope');
-- Settings yes; plan, sequences, and other companies no.
select tests.eq($q$with u as (update public.companies set settings = jsonb_set(settings, '{graceDay}', '21')
                where id = 'harborridge' returning 1) select count(*) from u$q$, 1, 'owner updates settings');
select tests.denied($q$update public.companies set subscription = '{}' where id = 'harborridge'$q$, 'owner changing their plan');
select tests.denied($q$update public.companies set sequences = '{}' where id = 'harborridge'$q$, 'owner resetting sequences');
select tests.no_rows($q$update public.companies set name = 'x' where id = 'savanna'$q$, 'owner updating another company');
-- Records are never deleted and payments only come from the service role.
select tests.denied($q$delete from public.tenancies where id = 'L-2160'$q$, 'owner deleting a tenancy');
select tests.denied($q$insert into public.payments (company_id, receipt_number, tenancy_id, amount, date, time, method, reference)
                     values ('harborridge', 'RCT-X', 'L-2160', 100, '2026-10-07', '10:00', 'Bank', 'X')$q$, 'owner inserting a payment');
select tests.denied($q$update public.payments set amount = 1 where tenancy_id = 'L-2160'$q$, 'owner editing a payment');
-- Can't plant rows in another company.
select tests.denied($q$insert into public.properties (company_id, manager_id, name, type, account_prefix, water_rate, garbage_fee)
                     values ('savanna', 's-sv-owner', 'Planted', 'houses', 'PL', 150, 250)$q$, 'owner adding a property to another company');
-- Can't give a login access by linking it to a staff row.
select tests.denied($q$update public.staff set user_id = gen_random_uuid() where id = 's-njoki'$q$, 'owner setting a staff login');
-- Audit trail for a move-out.
update public.tenancies set move_out = '2026-10-31' where id = 'L-2160';
select tests.eq($q$select count(*) from public.audit_log where action = 'move_out' and target = 'L-2160'
                   and actor = (select id from tests.users where name = 'hr_owner')$q$, 1, 'move-out audited with actor');
rollback;

-- MFA switch: with it on, a password-only (aal1) staff session sees nothing.
begin;
update app.settings set require_staff_mfa = true;
select tests.login('hr_owner', 'aal1');
select tests.eq('select count(*) from public.tenancies', 0, 'aal1 owner with MFA required');
reset role;
select tests.login('hr_owner', 'aal2');
select tests.eq('select count(*) from public.companies', 1, 'aal2 owner with MFA required');
rollback;

-- ---------------------------------------------------------------------------
-- Manager: same company view, but not settings, staff or the audit log.

begin;
select tests.login('hr_manager');
select tests.sees_exactly_company('harborridge');
select tests.no_rows($q$update public.companies set name = 'x' where id = 'harborridge'$q$, 'manager changing company details');
select tests.no_rows($q$update public.staff set role = 'owner' where id = 's-njoki'$q$, 'manager promoting themself');
select tests.eq('select count(*) from public.audit_log', 0, 'manager reading the audit log');
-- Manager replies in a thread as themself only.
insert into public.messages (company_id, tenancy_id, sender, staff_id, body)
values ('harborridge', 'L-2160', 'staff', 's-njoki', 'A plumber is coming at 2pm.');
select tests.denied($q$insert into public.messages (company_id, tenancy_id, sender, staff_id, body)
                     values ('harborridge', 'L-2160', 'staff', 's-owner', 'Posing as the owner')$q$, 'manager posting as someone else');
rollback;

-- Other company's owner sees only theirs.
begin;
select tests.login('sv_owner');
select tests.sees_exactly_company('savanna');
rollback;

-- ---------------------------------------------------------------------------
-- Caretaker: their properties' units, readings and repairs; no money or phones.

begin;
select tests.login('hr_caretaker');
select tests.eq('select count(*) from public.properties', 2, 'caretaker properties');
select tests.eq($q$select count(*) from public.units where property_id not in ('kilimani-heights', 'riverside-court')$q$, 0, 'caretaker units scope');
select tests.eq('select count(*) from public.tenants', 0, 'caretaker reading tenant phone numbers');
select tests.eq('select count(*) from public.tenancies', 0, 'caretaker reading rents');
select tests.eq('select count(*) from public.payments', 0, 'caretaker reading payments');
select tests.eq($q$select count(*) from public.repair_tickets where unit_id like 'mg-%'$q$, 0, 'caretaker reading another caretaker''s repairs');
insert into public.meter_readings (company_id, unit_id, month, value) values ('harborridge', 'rc-5a', '2026-11', 999);
select tests.denied($q$insert into public.meter_readings (company_id, unit_id, month, value)
                     values ('harborridge', 'mg-2', '2026-11', 999)$q$, 'caretaker reading another property''s meter');
update public.repair_tickets set status = 'in_progress', assigned_to = 's-otieno' where id = 'MT-1044';
select tests.denied($q$update public.repair_tickets set priority = 'low' where id = 'MT-1044'$q$, 'caretaker re-prioritising');
rollback;

-- ---------------------------------------------------------------------------
-- Current tenant: their own tenancy only.

begin;
select tests.login('david');
select tests.eq('select count(*) from public.companies', 1, 'tenant companies');
select tests.eq($q$select count(*) from public.companies where id <> 'harborridge'$q$, 0, 'tenant other landlord');
select tests.eq('select count(*) from public.tenancies', 1, 'tenant tenancies');
select tests.eq($q$select count(*) from public.tenancies where id <> 'L-2160'$q$, 0, 'tenant other tenancy');
select tests.eq('select count(*) from public.tenants', 1, 'tenant reads only themself');
select tests.eq('select count(*) from public.properties', 1, 'tenant properties');
select tests.eq('select count(*) from public.units', 1, 'tenant units');
select tests.eq($q$select count(*) from public.staff where id <> 's-njoki'$q$, 0, 'tenant sees only their manager');
select tests.eq($q$select count(*) from public.meter_readings where unit_id <> 'rc-5a'$q$, 0, 'tenant other meters');
select tests.eq($q$select count(*) from public.payments where tenancy_id <> 'L-2160'$q$, 0, 'tenant other payments');
select tests.eq($q$select count(*) from public.messages where tenancy_id <> 'L-2160'$q$, 0, 'tenant other threads');
select tests.eq($q$select count(*) from public.repair_tickets where tenancy_id <> 'L-2160'$q$, 0, 'tenant other repairs');
select tests.eq('select count(*) from public.audit_log', 0, 'tenant audit log');
-- Raises a request: numbered from the company's sequence, stamped now.
insert into public.repair_tickets (company_id, tenancy_id, unit_id, category, title, description)
values ('harborridge', 'L-2160', 'rc-5a', 'electrical', 'Socket sparks', 'Bedroom socket sparks when used.');
select tests.eq($q$select count(*) from public.repair_tickets where id = 'MT-1048' and created_at > now() - interval '1 minute'$q$,
                1, 'new request numbered MT-1048 and stamped now');
select tests.denied($q$insert into public.repair_tickets (company_id, tenancy_id, unit_id, category, title, priority)
                     values ('harborridge', 'L-2160', 'rc-5a', 'electrical', 'Urgent!', 'high')$q$, 'tenant setting priority');
select tests.denied($q$insert into public.repair_tickets (company_id, tenancy_id, unit_id, category, title)
                     values ('harborridge', 'L-2172', 'nr-312', 'plumbing', 'Not my unit')$q$, 'tenant raising for another tenancy');
select tests.denied($q$insert into public.repair_tickets (company_id, tenancy_id, unit_id, category, title)
                     values ('harborridge', 'L-2160', 'nr-312', 'plumbing', 'Wrong unit')$q$, 'tenant raising for another unit');
insert into public.messages (company_id, tenancy_id, sender, body) values ('harborridge', 'L-2160', 'tenant', 'Thanks!');
select tests.denied($q$insert into public.messages (company_id, tenancy_id, sender, staff_id, body)
                     values ('harborridge', 'L-2160', 'staff', 's-njoki', 'Posing as the manager')$q$, 'tenant posting as staff');
select tests.no_rows($q$update public.tenancies set rent = 1 where id = 'L-2160'$q$, 'tenant changing rent');
select tests.denied($q$insert into public.payments (company_id, receipt_number, tenancy_id, amount, date, time, method, reference)
                     values ('harborridge', 'RCT-X', 'L-2160', 100, '2026-10-07', '10:00', 'M-Pesa', 'FAKE')$q$, 'tenant inserting a payment');
select tests.no_rows($q$update public.messages set read_by_staff_at = now() where tenancy_id = 'L-2160'$q$, 'tenant marking read');
rollback;

-- ---------------------------------------------------------------------------
-- Former tenant: read-only, then nothing after the retention period.

begin;
select tests.login('joseph');
select tests.eq('select count(*) from public.tenancies', 1, 'former tenant still sees records');
select tests.denied($q$insert into public.repair_tickets (company_id, tenancy_id, unit_id, category, title)
                     values ('harborridge', 'L-2071', 'rc-2a', 'plumbing', 'After move-out')$q$, 'former tenant raising a repair');
select tests.denied($q$insert into public.messages (company_id, tenancy_id, sender, body)
                     values ('harborridge', 'L-2071', 'tenant', 'After move-out')$q$, 'former tenant messaging');
rollback;

begin;
update public.tenancies set move_out = '2026-01-31' where id = 'L-2071';
select tests.login('joseph');
select tests.eq('select count(*) from public.tenancies', 0, 'former tenant past retention');
select tests.eq('select count(*) from public.payments', 0, 'former tenant payments past retention');
rollback;

-- ---------------------------------------------------------------------------
-- One-time password: nothing until the tenant picks their own.

begin;
select public.mark_password_pending((select id from tests.users where name = 'naliaka'));
select tests.login('naliaka');
select tests.eq('select count(*) from public.tenancies', 0, 'pending tenant tenancies');
select tests.eq('select count(*) from public.tenants', 0, 'pending tenant profile');
select tests.eq($q$select count(*) from (select public.account_status() s) x where (s ->> 'mustChangePassword')::boolean$q$, 1, 'account_status');
select tests.eq($q$select count(*) from (select public.complete_password_change() ok) x where ok$q$, 0, 'clearing gate without changing password');
reset role;
update auth.users set encrypted_password = 'hash-new' where id = (select id from tests.users where name = 'naliaka');
select tests.login('naliaka');
select tests.eq($q$select count(*) from (select public.complete_password_change() ok) x where ok$q$, 1, 'clearing gate after change');
select tests.eq('select count(*) from public.tenancies', 1, 'tenant after password change');
rollback;

-- Expired one-time password can't be cleared; the manager issues a new one.
begin;
select public.mark_password_pending((select id from tests.users where name = 'naliaka'));
-- now() is fixed within a transaction, so put the expiry in the past.
update app.pending_passwords set expires_at = now() - interval '1 minute'
 where user_id = (select id from tests.users where name = 'naliaka');
update auth.users set encrypted_password = 'hash-new' where id = (select id from tests.users where name = 'naliaka');
select tests.login('naliaka');
select tests.eq($q$select count(*) from (select public.complete_password_change() ok) x where ok$q$, 0, 'expired one-time password');
rollback;

-- Only the service role can set the gate.
begin;
select tests.login('david');
select tests.denied($q$select public.mark_password_pending(auth.uid())$q$, 'tenant calling mark_password_pending');
rollback;

-- ---------------------------------------------------------------------------
-- Integrity: a child row can't point at another company's parent.

begin;
do $$ begin
  begin
    insert into public.units (company_id, property_id, label, bedrooms) values ('savanna', 'kilimani-heights', 'X1', 1);
    raise exception 'FAIL: unit attached to another company''s property';
  exception when foreign_key_violation then null;
  end;
  begin
    insert into public.tenancies (company_id, tenant_id, unit_id, rent, deposit, move_in, lease_start, lease_end)
    values ('harborridge', 't-naliaka', 'rc-5a', 1000, 0, '2026-11-01', '2026-11-01', '2027-10-31');
    raise exception 'FAIL: tenancy for another company''s tenant';
  exception when foreign_key_violation or unique_violation then null;
  end;
end $$;
rollback;

-- Service role (M-Pesa callback): receipt numbered from the sequence; a
-- retried callback with the same transaction code is rejected.
begin;
set local role service_role;
insert into public.payments (company_id, tenancy_id, amount, date, time, method, reference)
values ('harborridge', 'L-2160', 5000, '2026-10-07', '10:15', 'M-Pesa', 'TEST123ABC');
select tests.eq($q$select count(*) from public.payments where receipt_number = 'RCT-2610-0380'$q$, 1, 'receipt numbered RCT-2610-0380');
do $$ begin
  insert into public.payments (company_id, tenancy_id, amount, date, time, method, reference)
  values ('harborridge', 'L-2160', 5000, '2026-10-07', '10:15', 'M-Pesa', 'TEST123ABC');
  raise exception 'FAIL: duplicate M-Pesa callback recorded twice';
exception when unique_violation then null;
end $$;
rollback;

drop schema tests cascade;
select 'All access-rule tests passed' as result;

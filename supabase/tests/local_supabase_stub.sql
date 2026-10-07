-- Only for testing on a plain Postgres (no Supabase): the bits of Supabase the
-- migration relies on. A real Supabase project already has all of this.
--   psql -f supabase/tests/local_supabase_stub.sql -f supabase/migrations/*.sql \
--        -f supabase/seed.sql -f supabase/tests/rls_test.sql

create role anon nologin noinherit;
create role authenticated nologin noinherit;
create role service_role nologin noinherit bypassrls;

create schema auth;
create table auth.users (
  id uuid primary key,
  email text,
  phone text,
  encrypted_password text,
  raw_app_meta_data jsonb not null default '{}'
);
-- Supabase reads the caller's verified JWT claims from this setting.
create function auth.jwt() returns jsonb language sql stable as $$
  select coalesce(nullif(current_setting('request.jwt.claims', true), ''), '{}')::jsonb
$$;
create function auth.uid() returns uuid language sql stable as $$
  select nullif(auth.jwt() ->> 'sub', '')::uuid
$$;
grant usage on schema auth to anon, authenticated, service_role;
grant usage on schema public to anon, authenticated, service_role;

-- Supabase's defaults: the API roles get everything in public; RLS decides.
alter default privileges in schema public grant all on tables to anon, authenticated, service_role;
alter default privileges in schema public grant all on functions to anon, authenticated, service_role;
alter default privileges in schema public grant all on sequences to anon, authenticated, service_role;

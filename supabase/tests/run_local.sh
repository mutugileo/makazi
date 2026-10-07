#!/usr/bin/env bash
# Applies the migration and seed to a throwaway local Postgres database and
# runs the access-rule tests. Needs psql and a running Postgres (any 14+).
#   PGHOST=127.0.0.1 PGPORT=5432 PGUSER=postgres supabase/tests/run_local.sh
set -euo pipefail
cd "$(dirname "$0")/.."
DB=makazi_rls_test
psql -v ON_ERROR_STOP=1 -q -d postgres -c "drop database if exists $DB" -c "create database $DB"
# Roles are cluster-wide; ignore "already exists" from an earlier run.
psql -q -d postgres -c "create role anon nologin noinherit" 2>/dev/null || true
psql -q -d postgres -c "create role authenticated nologin noinherit" 2>/dev/null || true
psql -q -d postgres -c "create role service_role nologin noinherit bypassrls" 2>/dev/null || true
grep -v '^create role' tests/local_supabase_stub.sql | psql -v ON_ERROR_STOP=1 -q -d $DB
for f in migrations/*.sql; do psql -v ON_ERROR_STOP=1 -q -d $DB -f "$f"; done
psql -v ON_ERROR_STOP=1 -q -d $DB -f seed.sql
psql -v ON_ERROR_STOP=1 -q -d $DB -f tests/rls_test.sql
psql -q -d postgres -c "drop database $DB"

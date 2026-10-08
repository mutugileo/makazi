-- In-app notifications for tenants, starting with payment reminders sent
-- from the admin (Arrears → Send reminders). SMS and email are not used: no
-- per-message cost. The app shows unread ones on Home and pops one up when
-- it arrives while the app is open.

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  company_id text not null references public.companies (id),
  tenancy_id text not null,
  kind text not null check (kind in ('payment_reminder')),
  title text not null check (length(title) between 1 and 120),
  body text not null check (length(body) between 1 and 1000),
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  read_at timestamptz,
  foreign key (company_id, tenancy_id) references public.tenancies (company_id, id)
);

create index notifications_company_tenancy_idx
  on public.notifications (company_id, tenancy_id, created_at desc);

alter table public.notifications enable row level security;

-- Staff who run the company see what was sent; the tenant sees their own.
create policy notifications_read on public.notifications for select to authenticated using (
  company_id in (select app.admin_company_ids())
  or tenancy_id in (select app.tenant_tenancy_ids())
);

-- Sent by staff (the admin site writes with its server key today; this
-- covers signed-in staff sessions later).
create policy notifications_staff_insert on public.notifications for insert to authenticated
  with check (company_id in (select app.admin_company_ids()));

-- The tenant marks their own as read, and nothing else.
create policy notifications_tenant_mark_read on public.notifications for update to authenticated
  using (tenancy_id in (select app.tenant_tenancy_ids()))
  with check (tenancy_id in (select app.tenant_tenancy_ids()));

revoke all on public.notifications from anon, authenticated;
grant select on public.notifications to authenticated;
grant insert (company_id, tenancy_id, kind, title, body) on public.notifications to authenticated;
grant update (read_at) on public.notifications to authenticated;

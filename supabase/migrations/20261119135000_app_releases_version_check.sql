-- Remote app version config so PropMgtApp checks the live production
-- version in Supabase instead of hardcoding build numbers in the client.
create table if not exists public.app_releases (
  platform text primary key check (platform in ('android', 'ios')),
  latest_version text not null,
  latest_build_number integer not null check (latest_build_number > 0),
  min_supported_build_number integer not null default 1 check (min_supported_build_number > 0),
  release_notes jsonb not null default '[]'::jsonb,
  release_date text not null default '',
  store_url text not null,
  updated_at timestamptz not null default now()
);

alter table public.app_releases enable row level security;
revoke all on public.app_releases from anon, authenticated;
grant select on public.app_releases to anon, authenticated;

drop policy if exists app_releases_read on public.app_releases;
create policy app_releases_read on public.app_releases
  for select to anon, authenticated
  using (true);

insert into public.app_releases (
  platform,
  latest_version,
  latest_build_number,
  min_supported_build_number,
  release_notes,
  release_date,
  store_url
) values (
  'android',
  '1.0.11',
  11,
  8,
  '[
    "Paste M-Pesa or bank confirmation messages to confirm rent payments faster",
    "Edit or delete rejected payment confirmation messages",
    "Paginated bills and payment receipts for faster scrolling",
    "In-app notification pop-ups for payment confirmations and reminders",
    "Improved offline connection recovery"
  ]'::jsonb,
  '19 Nov 2026',
  'https://play.google.com/store/apps/details?id=com.codzure.makazi'
)
on conflict (platform) do update set
  latest_version = excluded.latest_version,
  latest_build_number = excluded.latest_build_number,
  min_supported_build_number = excluded.min_supported_build_number,
  release_notes = excluded.release_notes,
  release_date = excluded.release_date,
  store_url = excluded.store_url,
  updated_at = now();

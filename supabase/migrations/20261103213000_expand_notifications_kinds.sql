-- Migration: Expand notification kinds to support in-app messages and general alerts
alter table public.notifications drop constraint if exists notifications_kind_check;
alter table public.notifications add constraint notifications_kind_check check (kind in ('payment_reminder', 'message', 'pin_reset', 'general'));


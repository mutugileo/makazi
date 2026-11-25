-- Revoke non-RLS table privileges on property_enquiries from authenticated
-- and convert account_status() stub to SECURITY INVOKER.
revoke truncate, references, trigger on public.property_enquiries from authenticated;
alter function public.account_status() security invoker;

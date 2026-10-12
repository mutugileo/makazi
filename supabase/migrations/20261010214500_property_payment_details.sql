-- Property-level payment details.
-- When configured, tenants in the property use these M-Pesa and bank details
-- instead of falling back to company-wide defaults.

alter table public.properties
  add column if not exists mpesa_paybill text,
  add column if not exists bank_name text,
  add column if not exists bank_account text;

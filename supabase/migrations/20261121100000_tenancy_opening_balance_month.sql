-- A spreadsheet opening balance is what the tenant owes on the day of the
-- import. Billing must start at that cycle; charging rent for the months
-- between the company's ledger start and the import double-counts arrears.
alter table public.tenancies
  add column if not exists opening_balance_month text
    check (opening_balance_month ~ '^\d{4}-(0[1-9]|1[0-2])$');

comment on column public.tenancies.opening_balance_month is
  'Cycle (YYYY-MM) the opening balance was taken at; billing starts here. Null: the company ledgerStartMonth.';

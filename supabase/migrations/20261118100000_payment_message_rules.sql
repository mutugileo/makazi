-- More checks that a pasted message is a payment confirmation, on top of the
-- reference and amount submit_payment_claim and update_payment_claim require.
-- A trigger, so sending and editing are both covered; staff reviews don't
-- change the message and skip it.
create or replace function app.check_payment_claim_message()
returns trigger
language plpgsql set search_path = '' as $$
declare
  v_today date := (now() at time zone 'Africa/Nairobi')::date;
begin
  if tg_op = 'UPDATE' and new.message is not distinct from old.message then
    return new;
  end if;

  -- Typed text with a code and an amount isn't a confirmation.
  if new.message !~* '\m(confirmed|received|sent|paid|successful|completed)\M' then
    raise exception 'This doesn''t look like a payment confirmation. Paste the message you got from M-Pesa or your bank.'
      using errcode = '22023';
  end if;

  if new.paid_date is not null and new.paid_date > v_today + 1 then
    raise exception 'The date in this message is in the future. Check you pasted the right message.'
      using errcode = '22023';
  end if;
  if new.paid_date is not null and new.paid_date < v_today - 90 then
    raise exception 'That payment is from %, more than 90 days ago. Ask your manager to record it.',
      to_char(new.paid_date, 'DD Mon YYYY')
      using errcode = '22023';
  end if;

  return new;
end $$;

revoke all on function app.check_payment_claim_message() from public;

drop trigger if exists payment_claims_check_message on public.payment_claims;
create trigger payment_claims_check_message
  before insert or update of message on public.payment_claims
  for each row execute function app.check_payment_claim_message();

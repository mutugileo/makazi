import 'package:flutter_test/flutter_test.dart';
import 'package:prop_mgt_app/core/billing/payment_message_validator.dart';

void main() {
  test('accepts M-Pesa and bank confirmations', () {
    expect(
      validatePaymentMessage(
        'Confirmed. You have received KES 31200.00 for Account 404020 from '
        'AUGUSTINE MUSA. # Mpesa Ref:UKA1D18L3S on 10-11-2026 13:34Hrs',
      ),
      isNull,
    );
    expect(
      validatePaymentMessage(
        'UKA1D18L3S Confirmed. Ksh31,200.00 sent to THE PHOENIX for account '
        '404020 on 10/11/26 at 1:34 PM',
      ),
      isNull,
    );
  });

  test('refuses typed text with a code and an amount', () {
    expect(
      validatePaymentMessage(
        'my rent TST9Z8Y7X6 KES 5000 for this month please',
      ),
      contains("doesn't look like a payment confirmation"),
    );
  });

  test('refuses a confirmation without a reference or amount', () {
    expect(
      validatePaymentMessage(
        'Confirmed. You have received money from a friend',
      ),
      contains('including the reference and amount'),
    );
  });
}

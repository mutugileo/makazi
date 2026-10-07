import 'package:flutter/foundation.dart';
import '../billing/billing_engine.dart';

@immutable
class PaymentReceipt {
  const PaymentReceipt({
    required this.receiptNumber,
    required this.companyName,
    required this.kraPin,
    required this.amount,
    required this.tenantName,
    required this.unit,
    required this.date,
    required this.time,
    required this.method,
    required this.reference,
    required this.forDescription,
    required this.billMonth,
  });

  final String receiptNumber;
  final String companyName;
  final String kraPin;

  /// Whole Kenyan shillings.
  final int amount;
  final String tenantName;
  final String unit;

  /// ISO date, e.g. '2026-10-02'.
  final String date;

  /// 'HH:mm', Nairobi time.
  final String time;
  final String method;
  final String reference;
  final String forDescription;

  /// The bill this payment counted towards ('YYYY-MM').
  final String billMonth;

  String get id => receiptNumber;
  String get amountLabel => formatKes(amount);
  String get dateLabel => BillingDates.formatDate(date);

  /// '02 Oct 2026, 08:14', as on the admin's receipt.
  String get dateTimeLabel => '$dateLabel, $time';
  String get initial => method.substring(0, 1);

  @override
  bool operator ==(Object other) =>
      other is PaymentReceipt && other.receiptNumber == receiptNumber;

  @override
  int get hashCode => receiptNumber.hashCode;
}

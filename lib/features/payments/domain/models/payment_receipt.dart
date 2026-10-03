import 'package:flutter/foundation.dart';

@immutable
class PaymentReceipt {
  const PaymentReceipt({
    required this.id,
    required this.receiptNumber,
    required this.companyName,
    required this.kraPin,
    required this.amount,
    required this.tenantName,
    required this.unit,
    required this.date,
    required this.method,
    required this.reference,
    required this.forDescription,
    required this.initial,
  });

  final String id;
  final String receiptNumber;
  final String companyName;
  final String kraPin;
  final String amount;
  final String tenantName;
  final String unit;
  final String date;
  final String method;
  final String reference;
  final String forDescription;
  final String initial;
}

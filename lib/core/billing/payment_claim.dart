import 'package:flutter/foundation.dart';

enum PaymentClaimStatus {
  pending('pending'),
  confirmed('confirmed'),
  rejected('rejected');

  const PaymentClaimStatus(this.wire);
  final String wire;

  static PaymentClaimStatus fromWire(String value) =>
      values.firstWhere((s) => s.wire == value);
}

/// A payment confirmation message the tenant pasted for the manager to check
/// against their statement (public.payment_claims). It never changes the
/// balance by itself: confirming it records the payment and its receipt.
@immutable
class PaymentClaim {
  const PaymentClaim({
    required this.id,
    required this.status,
    required this.createdAt,
    this.message,
    this.reference,
    this.amount,
    this.reviewNote,
  });

  final String id;
  final PaymentClaimStatus status;

  /// Nairobi time, 'YYYY-MM-DDTHH:MM:SS+03:00'.
  final String createdAt;

  /// Original confirmation text pasted by the tenant.
  final String? message;

  /// Read from the message; null when it couldn't be read.
  final String? reference;
  final int? amount;

  /// Why the manager didn't confirm it.
  final String? reviewNote;
}

/// The database refused a payment message, with a reason to show the tenant.
class PaymentClaimRefused implements Exception {
  const PaymentClaimRefused(this.message);

  final String message;

  @override
  String toString() => message;
}

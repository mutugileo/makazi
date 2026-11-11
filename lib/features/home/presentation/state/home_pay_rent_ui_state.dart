import 'package:flutter/foundation.dart';
import '../../../../core/billing/payment_claim.dart';

/// The Pay rent sheet: payment details, and a field for the confirmation
/// message the tenant got from M-Pesa or the bank.
@immutable
class HomePayRentUiState {
  const HomePayRentUiState({
    this.isOpen = false,
    this.message = '',
    this.isSending = false,
    this.errorText,
    this.sentClaim,
  });

  final bool isOpen;

  /// What the tenant pasted.
  final String message;
  final bool isSending;

  /// Why the message wasn't accepted.
  final String? errorText;

  /// Set once the message reached the manager.
  final PaymentClaim? sentClaim;

  bool get canSend => !isSending && message.trim().isNotEmpty;

  HomePayRentUiState copyWith({
    String? message,
    bool? isSending,
    ValueGetter<String?>? errorText,
    ValueGetter<PaymentClaim?>? sentClaim,
  }) {
    return HomePayRentUiState(
      isOpen: isOpen,
      message: message ?? this.message,
      isSending: isSending ?? this.isSending,
      errorText: errorText != null ? errorText() : this.errorText,
      sentClaim: sentClaim != null ? sentClaim() : this.sentClaim,
    );
  }
}

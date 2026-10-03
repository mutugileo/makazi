import 'package:flutter/foundation.dart';
import '../../domain/models/payment_receipt.dart';

@immutable
class PaymentsUiState {
  const PaymentsUiState({required this.receipts, this.selectedReceipt});

  final List<PaymentReceipt> receipts;
  final PaymentReceipt? selectedReceipt;

  PaymentsUiState copyWith({
    List<PaymentReceipt>? receipts,
    PaymentReceipt? Function()? selectedReceipt,
  }) {
    return PaymentsUiState(
      receipts: receipts ?? this.receipts,
      selectedReceipt: selectedReceipt != null
          ? selectedReceipt()
          : this.selectedReceipt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentsUiState &&
          runtimeType == other.runtimeType &&
          listEquals(receipts, other.receipts) &&
          selectedReceipt == other.selectedReceipt;

  @override
  int get hashCode => Object.hash(receipts, selectedReceipt);
}

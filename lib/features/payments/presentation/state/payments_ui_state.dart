import 'package:flutter/foundation.dart';
import '../../domain/models/payment_receipt.dart';

enum PaymentsView { bills, receipts }

@immutable
class PaymentsUiState {
  const PaymentsUiState({
    this.view = PaymentsView.bills,
    this.selectedBillMonth,
    this.selectedReceipt,
    this.showingStatement = false,
  });

  final PaymentsView view;

  /// 'YYYY-MM' of the bill being viewed.
  final String? selectedBillMonth;
  final PaymentReceipt? selectedReceipt;
  final bool showingStatement;

  PaymentsUiState copyWith({
    PaymentsView? view,
    String? Function()? selectedBillMonth,
    PaymentReceipt? Function()? selectedReceipt,
    bool? showingStatement,
  }) {
    return PaymentsUiState(
      view: view ?? this.view,
      selectedBillMonth: selectedBillMonth != null
          ? selectedBillMonth()
          : this.selectedBillMonth,
      selectedReceipt: selectedReceipt != null
          ? selectedReceipt()
          : this.selectedReceipt,
      showingStatement: showingStatement ?? this.showingStatement,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentsUiState &&
          view == other.view &&
          selectedBillMonth == other.selectedBillMonth &&
          selectedReceipt == other.selectedReceipt &&
          showingStatement == other.showingStatement;

  @override
  int get hashCode =>
      Object.hash(view, selectedBillMonth, selectedReceipt, showingStatement);
}

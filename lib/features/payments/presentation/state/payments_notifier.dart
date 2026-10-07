import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/payment_receipt.dart';
import 'payments_ui_state.dart';

/// Navigation state for the Payments tab. Bills and receipts themselves come
/// from tenantAccountProvider.
class PaymentsNotifier extends Notifier<PaymentsUiState> {
  @override
  PaymentsUiState build() {
    return const PaymentsUiState();
  }

  void showView(PaymentsView view) {
    if (state.view == view) return;
    state = state.copyWith(view: view);
  }

  void selectBill(String month) {
    state = state.copyWith(
      view: PaymentsView.bills,
      selectedBillMonth: () => month,
      selectedReceipt: () => null,
    );
  }

  void clearSelectedBill() {
    if (state.selectedBillMonth == null) return;
    state = state.copyWith(selectedBillMonth: () => null);
  }

  void selectReceipt(PaymentReceipt receipt) {
    if (state.selectedReceipt == receipt) {
      return;
    }
    state = state.copyWith(selectedReceipt: () => receipt);
  }

  void clearSelectedReceipt() {
    if (state.selectedReceipt == null) {
      return;
    }
    state = state.copyWith(selectedReceipt: () => null);
  }

  void showStatement() => state = state.copyWith(showingStatement: true);

  void closeStatement() => state = state.copyWith(showingStatement: false);

  /// Back to the top of the tab (used when arriving from Home).
  void resetToList(PaymentsView view) {
    state = PaymentsUiState(view: view);
  }
}

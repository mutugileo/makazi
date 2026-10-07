import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/billing/billing_models.dart';
import '../../../../core/data/data_mode.dart';
import '../../../billing/presentation/state/tenant_account_providers.dart';
import '../../domain/models/pay_rent_models.dart';
import 'home_pay_rent_ui_state.dart';

class HomePayRentNotifier extends Notifier<HomePayRentUiState> {
  @override
  HomePayRentUiState build() {
    return const HomePayRentUiState.initial();
  }

  void openPayRent() {
    final balance = ref.read(tenantAccountProvider).balance;
    state = state.copyWith(
      isPayRentOpen: true,
      fullBalance: balance > 0 ? balance : 0,
      amountOption: balance > 0
          ? PayRentAmountOption.fullBalance
          : PayRentAmountOption.other,
      otherAmountText: '',
      step: PayRentStep.form,
      completedReceipt: () => null,
      showingReceiptDetail: false,
    );
  }

  void closePayRent() {
    if (state.step == PayRentStep.confirming) return;
    state = state.copyWith(
      isPayRentOpen: false,
      showingReceiptDetail: false,
      step: PayRentStep.form,
    );
  }

  void selectAmountOption(PayRentAmountOption option) {
    if (state.amountOption == option) {
      return;
    }
    state = state.copyWith(amountOption: option);
  }

  void updateOtherAmount(String digits) {
    state = state.copyWith(otherAmountText: digits);
  }

  void selectPaymentMethod(PayRentMethod method) {
    if (state.paymentMethod == method) {
      return;
    }
    state = state.copyWith(paymentMethod: method);
  }

  /// Demo build only: simulates the STK push and records the payment
  /// locally. The live app shows Paybill details instead and never writes
  /// payments (they come from the manager or M-Pesa).
  Future<void> submitPayment() async {
    if (!state.canSubmit ||
        state.paymentMethod != PayRentMethod.mpesa ||
        ref.read(liveDataProvider)) {
      return;
    }
    final amount = state.amountValue;
    state = state.copyWith(step: PayRentStep.confirming);

    // Stand-in for the STK push round trip.
    await Future<void>.delayed(const Duration(milliseconds: 1800));
    if (!ref.mounted) return;

    final now = DateTime.now();
    final receipt = ref
        .read(tenantAccountProvider.notifier)
        .recordPayment(
          amount: amount,
          method: PaymentMethod.mpesa,
          reference: _demoMpesaReference(now),
          time:
              '${now.hour.toString().padLeft(2, '0')}:'
              '${now.minute.toString().padLeft(2, '0')}',
        );

    state = state.copyWith(
      step: PayRentStep.received,
      completedReceipt: () => receipt,
    );
  }

  void viewCompletedReceipt() {
    state = state.copyWith(showingReceiptDetail: true);
  }

  void closeReceiptDetail() {
    state = state.copyWith(showingReceiptDetail: false);
  }

  void finishPayRent() {
    state = state.copyWith(
      isPayRentOpen: false,
      showingReceiptDetail: false,
      step: PayRentStep.form,
    );
  }

  static String _demoMpesaReference(DateTime now) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ0123456789';
    var seed = now.microsecondsSinceEpoch;
    final buffer = StringBuffer('SK');
    for (var i = 0; i < 8; i++) {
      buffer.write(chars[seed % chars.length]);
      seed ~/= chars.length;
    }
    return buffer.toString();
  }
}

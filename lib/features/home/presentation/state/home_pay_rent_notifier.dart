import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/billing/billing_models.dart';
import '../../../../core/data/data_mode.dart';
import '../../../../core/data/supabase_billing_providers.dart';
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
      errorText: () => null,
      promptShown: false,
    );
  }

  void closePayRent() {
    if (state.step == PayRentStep.confirming) return;
    if (state.step == PayRentStep.awaitingApproval) {
      declineMpesaPush();
      return;
    }
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

  /// Whether "Pay now" runs the M-Pesa STK push here: always in the demo
  /// build; in the live app only while the company has M-Pesa test mode on
  /// (otherwise the tenant pays from the Paybill details).
  bool get canPushMpesa =>
      !ref.read(liveDataProvider) ||
      ref.read(tenantAccountProvider).company.settings.mpesaSimulation;

  /// "Pay now": sends the M-Pesa request to the tenant's phone. A moment
  /// later the prompt arrives and waits for [approveMpesaPush] or
  /// [declineMpesaPush], as the real STK prompt waits for the tenant.
  Future<void> submitPayment() async {
    if (!state.canSubmit ||
        state.paymentMethod != PayRentMethod.mpesa ||
        !canPushMpesa) {
      return;
    }
    state = state.copyWith(
      step: PayRentStep.awaitingApproval,
      promptShown: false,
      errorText: () => null,
    );
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!ref.mounted || state.step != PayRentStep.awaitingApproval) return;
    state = state.copyWith(promptShown: true);
  }

  /// The tenant turned the request down on their phone: nothing is paid.
  void declineMpesaPush() {
    if (state.step != PayRentStep.awaitingApproval) return;
    state = state.copyWith(
      step: PayRentStep.form,
      promptShown: false,
      errorText: () => 'You declined the M-Pesa request. Nothing was paid.',
    );
  }

  /// The tenant approved on their phone. Demo build: recorded on this phone.
  /// Live (M-Pesa test mode): the database records a flagged test payment,
  /// and the receipt shows only once that has been saved.
  Future<void> approveMpesaPush() async {
    if (state.step != PayRentStep.awaitingApproval || !state.promptShown) {
      return;
    }
    final amount = state.amountValue;
    state = state.copyWith(step: PayRentStep.confirming, promptShown: false);

    if (ref.read(liveDataProvider)) {
      final String receiptNumber;
      try {
        receiptNumber = await ref
            .read(supabaseBillingRepositoryProvider)
            .simulateMpesaPayment(amount);
      } catch (error) {
        if (!ref.mounted) return;
        state = state.copyWith(
          step: PayRentStep.form,
          errorText: () => _failureMessage(error),
        );
        return;
      }
      final account = ref.read(tenantAccountProvider.notifier);
      await account.refreshFromDatabase();
      if (!ref.mounted) return;
      final receipt = ref
          .read(tenantAccountProvider)
          .receipts
          .where((r) => r.receiptNumber == receiptNumber)
          .firstOrNull;
      state = state.copyWith(
        step: PayRentStep.received,
        completedReceipt: () => receipt,
      );
      return;
    }

    // Demo build: stand-in for the M-Pesa round trip, recorded locally.
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

  static String _failureMessage(Object error) {
    final text = error.toString();
    if (text.contains('test mode is off')) {
      return 'M-Pesa test mode was turned off. Pay from the Paybill details instead.';
    }
    if (text.contains('Too many test payments')) {
      return 'That\'s the most test payments for today. Try again tomorrow.';
    }
    return 'The payment didn\'t go through. Nothing was recorded; try again.';
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

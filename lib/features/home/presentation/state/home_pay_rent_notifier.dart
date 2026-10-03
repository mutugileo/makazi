import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/payment_receipt.dart';
import '../../domain/models/pay_rent_models.dart';
import 'home_pay_rent_ui_state.dart';

class HomePayRentNotifier extends Notifier<HomePayRentUiState> {
  @override
  HomePayRentUiState build() {
    return const HomePayRentUiState.initial();
  }

  void openPayRent() {
    state = state.copyWith(
      isPayRentOpen: true,
      step: PayRentStep.form,
      showingReceiptDetail: false,
    );
  }

  void closePayRent() {
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

  void selectPaymentMethod(PayRentMethod method) {
    if (state.paymentMethod == method) {
      return;
    }
    state = state.copyWith(paymentMethod: method);
  }

  void updateMpesaNumber(String number) {
    state = state.copyWith(mpesaNumber: number);
  }

  Future<void> submitPayment() async {
    state = state.copyWith(step: PayRentStep.confirming);

    await Future<void>.delayed(const Duration(milliseconds: 1800));

    final isHalf = state.amountOption == PayRentAmountOption.half;
    final receipt = PaymentReceipt(
      id: 'rcpt-new-${DateTime.now().millisecondsSinceEpoch}',
      receiptNumber: 'RCT-2610-0423',
      companyName: 'Jengo Property Management',
      kraPin: 'P051234567X',
      amount: isHalf ? 'KES 22,500' : 'KES 45,000',
      tenantName: 'David Mwangi',
      unit: '5A · Riverside Court',
      date: '01 Oct 2026',
      method: state.paymentMethod == PayRentMethod.mpesa ? 'M-Pesa' : 'Bank',
      reference: 'SJAEEMDE4J',
      forDescription: isHalf
          ? 'Rent, October 2026 (part)'
          : 'Rent, October 2026 (balance)',
      initial: state.paymentMethod == PayRentMethod.mpesa ? 'M' : 'B',
    );

    state = state.copyWith(
      step: PayRentStep.received,
      completedReceipt: () => receipt,
      isBalancePaid: !isHalf,
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
}

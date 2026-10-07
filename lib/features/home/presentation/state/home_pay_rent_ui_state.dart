import 'package:flutter/foundation.dart';
import '../../../../core/billing/billing_engine.dart';
import '../../../../core/models/payment_receipt.dart';
import '../../domain/models/pay_rent_models.dart';

@immutable
class HomePayRentUiState {
  const HomePayRentUiState({
    required this.isPayRentOpen,
    required this.fullBalance,
    required this.amountOption,
    required this.otherAmountText,
    required this.paymentMethod,
    required this.step,
    required this.completedReceipt,
    required this.showingReceiptDetail,
  });

  const HomePayRentUiState.initial()
    : isPayRentOpen = false,
      fullBalance = 0,
      amountOption = PayRentAmountOption.fullBalance,
      otherAmountText = '',
      paymentMethod = PayRentMethod.mpesa,
      step = PayRentStep.form,
      completedReceipt = null,
      showingReceiptDetail = false;

  final bool isPayRentOpen;

  /// Outstanding balance when the flow was opened.
  final int fullBalance;
  final PayRentAmountOption amountOption;
  final String otherAmountText;
  final PayRentMethod paymentMethod;
  final PayRentStep step;
  final PaymentReceipt? completedReceipt;
  final bool showingReceiptDetail;

  int get amountValue => switch (amountOption) {
    PayRentAmountOption.fullBalance => fullBalance,
    PayRentAmountOption.other => int.tryParse(otherAmountText) ?? 0,
  };

  String get amountFormatted => formatKes(amountValue);

  /// Why the current amount can't be paid, or null when it can.
  String? get amountError {
    if (amountValue <= 0) return 'Enter an amount to pay';
    if (paymentMethod == PayRentMethod.mpesa &&
        amountValue > kMpesaMaxPerTransaction) {
      return 'M-Pesa takes up to ${formatKes(kMpesaMaxPerTransaction)} per payment';
    }
    return null;
  }

  /// Amount above the balance that will carry forward as credit.
  int get creditAfterPayment =>
      amountValue > fullBalance ? amountValue - fullBalance : 0;

  bool get canSubmit => step == PayRentStep.form && amountError == null;

  HomePayRentUiState copyWith({
    bool? isPayRentOpen,
    int? fullBalance,
    PayRentAmountOption? amountOption,
    String? otherAmountText,
    PayRentMethod? paymentMethod,
    PayRentStep? step,
    ValueGetter<PaymentReceipt?>? completedReceipt,
    bool? showingReceiptDetail,
  }) {
    return HomePayRentUiState(
      isPayRentOpen: isPayRentOpen ?? this.isPayRentOpen,
      fullBalance: fullBalance ?? this.fullBalance,
      amountOption: amountOption ?? this.amountOption,
      otherAmountText: otherAmountText ?? this.otherAmountText,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      step: step ?? this.step,
      completedReceipt: completedReceipt != null
          ? completedReceipt()
          : this.completedReceipt,
      showingReceiptDetail: showingReceiptDetail ?? this.showingReceiptDetail,
    );
  }
}

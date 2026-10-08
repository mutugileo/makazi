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
    this.errorText,
    this.promptShown = false,
  });

  const HomePayRentUiState.initial()
    : isPayRentOpen = false,
      fullBalance = 0,
      amountOption = PayRentAmountOption.fullBalance,
      otherAmountText = '',
      paymentMethod = PayRentMethod.mpesa,
      step = PayRentStep.form,
      completedReceipt = null,
      showingReceiptDetail = false,
      errorText = null,
      promptShown = false;

  final bool isPayRentOpen;

  /// Outstanding balance when the flow was opened.
  final int fullBalance;
  final PayRentAmountOption amountOption;
  final String otherAmountText;
  final PayRentMethod paymentMethod;
  final PayRentStep step;
  final PaymentReceipt? completedReceipt;
  final bool showingReceiptDetail;

  /// Why the last M-Pesa request didn't go through (declined, failed).
  final String? errorText;

  /// The M-Pesa request has reached the phone and is waiting for the tenant.
  final bool promptShown;

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
    ValueGetter<String?>? errorText,
    bool? promptShown,
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
      errorText: errorText != null ? errorText() : this.errorText,
      promptShown: promptShown ?? this.promptShown,
    );
  }
}

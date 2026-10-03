import 'package:flutter/foundation.dart';
import '../../../../core/models/payment_receipt.dart';
import '../../domain/models/pay_rent_models.dart';

@immutable
class HomePayRentUiState {
  const HomePayRentUiState({
    required this.isPayRentOpen,
    required this.amountOption,
    required this.paymentMethod,
    required this.mpesaNumber,
    required this.step,
    required this.completedReceipt,
    required this.showingReceiptDetail,
    required this.isBalancePaid,
  });

  const HomePayRentUiState.initial()
    : isPayRentOpen = false,
      amountOption = PayRentAmountOption.fullBalance,
      paymentMethod = PayRentMethod.mpesa,
      mpesaNumber = '0733  605  118',
      step = PayRentStep.form,
      completedReceipt = null,
      showingReceiptDetail = false,
      isBalancePaid = false;

  final bool isPayRentOpen;
  final PayRentAmountOption amountOption;
  final PayRentMethod paymentMethod;
  final String mpesaNumber;
  final PayRentStep step;
  final PaymentReceipt? completedReceipt;
  final bool showingReceiptDetail;
  final bool isBalancePaid;

  int get amountValue {
    switch (amountOption) {
      case PayRentAmountOption.fullBalance:
        return 45000;
      case PayRentAmountOption.half:
        return 22500;
    }
  }

  String get amountFormatted {
    switch (amountOption) {
      case PayRentAmountOption.fullBalance:
        return 'KES 45,000';
      case PayRentAmountOption.half:
        return 'KES 22,500';
    }
  }

  HomePayRentUiState copyWith({
    bool? isPayRentOpen,
    PayRentAmountOption? amountOption,
    PayRentMethod? paymentMethod,
    String? mpesaNumber,
    PayRentStep? step,
    ValueGetter<PaymentReceipt?>? completedReceipt,
    bool? showingReceiptDetail,
    bool? isBalancePaid,
  }) {
    return HomePayRentUiState(
      isPayRentOpen: isPayRentOpen ?? this.isPayRentOpen,
      amountOption: amountOption ?? this.amountOption,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      mpesaNumber: mpesaNumber ?? this.mpesaNumber,
      step: step ?? this.step,
      completedReceipt: completedReceipt != null
          ? completedReceipt()
          : this.completedReceipt,
      showingReceiptDetail: showingReceiptDetail ?? this.showingReceiptDetail,
      isBalancePaid: isBalancePaid ?? this.isBalancePaid,
    );
  }
}

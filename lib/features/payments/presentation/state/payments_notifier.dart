import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/payment_receipt.dart';
import 'payments_ui_state.dart';

class PaymentsNotifier extends Notifier<PaymentsUiState> {
  @override
  PaymentsUiState build() {
    return const PaymentsUiState(
      receipts: [
        PaymentReceipt(
          id: 'rcpt-1',
          receiptNumber: 'RCT-2610-0416',
          companyName: 'Jengo Property Management',
          kraPin: 'P051234567X',
          amount: 'KES 45,000',
          tenantName: 'David Mwangi',
          unit: '5A · Riverside Court',
          date: '30 Sep 2026',
          method: 'M-Pesa',
          reference: 'SJ93HD72PL',
          forDescription: 'Rent, October 2026 (part)',
          initial: 'M',
        ),
        PaymentReceipt(
          id: 'rcpt-2',
          receiptNumber: 'RCT-2609-0371',
          companyName: 'Jengo Property Management',
          kraPin: 'P051234567X',
          amount: 'KES 90,000',
          tenantName: 'David Mwangi',
          unit: '5A · Riverside Court',
          date: '03 Sep 2026',
          method: 'M-Pesa',
          reference: 'QK89HD34MP',
          forDescription: 'Rent, September 2026',
          initial: 'M',
        ),
        PaymentReceipt(
          id: 'rcpt-3',
          receiptNumber: 'RCT-2608-0322',
          companyName: 'Jengo Property Management',
          kraPin: 'P051234567X',
          amount: 'KES 90,000',
          tenantName: 'David Mwangi',
          unit: '5A · Riverside Court',
          date: '04 Aug 2026',
          method: 'Bank',
          reference: 'BNK-26804-991',
          forDescription: 'Rent, August 2026',
          initial: 'B',
        ),
        PaymentReceipt(
          id: 'rcpt-4',
          receiptNumber: 'RCT-2607-0287',
          companyName: 'Jengo Property Management',
          kraPin: 'P051234567X',
          amount: 'KES 90,000',
          tenantName: 'David Mwangi',
          unit: '5A · Riverside Court',
          date: '02 Jul 2026',
          method: 'M-Pesa',
          reference: 'MP8732KD91',
          forDescription: 'Rent, July 2026',
          initial: 'M',
        ),
      ],
      selectedReceipt: null,
    );
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

  void addReceipt(PaymentReceipt receipt) {
    state = state.copyWith(receipts: [receipt, ...state.receipts]);
  }
}

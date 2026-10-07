import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prop_mgt_app/features/billing/presentation/state/tenant_account_providers.dart';
import 'package:prop_mgt_app/features/payments/presentation/state/payments_providers.dart';
import 'package:prop_mgt_app/features/payments/presentation/state/payments_ui_state.dart';

void main() {
  group('PaymentsNotifier', () {
    test('starts on the bills list with nothing selected', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(paymentsProvider);

      expect(state.view, PaymentsView.bills);
      expect(state.selectedBillMonth, isNull);
      expect(state.selectedReceipt, isNull);
    });

    test('selectBill opens a bill and clearSelectedBill closes it', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(paymentsProvider.notifier);

      notifier.selectBill('2026-09');
      expect(container.read(paymentsProvider).selectedBillMonth, '2026-09');

      notifier.clearSelectedBill();
      expect(container.read(paymentsProvider).selectedBillMonth, isNull);
    });

    test('selectReceipt sets and clearSelectedReceipt resets', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final firstReceipt = container.read(tenantAccountProvider).receipts.first;
      container.read(paymentsProvider.notifier).selectReceipt(firstReceipt);
      expect(
        container.read(paymentsProvider).selectedReceipt?.receiptNumber,
        'RCT-2610-0373',
      );

      container.read(paymentsProvider.notifier).clearSelectedReceipt();
      expect(container.read(paymentsProvider).selectedReceipt, isNull);
    });

    test('selectReceipt ignores duplicate selection', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final firstReceipt = container.read(tenantAccountProvider).receipts.first;
      container.read(paymentsProvider.notifier).selectReceipt(firstReceipt);
      final before = container.read(paymentsProvider);
      container.read(paymentsProvider.notifier).selectReceipt(firstReceipt);

      expect(identical(before, container.read(paymentsProvider)), isTrue);
    });

    test('resetToList clears selections and switches view', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(paymentsProvider.notifier)
        ..selectBill('2026-10');

      notifier.resetToList(PaymentsView.receipts);

      final state = container.read(paymentsProvider);
      expect(state.view, PaymentsView.receipts);
      expect(state.selectedBillMonth, isNull);
    });
  });
}

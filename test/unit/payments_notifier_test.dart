import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prop_mgt_app/features/payments/presentation/state/payments_providers.dart';

void main() {
  group('PaymentsNotifier', () {
    test('initial state contains receipts and null selectedReceipt', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(paymentsProvider);

      expect(state.receipts.length, 4);
      expect(state.selectedReceipt, isNull);
    });

    test('selectReceipt sets selectedReceipt in state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final firstReceipt = container.read(paymentsProvider).receipts.first;
      container.read(paymentsProvider.notifier).selectReceipt(firstReceipt);

      final updatedState = container.read(paymentsProvider);
      expect(updatedState.selectedReceipt, firstReceipt);
      expect(updatedState.selectedReceipt?.receiptNumber, 'RCT-2610-0416');
    });

    test('clearSelectedReceipt resets selectedReceipt to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final firstReceipt = container.read(paymentsProvider).receipts.first;
      container.read(paymentsProvider.notifier).selectReceipt(firstReceipt);
      expect(container.read(paymentsProvider).selectedReceipt, isNotNull);

      container.read(paymentsProvider.notifier).clearSelectedReceipt();
      expect(container.read(paymentsProvider).selectedReceipt, isNull);
    });

    test('selectReceipt ignores duplicate selection', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final firstReceipt = container.read(paymentsProvider).receipts.first;
      container.read(paymentsProvider.notifier).selectReceipt(firstReceipt);
      final stateAfterFirstSelect = container.read(paymentsProvider);

      container.read(paymentsProvider.notifier).selectReceipt(firstReceipt);
      final stateAfterDuplicateSelect = container.read(paymentsProvider);

      expect(
        identical(stateAfterFirstSelect, stateAfterDuplicateSelect),
        isTrue,
      );
    });
  });
}

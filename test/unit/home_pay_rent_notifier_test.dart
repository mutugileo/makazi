import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prop_mgt_app/features/home/domain/models/pay_rent_models.dart';
import 'package:prop_mgt_app/features/home/presentation/state/home_pay_rent_providers.dart';

void main() {
  group('HomePayRentNotifier', () {
    test('initial state has default options and isPayRentOpen false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(homePayRentProvider);

      expect(state.isPayRentOpen, isFalse);
      expect(state.amountOption, PayRentAmountOption.fullBalance);
      expect(state.amountValue, 45000);
      expect(state.paymentMethod, PayRentMethod.mpesa);
      expect(state.step, PayRentStep.form);
      expect(state.isBalancePaid, isFalse);
    });

    test('openPayRent sets isPayRentOpen true and resets step to form', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(homePayRentProvider.notifier).openPayRent();

      final state = container.read(homePayRentProvider);
      expect(state.isPayRentOpen, isTrue);
      expect(state.step, PayRentStep.form);
    });

    test('selectAmountOption toggles amount and formatted value', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(homePayRentProvider.notifier)
          .selectAmountOption(PayRentAmountOption.half);

      expect(
        container.read(homePayRentProvider).amountOption,
        PayRentAmountOption.half,
      );
      expect(container.read(homePayRentProvider).amountValue, 22500);
      expect(container.read(homePayRentProvider).amountFormatted, 'KES 22,500');
    });

    test('selectPaymentMethod switches between mpesa and bank transfer', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(homePayRentProvider.notifier)
          .selectPaymentMethod(PayRentMethod.bankTransfer);

      expect(
        container.read(homePayRentProvider).paymentMethod,
        PayRentMethod.bankTransfer,
      );
    });

    test('submitPayment moves through confirming to received state', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final future = container
          .read(homePayRentProvider.notifier)
          .submitPayment();
      expect(container.read(homePayRentProvider).step, PayRentStep.confirming);

      await future;

      final state = container.read(homePayRentProvider);
      expect(state.step, PayRentStep.received);
      expect(state.completedReceipt, isNotNull);
      expect(state.completedReceipt?.receiptNumber, 'RCT-2610-0423');
      expect(state.isBalancePaid, isTrue);
    });

    test('viewCompletedReceipt and closeReceiptDetail toggle state', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(homePayRentProvider.notifier).submitPayment();
      container.read(homePayRentProvider.notifier).viewCompletedReceipt();

      expect(container.read(homePayRentProvider).showingReceiptDetail, isTrue);

      container.read(homePayRentProvider.notifier).closeReceiptDetail();
      expect(container.read(homePayRentProvider).showingReceiptDetail, isFalse);
    });

    test('finishPayRent resets isPayRentOpen and step', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(homePayRentProvider.notifier).openPayRent();
      container.read(homePayRentProvider.notifier).finishPayRent();

      final state = container.read(homePayRentProvider);
      expect(state.isPayRentOpen, isFalse);
      expect(state.step, PayRentStep.form);
    });
  });
}

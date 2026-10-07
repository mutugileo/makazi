import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prop_mgt_app/features/billing/presentation/state/tenant_account_providers.dart';
import 'package:prop_mgt_app/features/home/domain/models/pay_rent_models.dart';
import 'package:prop_mgt_app/features/home/presentation/state/home_pay_rent_providers.dart';

void main() {
  group('HomePayRentNotifier', () {
    test('initial state is closed with M-Pesa selected', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(homePayRentProvider);

      expect(state.isPayRentOpen, isFalse);
      expect(state.paymentMethod, PayRentMethod.mpesa);
      expect(state.step, PayRentStep.form);
    });

    test(
      'openPayRent snapshots the outstanding balance as the full amount',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        container.read(homePayRentProvider.notifier).openPayRent();

        final state = container.read(homePayRentProvider);
        expect(state.isPayRentOpen, isTrue);
        expect(state.step, PayRentStep.form);
        expect(state.fullBalance, 18950);
        expect(state.amountOption, PayRentAmountOption.fullBalance);
        expect(state.amountValue, 18950);
        expect(state.amountFormatted, 'KES 18,950');
      },
    );

    test('other amount is validated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(homePayRentProvider.notifier)
        ..openPayRent()
        ..selectAmountOption(PayRentAmountOption.other);

      expect(container.read(homePayRentProvider).canSubmit, isFalse);
      expect(
        container.read(homePayRentProvider).amountError,
        'Enter an amount to pay',
      );

      notifier.updateOtherAmount('300000');
      expect(container.read(homePayRentProvider).canSubmit, isFalse);
      expect(
        container.read(homePayRentProvider).amountError,
        contains('250,000'),
      );

      notifier.updateOtherAmount('20000');
      expect(container.read(homePayRentProvider).canSubmit, isTrue);
      expect(container.read(homePayRentProvider).amountValue, 20000);
    });

    test('paying more than the balance reports the credit', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(homePayRentProvider.notifier)
        ..openPayRent()
        ..selectAmountOption(PayRentAmountOption.other)
        ..updateOtherAmount('20000');

      expect(container.read(homePayRentProvider).creditAfterPayment, 1050);
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

    test(
      'submitPayment records the payment before showing it received',
      () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final notifier = container.read(homePayRentProvider.notifier)
          ..openPayRent();

        final future = notifier.submitPayment();
        expect(
          container.read(homePayRentProvider).step,
          PayRentStep.confirming,
        );
        expect(container.read(tenantAccountProvider).balance, 18950);

        await future;

        final state = container.read(homePayRentProvider);
        expect(state.step, PayRentStep.received);
        expect(state.completedReceipt?.receiptNumber, 'RCT-2610-0380');
        expect(state.completedReceipt?.amount, 18950);
        expect(state.completedReceipt?.forDescription, 'Bill, October 2026');
        expect(container.read(tenantAccountProvider).balance, 0);
      },
    );

    test('a part payment leaves the rest outstanding', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(homePayRentProvider.notifier)
        ..openPayRent()
        ..selectAmountOption(PayRentAmountOption.other)
        ..updateOtherAmount('10000');

      await notifier.submitPayment();

      expect(
        container.read(homePayRentProvider).completedReceipt?.forDescription,
        'Bill, October 2026 (part)',
      );
      expect(container.read(tenantAccountProvider).balance, 8950);
    });

    test('closing is ignored while a payment is confirming', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(homePayRentProvider.notifier)
        ..openPayRent();

      final future = notifier.submitPayment();
      notifier.closePayRent();
      expect(container.read(homePayRentProvider).isPayRentOpen, isTrue);
      await future;
    });

    test('viewCompletedReceipt and closeReceiptDetail toggle state', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(homePayRentProvider.notifier)
        ..openPayRent();

      await notifier.submitPayment();
      notifier.viewCompletedReceipt();
      expect(container.read(homePayRentProvider).showingReceiptDetail, isTrue);

      notifier.closeReceiptDetail();
      expect(container.read(homePayRentProvider).showingReceiptDetail, isFalse);
    });

    test('finishPayRent resets isPayRentOpen and step', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(homePayRentProvider.notifier)
        ..openPayRent()
        ..finishPayRent();

      final state = container.read(homePayRentProvider);
      expect(state.isPayRentOpen, isFalse);
      expect(state.step, PayRentStep.form);
    });
  });
}

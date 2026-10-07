import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prop_mgt_app/core/billing/billing_models.dart';
import 'package:prop_mgt_app/features/auth/data/auth_repository.dart';
import 'package:prop_mgt_app/features/auth/data/demo_credentials.dart';
import 'package:prop_mgt_app/features/auth/presentation/state/auth_providers.dart';
import 'package:prop_mgt_app/features/billing/presentation/state/tenant_account_providers.dart';

void main() {
  group('TenantAccountNotifier', () {
    test('loads the tenant, unit and current bill from the seed', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final account = container.read(tenantAccountProvider);

      expect(account.tenant.name, 'David Mwangi');
      expect(account.unitTitle, 'Riverside Court · 5A');
      expect(account.accountNumber, 'RC-5A');
      expect(account.isActive, isTrue);
      expect(account.depositHeld, 30000, reason: '2-bed deposit');

      final bill = account.currentBill!;
      expect(bill.month, '2026-10');
      expect(bill.rent, 30000);
      expect(bill.water!.units, 15);
      expect(bill.waterAmount, 2250);
      expect(bill.garbage, 250);
      expect(bill.balanceBf, 1450, reason: 'September water left unpaid');
      expect(bill.totalDue, 33950);
      expect(bill.amountPaid, 15000);
      expect(bill.status, BillStatus.partial);
      expect(account.balance, 18950);
    });

    test('unpaid September balance carries into October', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final account = container.read(tenantAccountProvider);
      final september = account.billFor('2026-09')!;

      expect(september.outstanding, 1450);
      expect(account.billFor('2026-10')!.balanceBf, september.outstanding);
    });

    test('receipts are newest first and describe the bill they paid', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final receipts = container.read(tenantAccountProvider).receipts;

      expect(receipts.length, 6);
      expect(receipts.first.receiptNumber, 'RCT-2610-0373');
      expect(receipts.first.forDescription, 'Bill, October 2026 (part)');
      expect(receipts[1].forDescription, 'Bill, September 2026 (part)');
      expect(receipts[2].forDescription, 'Bill, August 2026');
    });

    test('recordPayment rejects non-positive amounts', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        () => container
            .read(tenantAccountProvider.notifier)
            .recordPayment(
              amount: 0,
              method: PaymentMethod.mpesa,
              reference: 'X',
              time: '10:00',
            ),
        throwsArgumentError,
      );
    });

    test('overpaying turns the balance into credit', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(tenantAccountProvider.notifier)
          .recordPayment(
            amount: 20000,
            method: PaymentMethod.mpesa,
            reference: 'SKTEST0001',
            time: '10:00',
          );

      final account = container.read(tenantAccountProvider);
      expect(account.balance, -1050);
      expect(account.currentBill!.status, BillStatus.credit);
    });
  });

  group('multi-company', () {
    test('a Savanna tenant sees Savanna, never HarborRidge', () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            DemoAuthRepository(latency: Duration.zero),
          ),
        ],
      );
      addTearDown(container.dispose);
      final naliaka = kDemoAccounts.firstWhere(
        (a) => a.phone == '0723 555 019',
      );

      await container
          .read(authProvider.notifier)
          .signIn(phone: naliaka.phone, password: naliaka.password);
      final account = container.read(tenantAccountProvider);

      expect(account.tenant.name, 'Naliaka Wekesa');
      expect(account.company.name, 'Savanna Homes Ltd');
      expect(account.company.mpesaPaybill, '400200');
      expect(account.accountNumber, 'MC-3');
      expect(account.manager?.name, 'Wanjiru Maina');
      expect(account.currentBill!.dueDate, '2026-10-01');
      expect(account.receipts.first.companyName, 'Savanna Homes Ltd');
      expect(account.seed.companies.map((c) => c.id), ['savanna']);
    });
  });

  group('former tenant', () {
    test(
      'Joseph sees his records read-only, with the retention date',
      () async {
        final container = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(
              DemoAuthRepository(latency: Duration.zero),
            ),
          ],
        );
        addTearDown(container.dispose);
        final joseph = kDemoAccounts.firstWhere(
          (a) => a.phone == '0720 671 093',
        );

        await container
            .read(authProvider.notifier)
            .signIn(phone: joseph.phone, password: joseph.password);
        final account = container.read(tenantAccountProvider);

        expect(account.tenant.name, 'Joseph Kariuki');
        expect(account.isActive, isFalse);
        expect(account.depositHeld, 0);
        // Same 6-month rule as the admin's Former tenants tab.
        expect(account.recordsKeptUntil, '2027-02-28');
        expect(account.currentBill!.kind.wire, 'final');
        expect(account.currentBill!.depositRefund, 28500);
        expect(account.balance, 0);
      },
    );
  });
}

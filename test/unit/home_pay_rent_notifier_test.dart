import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prop_mgt_app/core/billing/payment_claim.dart';
import 'package:prop_mgt_app/core/data/payment_claims_repository.dart';
import 'package:prop_mgt_app/core/data/supabase_billing_providers.dart';
import 'package:prop_mgt_app/features/billing/presentation/state/tenant_account_providers.dart';
import 'package:prop_mgt_app/features/home/presentation/state/home_pay_rent_providers.dart';

const _message =
    'UKA1D18L3S Confirmed. Ksh31,200.00 sent to THE PHOENIX for account '
    '404020 on 10/11/26 at 1:34 PM';

/// Answers like the database: refuses, fails, or accepts and reads the message.
class _FakeClaims implements PaymentClaimsRepository {
  _FakeClaims({this.refusal, this.fails = false});

  final String? refusal;
  final bool fails;
  final sent = <({String tenancyId, String message})>[];
  final updated = <({String claimId, String message})>[];
  final deleted = <String>[];

  @override
  Future<PaymentClaim> submit({
    required String tenancyId,
    required String message,
  }) async {
    if (fails) throw Exception('offline');
    if (refusal != null) throw PaymentClaimRefused(refusal!);
    sent.add((tenancyId: tenancyId, message: message));
    return const PaymentClaim(
      id: 'c1',
      status: PaymentClaimStatus.pending,
      createdAt: '2026-11-10T13:40:00+03:00',
      reference: 'UKA1D18L3S',
      amount: 31200,
    );
  }

  @override
  Future<List<PaymentClaim>> fetchOpen({required String tenancyId}) async => [
    for (final _ in sent)
      const PaymentClaim(
        id: 'c1',
        status: PaymentClaimStatus.pending,
        createdAt: '2026-11-10T13:40:00+03:00',
      ),
  ];

  @override
  Future<PaymentClaim> updateClaim({
    required String claimId,
    required String message,
  }) async {
    if (fails) throw Exception('offline');
    if (refusal != null) throw PaymentClaimRefused(refusal!);
    updated.add((claimId: claimId, message: message));
    return PaymentClaim(
      id: claimId,
      status: PaymentClaimStatus.pending,
      createdAt: '2026-11-10T13:45:00+03:00',
      message: message,
      reference: 'UKA1D18L3S',
      amount: 31200,
    );
  }

  @override
  Future<void> deleteClaim({required String claimId}) async {
    deleted.add(claimId);
  }
}

ProviderContainer _container(_FakeClaims claims) {
  final container = ProviderContainer(
    overrides: [paymentClaimsRepositoryProvider.overrideWithValue(claims)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('HomePayRentNotifier', () {
    test('opens empty, and nothing can be sent until a message is pasted', () {
      final container = _container(_FakeClaims());
      container.read(homePayRentProvider.notifier).openPayRent();

      final state = container.read(homePayRentProvider);
      expect(state.isOpen, isTrue);
      expect(state.message, isEmpty);
      expect(state.canSend, isFalse);

      container.read(homePayRentProvider.notifier).updateMessage('   ');
      expect(container.read(homePayRentProvider).canSend, isFalse);
    });

    test('sends the trimmed message for the current tenancy', () async {
      final claims = _FakeClaims();
      final container = _container(claims);
      final notifier = container.read(homePayRentProvider.notifier)
        ..openPayRent()
        ..updateMessage('  $_message  ');

      await notifier.sendMessage();

      expect(claims.sent.single.message, _message);
      expect(
        claims.sent.single.tenancyId,
        container.read(tenantAccountProvider).tenancy.id,
      );
      final state = container.read(homePayRentProvider);
      expect(state.isSending, isFalse);
      expect(state.sentClaim?.reference, 'UKA1D18L3S');
      expect(state.sentClaim?.amount, 31200);
      // The balance is untouched until the manager confirms.
      expect(container.read(tenantAccountProvider).balance, 18950);
    });

    test('a sent message shows as waiting', () async {
      final container = _container(_FakeClaims());
      final notifier = container.read(homePayRentProvider.notifier)
        ..openPayRent()
        ..updateMessage(_message);
      await notifier.sendMessage();

      final open = await container.read(paymentClaimsProvider.future);
      expect(open.single.status, PaymentClaimStatus.pending);
    });

    test('a refusal is shown as the database worded it', () async {
      final container = _container(
        _FakeClaims(refusal: 'This payment is already recorded'),
      );
      final notifier = container.read(homePayRentProvider.notifier)
        ..openPayRent()
        ..updateMessage(_message);

      await notifier.sendMessage();

      final state = container.read(homePayRentProvider);
      expect(state.errorText, 'This payment is already recorded');
      expect(state.sentClaim, isNull);
      expect(state.isSending, isFalse);
    });

    test('a network failure says nothing was sent', () async {
      final container = _container(_FakeClaims(fails: true));
      final notifier = container.read(homePayRentProvider.notifier)
        ..openPayRent()
        ..updateMessage(_message);

      await notifier.sendMessage();

      expect(
        container.read(homePayRentProvider).errorText,
        contains("Couldn't send"),
      );
    });

    test('editing the message clears the error; closing resets', () async {
      final container = _container(_FakeClaims(refusal: 'Too many'));
      final notifier = container.read(homePayRentProvider.notifier)
        ..openPayRent()
        ..updateMessage(_message);
      await notifier.sendMessage();
      notifier.updateMessage('$_message.');
      expect(container.read(homePayRentProvider).errorText, isNull);

      notifier.closePayRent();
      final state = container.read(homePayRentProvider);
      expect(state.isOpen, isFalse);
      expect(state.message, isEmpty);
    });

    test('rejects non-payment text without calling the repository', () async {
      final claims = _FakeClaims();
      final container = _container(claims);
      final notifier = container.read(homePayRentProvider.notifier)
        ..openPayRent()
        ..updateMessage('Hello landlord, I will pay rent on Friday evening');

      await notifier.sendMessage();

      expect(claims.sent, isEmpty);
      final state = container.read(homePayRentProvider);
      expect(state.sentClaim, isNull);
      expect(state.isSending, isFalse);
      expect(state.errorText, contains('reference and amount'));
    });

    test('rejects a short message without calling the repository', () async {
      final claims = _FakeClaims();
      final container = _container(claims);
      final notifier = container.read(homePayRentProvider.notifier)
        ..openPayRent()
        ..updateMessage('UKA1D18L3S');

      await notifier.sendMessage();

      expect(claims.sent, isEmpty);
      expect(
        container.read(homePayRentProvider).errorText,
        'Paste the whole confirmation message',
      );
    });

    test('accepts a received-side M-Pesa confirmation message', () async {
      final claims = _FakeClaims();
      final container = _container(claims);
      const received =
          'Confirmed. You have received KES 31200.00 for Account 404020 '
          'from AUGUSTINE MUSA. # Mpesa Ref:UKA1D18L3S on 10-11-2026 13:34Hrs';
      final notifier = container.read(homePayRentProvider.notifier)
        ..openPayRent()
        ..updateMessage(received);

      await notifier.sendMessage();

      expect(claims.sent.single.message, received);
      expect(container.read(homePayRentProvider).errorText, isNull);
    });

    test('edits and resubmits a rejected payment claim', () async {
      final claims = _FakeClaims();
      final container = _container(claims);
      const rejectedClaim = PaymentClaim(
        id: 'c-rejected',
        status: PaymentClaimStatus.rejected,
        createdAt: '2026-11-10T12:00:00+03:00',
        message: 'OLD1234567 Confirmed. Ksh100.00 sent to THE PHOENIX',
        reference: 'OLD1234567',
        amount: 100,
        reviewNote: 'Wrong amount',
      );
      final notifier = container.read(homePayRentProvider.notifier)
        ..openPayRentForEdit(rejectedClaim);

      expect(container.read(homePayRentProvider).isEditing, isTrue);
      expect(
        container.read(homePayRentProvider).message,
        rejectedClaim.message,
      );

      notifier.updateMessage(_message);
      await notifier.sendMessage();

      expect(claims.sent, isEmpty);
      expect(claims.updated.single.claimId, 'c-rejected');
      expect(claims.updated.single.message, _message);
      expect(container.read(homePayRentProvider).sentClaim?.id, 'c-rejected');
    });
  });
}

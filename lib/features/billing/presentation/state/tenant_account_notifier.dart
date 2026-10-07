import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/billing/billing_models.dart';
import '../../../../core/billing/seed/tenant_seed.g.dart';
import '../../../../core/data/data_mode.dart';
import '../../../../core/models/payment_receipt.dart';
import '../../../auth/presentation/state/auth_providers.dart';
import 'tenant_account_providers.dart';
import 'tenant_account_state.dart';

/// The signed-in tenant's account.
///
/// Live mode: built only from [liveTenantSeedProvider]; the app shell is not
/// shown until that has loaded, so there is no moment of demo data.
/// Tests and the offline demo build: the bundled seed for the phone number.
class TenantAccountNotifier extends Notifier<TenantAccountState> {
  @override
  TenantAccountState build() {
    if (ref.watch(liveDataProvider)) {
      final seed = ref.watch(liveTenantSeedProvider).value;
      if (seed != null) return TenantAccountState.fromSeed(seed);
      // Signing out: keep the last account while the shell fades away.
      final previous = stateOrNull;
      if (previous != null) return previous;
      throw StateError('Tenant data has not loaded');
    }

    final phone = ref.watch(authProvider.select((s) => s.phone));
    final json =
        kTenantSeedsByPhone[phone ?? kDefaultTenantPhone] ??
        kTenantSeedsByPhone[kDefaultTenantPhone]!;
    return TenantAccountState.fromSeed(
      BillingSeed.fromJson(jsonDecode(json) as Map<String, dynamic>),
    );
  }

  /// Rereads the account from the database (live mode only). Completes when
  /// the reload has finished; if it fails, the last loaded account stays.
  Future<void> refreshFromDatabase() async {
    if (!ref.read(liveDataProvider)) return;
    ref.invalidate(liveTenantSeedProvider);
    try {
      await ref.read(liveTenantSeedProvider.future);
    } catch (_) {
      // Shown by the shell's connection banner.
    }
  }

  /// Demo build only: records a simulated M-Pesa payment locally. The live
  /// app never writes payments; they come from the manager or M-Pesa.
  PaymentReceipt recordPayment({
    required int amount,
    required PaymentMethod method,
    required String reference,
    required String time,
  }) {
    if (ref.read(liveDataProvider)) {
      throw StateError('Payments are recorded by the server, not the app');
    }
    if (amount <= 0) {
      throw ArgumentError.value(amount, 'amount', 'must be positive');
    }
    final seed = state.seed;
    final company = state.company;
    final sequence = company.receiptSequence + 1;
    final date = seed.asOf;
    final receiptNumber =
        'RCT-${date.substring(2, 4)}${date.substring(5, 7)}-'
        '${sequence.toString().padLeft(4, '0')}';

    final payment = Payment(
      receiptNumber: receiptNumber,
      tenancyId: state.tenancy.id,
      amount: amount,
      date: date,
      time: time,
      method: method,
      reference: reference,
    );

    state = TenantAccountState.fromSeed(
      seed.copyWith(
        payments: [...seed.payments, payment],
        companies: [
          for (final c in seed.companies)
            c.id == company.id ? c.copyWith(receiptSequence: sequence) : c,
        ],
      ),
    );
    return state.receipts.firstWhere((r) => r.receiptNumber == receiptNumber);
  }
}

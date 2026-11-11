import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/billing/billing_models.dart';
import '../../../../core/billing/seed/tenant_seed.g.dart';
import '../../../../core/config/demo_data.dart';
import '../../../../core/data/data_mode.dart';
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
    if (kDemoDataAvailable && !ref.watch(liveDataProvider)) {
      return _demoAccount();
    }

    final seed = ref.watch(liveTenantSeedProvider).value;
    if (seed != null) return TenantAccountState.fromSeed(seed);
    // Signing out: keep the last account while the shell fades away.
    final previous = stateOrNull;
    if (previous != null) return previous;
    throw StateError('Tenant data has not loaded');
  }

  TenantAccountState _demoAccount() {
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
}

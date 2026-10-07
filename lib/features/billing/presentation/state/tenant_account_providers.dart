import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/billing/billing_models.dart';
import '../../../../core/data/data_mode.dart';
import '../../../../core/data/supabase_billing_providers.dart';
import '../../../auth/domain/auth_models.dart';
import '../../../auth/presentation/state/auth_providers.dart';
import '../../../messages/presentation/state/messages_notifier.dart';
import 'tenant_account_notifier.dart';
import 'tenant_account_state.dart';

final tenantAccountProvider =
    NotifierProvider<TenantAccountNotifier, TenantAccountState>(
      TenantAccountNotifier.new,
    );

/// Live mode: the signed-in tenant's own data, read through RLS.
///
/// Null while nobody is signed in (or still on a one-time password, when the
/// database shows nothing). Errors are shown with a retry, never replaced by
/// seed data, so retries are manual.
final liveTenantSeedProvider = FutureProvider<BillingSeed?>((ref) {
  if (!ref.watch(liveDataProvider)) return null;
  // Refetches on each sign-in (it passes through signed-out), not on lock.
  final canRead = ref.watch(
    authProvider.select(
      (s) => switch (s.stage) {
        AuthStage.createPin ||
        AuthStage.enableBiometrics ||
        AuthStage.locked ||
        AuthStage.unlocked => true,
        AuthStage.signedOut || AuthStage.mustChangePassword => false,
      },
    ),
  );
  if (!canRead) return null;
  return ref.watch(supabaseBillingRepositoryProvider).fetchTenantSeed();
}, retry: (_, _) => null);

/// Live mode: refetches when the admin changes something for this tenant,
/// and shows the manager typing. Kept alive by the screen that shows data.
final tenantRealtimeProvider = Provider<void>((ref) {
  final ids = ref.watch(
    liveTenantSeedProvider.select((async) {
      final seed = async.value;
      return seed == null
          ? null
          : (
              company: seed.companies.single.id,
              tenancy: seed.tenancies.single.id,
            );
    }),
  );
  if (ids == null) return;
  final realtime = ref
      .read(supabaseBillingRepositoryProvider)
      .subscribe(
        companyId: ids.company,
        tenancyId: ids.tenancy,
        onChanged: () => ref.invalidate(liveTenantSeedProvider),
        onTyping: (isTyping) {
          final typing = ref.read(managerTypingProvider.notifier);
          isTyping ? typing.showTyping() : typing.hideTyping();
        },
      );
  ref.onDispose(realtime.dispose);
});

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/billing/billing_models.dart';
import '../../../../core/billing/payment_claim.dart';
import '../../../../core/theme/brand_colors.dart';
import '../../../../core/theme/brand_theme_cache.dart';
import '../../../../core/data/data_mode.dart';
import '../../../../core/data/supabase_billing_providers.dart';
import '../../../../core/data/supabase_billing_repository.dart';
import '../../../auth/domain/auth_models.dart';
import '../../../auth/presentation/state/auth_providers.dart';
import '../../../messages/presentation/state/messages_notifier.dart';
import '../../../notifications/presentation/state/notifications_providers.dart';
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
final liveTenantSeedProvider = FutureProvider<BillingSeed?>((ref) async {
  if (!ref.watch(liveDataProvider)) return null;
  // Refetches on each sign-in (it passes through signed-out), not on lock.
  final canRead = ref.watch(
    authProvider.select(
      (s) => switch (s.stage) {
        AuthStage.createPin ||
        AuthStage.enableBiometrics ||
        AuthStage.locked ||
        AuthStage.unlocked => true,
        AuthStage.signedOut => false,
      },
    ),
  );
  if (!canRead) return null;
  final seed = await ref
      .watch(supabaseBillingRepositoryProvider)
      .fetchTenantSeed();
  // Remembered for the next launch's loading screens (colours only).
  unawaited(
    BrandThemeCache.write(
      TenantAccountState.fromSeed(seed).company.settings.theme,
    ),
  );
  return seed;
}, retry: (_, _) => null);

/// Live mode: refetches when the admin changes something for this tenant,
/// and shows the manager typing. Kept alive by the screen that shows data.
final tenantRealtimeProvider = Provider<TenantRealtime?>((ref) {
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
  if (ids == null) return null;
  final realtime = ref
      .read(supabaseBillingRepositoryProvider)
      .subscribe(
        companyId: ids.company,
        tenancyId: ids.tenancy,
        onChanged: () {
          ref.invalidate(liveTenantSeedProvider);
          ref.invalidate(tenantNotificationsProvider);
        },
        onTyping: (isTyping) {
          final typing = ref.read(managerTypingProvider.notifier);
          isTyping ? typing.showTyping() : typing.hideTyping();
        },
      );
  ref.onDispose(realtime.dispose);
  return realtime;
});

/// The tenant's payment messages that are waiting for the manager or were not
/// confirmed (newest first). Confirmed ones show as receipts instead.
/// Rereads whenever the account does (realtime, pull to refresh, resume).
final paymentClaimsProvider = FutureProvider<List<PaymentClaim>>((ref) {
  ref.watch(liveTenantSeedProvider.select((seed) => seed.value));
  final tenancyId = ref.watch(
    tenantAccountProvider.select((a) => a.tenancy.id),
  );
  return ref
      .watch(paymentClaimsRepositoryProvider)
      .fetchOpen(tenancyId: tenancyId);
});

/// The company theme saved on this device by the last load. Null on a fresh
/// install. Overridden at startup in main.dart.
final cachedBrandThemeProvider = Provider<CompanyTheme?>((ref) => null);

/// The company's brand colours. Makazi's own palette until the account has
/// loaded. Never throws: reads the live seed directly, because the account
/// notifier throws while it is still loading.
final brandColorsProvider = Provider<BrandColors>((ref) {
  if (ref.watch(liveDataProvider)) {
    final seed = ref.watch(liveTenantSeedProvider).value;
    if (seed == null) {
      final cached = ref.watch(cachedBrandThemeProvider);
      return cached == null
          ? BrandColors.makazi
          : BrandColors.fromTheme(cached);
    }
    return BrandColors.fromTheme(
      TenantAccountState.fromSeed(seed).company.settings.theme,
    );
  }
  return BrandColors.fromTheme(
    ref.watch(tenantAccountProvider.select((s) => s.company.settings.theme)),
  );
});

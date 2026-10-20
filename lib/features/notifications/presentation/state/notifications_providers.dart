import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/data/data_mode.dart';
import '../../../../core/data/supabase_billing_providers.dart';
import '../../../billing/presentation/state/tenant_account_providers.dart';
import '../../domain/tenant_notification.dart';

/// Live mode: the signed-in tenant's notifications, newest first. Refetched
/// when the admin nudges the app (tenantRealtimeProvider). Empty in the demo
/// build, which has no staff to send any.
final tenantNotificationsProvider =
    AsyncNotifierProvider<
      TenantNotificationsNotifier,
      List<TenantNotification>
    >(TenantNotificationsNotifier.new);

class TenantNotificationsNotifier
    extends AsyncNotifier<List<TenantNotification>> {
  @override
  Future<List<TenantNotification>> build() async {
    if (!ref.watch(liveDataProvider)) return const [];
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
    if (ids == null) return const [];
    return ref
        .read(supabaseBillingRepositoryProvider)
        .fetchNotifications(companyId: ids.company, tenancyId: ids.tenancy);
  }

  ({String company, String tenancy})? _ids() {
    final seed = ref.read(liveTenantSeedProvider).value;
    return seed == null
        ? null
        : (
            company: seed.companies.single.id,
            tenancy: seed.tenancies.single.id,
          );
  }

  /// Refreshes the notifications list from the database.
  Future<void> refresh() async {
    if (!ref.read(liveDataProvider)) return;
    final ids = _ids();
    if (ids == null) return;
    final fresh = await ref
        .read(supabaseBillingRepositoryProvider)
        .fetchNotifications(companyId: ids.company, tenancyId: ids.tenancy);
    state = AsyncData(fresh);
  }

  /// Hides it once the database has recorded it as read. Throws if that
  /// failed, so the card stays and the screen can say so.
  Future<void> dismiss(String id) async {
    await ref.read(supabaseBillingRepositoryProvider).markNotificationRead(id);
    final current = state.value;
    if (current == null) return;
    state = AsyncData([
      for (final n in current)
        n.id == id
            ? TenantNotification(
                id: n.id,
                kind: n.kind,
                title: n.title,
                body: n.body,
                createdAt: n.createdAt,
                readAt: DateTime.now().toIso8601String(),
              )
            : n,
    ]);
  }

  /// Marks all unread notifications read for this tenancy.
  Future<void> markAllRead() async {
    if (!ref.read(liveDataProvider)) return;
    final ids = _ids();
    if (ids == null) return;
    await ref
        .read(supabaseBillingRepositoryProvider)
        .markAllNotificationsRead(
          companyId: ids.company,
          tenancyId: ids.tenancy,
        );
    final current = state.value;
    if (current == null) return;
    final now = DateTime.now().toIso8601String();
    state = AsyncData([
      for (final n in current)
        n.isUnread
            ? TenantNotification(
                id: n.id,
                kind: n.kind,
                title: n.title,
                body: n.body,
                createdAt: n.createdAt,
                readAt: now,
              )
            : n,
    ]);
  }
}

/// Unread ones, for Home and the pop-up.
final unreadNotificationsProvider = Provider<List<TenantNotification>>(
  (ref) => [
    for (final n in ref.watch(tenantNotificationsProvider).value ?? const [])
      if (n.isUnread) n,
  ],
);

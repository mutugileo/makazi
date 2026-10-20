import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/widgets/change_pin_sheet.dart';
import '../../../billing/presentation/state/tenant_account_providers.dart';
import '../../../home/presentation/state/home_pay_rent_providers.dart';
import '../../../messages/presentation/state/messages_notifier.dart';
import '../../domain/tenant_notification.dart';
import '../state/notifications_providers.dart';
import '../../../../core/platform/platform_channel_service.dart';

/// Full-screen notification inbox showing security alerts, payment reminders,
/// and property announcements.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(tenantNotificationsProvider);
    final unread = ref.watch(unreadNotificationsProvider);
    final hasNotificationPermission = ref.watch(notificationPermissionProvider);
    final hasNetwork = ref.watch(networkStatusProvider);
    final asOf = DateTime.now()
        .toUtc()
        .add(const Duration(hours: 3))
        .toIso8601String()
        .substring(0, 10);

    return Scaffold(
      key: const ValueKey('notifications_screen'),
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: AppColors.pageBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          key: const ValueKey('notifications_back_button'),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          unread.isEmpty ? 'Notifications' : 'Notifications (${unread.length})',
          style: AppTypography.editorialSerif(
            fontSize: 22,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          if (unread.isNotEmpty)
            TextButton(
              key: const ValueKey('notifications_mark_all_read'),
              onPressed: () =>
                  ref.read(tenantNotificationsProvider.notifier).markAllRead(),
              child: Text(
                'Mark all read',
                style: AppTypography.sans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.forestGreen,
                ),
              ),
            ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            if (!hasNetwork)
              Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.terracottaLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.wifi_off_rounded,
                      color: AppColors.terracotta,
                      size: 16,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'Device is offline',
                        style: AppTypography.sans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.terracotta,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => ref
                          .read(networkStatusProvider.notifier)
                          .openSettings(),
                      child: Text(
                        'Settings',
                        style: AppTypography.sans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.terracotta,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (!hasNotificationPermission)
              Container(
                key: const ValueKey('notification_permission_banner'),
                margin: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.mintBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.notifications_off_outlined,
                      color: AppColors.forestGreen,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Allow phone notifications',
                            style: AppTypography.sans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.forestGreen,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Enable alerts to get instant notifications when your manager issues a new PIN or rent receipt.',
                            style: AppTypography.sans(
                              fontSize: 12,
                              color: AppColors.textPrimary,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 6),
                          GestureDetector(
                            key: const ValueKey('enable_notifications_button'),
                            onTap: () async {
                              final granted = await ref
                                  .read(notificationPermissionProvider.notifier)
                                  .requestPermission();
                              if (!granted && context.mounted) {
                                await ref
                                    .read(
                                      notificationPermissionProvider.notifier,
                                    )
                                    .openSettings();
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.forestGreen,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Enable in settings',
                                style: AppTypography.sans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.pureWhite,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.forestGreen,
                backgroundColor: AppColors.cardBackground,
                onRefresh: () =>
                    ref.read(tenantNotificationsProvider.notifier).refresh(),

                child: notificationsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: AppColors.forestGreen,
                    ),
                  ),
                  error: (_, _) => ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      const SizedBox(height: 60),
                      Center(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.wifi_off_rounded,
                              size: 48,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Could not load notifications',
                              style: AppTypography.sans(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Pull down to try again',
                              style: AppTypography.sans(
                                fontSize: 13,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  data: (items) {
                    if (items.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        children: [
                          const SizedBox(height: 80),
                          Center(
                            child: Container(
                              key: const ValueKey('notifications_empty_state'),
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: AppColors.cardBackground,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.borderLight,
                                ),
                              ),
                              child: const Icon(
                                Icons.notifications_none_rounded,
                                size: 36,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'No notifications yet',
                            textAlign: TextAlign.center,
                            style: AppTypography.editorialSerif(
                              fontSize: 22,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                            child: Text(
                              'Security alerts, temporary login PINs, and rent reminders from property management will appear here.',
                              textAlign: TextAlign.center,
                              style: AppTypography.sans(
                                fontSize: 14,
                                color: AppColors.textMuted,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    return ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.sm,
                        AppSpacing.md,
                        AppSpacing.xl,
                      ),
                      itemCount: items.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final notification = items[index];
                        return _NotificationItemCard(
                          notification: notification,
                          asOf: asOf,
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationItemCard extends ConsumerStatefulWidget {
  const _NotificationItemCard({required this.notification, required this.asOf});

  final TenantNotification notification;
  final String asOf;

  @override
  ConsumerState<_NotificationItemCard> createState() =>
      _NotificationItemCardState();
}

class _NotificationItemCardState extends ConsumerState<_NotificationItemCard> {
  bool _isBusy = false;

  Future<void> _dismiss() async {
    setState(() => _isBusy = true);
    try {
      await ref
          .read(tenantNotificationsProvider.notifier)
          .dismiss(widget.notification.id);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isBusy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not dismiss notification. Check connection.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.notification;
    final isPinReset = n.isPinReset;
    final seed = ref.watch(liveTenantSeedProvider).value;
    final canPay =
        n.isPaymentReminder && seed != null && seed.tenancies.isNotEmpty;

    final cardBg = isPinReset
        ? AppColors.cardBackground
        : (n.isPaymentReminder
              ? AppColors.terracottaLight
              : AppColors.cardBackground);

    final borderColor = isPinReset
        ? (n.isUnread
              ? AppColors.forestGreen.withValues(alpha: 0.35)
              : AppColors.borderLight)
        : (n.isPaymentReminder
              ? AppColors.statusUnpaidBorder
              : AppColors.borderLight);

    final iconBg = isPinReset
        ? AppColors.limeSoft
        : (n.isPaymentReminder
              ? AppColors.terracottaLight
              : AppColors.avatarBackground);

    final iconColor = isPinReset
        ? AppColors.forestGreen
        : (n.isPaymentReminder ? AppColors.terracotta : AppColors.textPrimary);

    final icon = isPinReset
        ? Icons.lock_reset_rounded
        : (n.isPaymentReminder
              ? Icons.notifications_active_outlined
              : Icons.info_outline_rounded);

    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Container(
        key: ValueKey('notification_tile_${n.id}'),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: n.isUnread ? 1.5 : 1),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (n.isUnread) ...[
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.forestGreen,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Expanded(
                            child: Text(
                              n.title,
                              style: AppTypography.sans(
                                fontSize: 15,
                                fontWeight: n.isUnread
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        chatTimestamp(n.createdAt, widget.asOf),
                        style: AppTypography.sans(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              n.body,
              style: AppTypography.sans(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            if (isPinReset) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.statusPartialBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.statusPartialBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: AppColors.statusPartialText,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          n.pinValidityLabel ?? 'Valid for 72 hours',
                          style: AppTypography.sans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.statusPartialText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.limeSoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified_user_outlined,
                          size: 14,
                          color: AppColors.forestGreen,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'One-time PIN',
                          style: AppTypography.sans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.forestGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.xs,
                runSpacing: 4,
                children: [
                  if (n.isUnread)
                    TextButton(
                      key: ValueKey('notification_dismiss_${n.id}'),
                      onPressed: _isBusy ? null : _dismiss,
                      child: _isBusy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.textMuted,
                              ),
                            )
                          : Text(
                              'Mark as read',
                              style: AppTypography.sans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted,
                              ),
                            ),
                    ),
                  if (isPinReset)
                    ElevatedButton.icon(
                      key: ValueKey('notification_change_pin_${n.id}'),
                      onPressed: () {
                        if (n.isUnread) _dismiss();
                        ChangePinSheet.show(context);
                      },
                      icon: const Icon(Icons.key_outlined, size: 16),
                      label: const Text('Change PIN'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.forestGreen,
                        foregroundColor: AppColors.pureWhite,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                      ),
                    ),
                  if (canPay)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        ref.read(homePayRentProvider.notifier).openPayRent();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.mintAccent,
                        foregroundColor: AppColors.pureWhite,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Pay rent'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

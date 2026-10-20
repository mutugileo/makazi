import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../billing/presentation/state/tenant_account_providers.dart';
import '../../../home/presentation/state/home_pay_rent_providers.dart';
import '../../../messages/presentation/state/messages_notifier.dart';
import '../../domain/tenant_notification.dart';
import '../state/notifications_providers.dart';

import '../../../auth/presentation/widgets/change_pin_sheet.dart';
import '../screens/notifications_screen.dart';

/// Unread notifications at the top of Home, newest first, until dismissed.
class NotificationCards extends ConsumerWidget {
  const NotificationCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationsProvider);
    if (unread.isEmpty) return const SizedBox.shrink();
    final topThree = unread.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.notifications_active_outlined,
                  size: 16,
                  color: AppColors.forestGreen,
                ),
                const SizedBox(width: 6),
                Text(
                  'NOTIFICATIONS',
                  style: AppTypography.sans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.forestGreen,
                  ),
                ),
              ],
            ),
            TextButton(
              key: const ValueKey('notifications_view_all_button'),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                );
              },
              child: Text(
                'View all (${unread.length})',
                style: AppTypography.sans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.forestGreen,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        for (final n in topThree) ...[
          _NotificationCard(notification: n),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _NotificationCard extends ConsumerStatefulWidget {
  const _NotificationCard({required this.notification});

  final TenantNotification notification;

  @override
  ConsumerState<_NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends ConsumerState<_NotificationCard> {
  bool _dismissing = false;

  Future<void> _dismiss() async {
    setState(() => _dismissing = true);
    try {
      await ref
          .read(tenantNotificationsProvider.notifier)
          .dismiss(widget.notification.id);
    } catch (_) {
      if (!mounted) return;
      setState(() => _dismissing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Couldn\'t dismiss it. Check your connection.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.notification;
    final isPinReset = n.isPinReset;
    final account = ref.watch(tenantAccountProvider);
    final canPay =
        n.isPaymentReminder && account.isActive && account.balance > 0;

    final cardBg = isPinReset
        ? AppColors.cardBackground
        : AppColors.terracottaLight;

    final borderColor = isPinReset
        ? AppColors.forestGreen.withValues(alpha: 0.3)
        : AppColors.statusUnpaidBorder;

    final iconColor = isPinReset ? AppColors.forestGreen : AppColors.terracotta;

    final icon = isPinReset
        ? Icons.lock_reset_rounded
        : Icons.notifications_active_outlined;

    return Container(
      key: ValueKey('notification_${n.id}'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  n.title,
                  style: AppTypography.sans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                chatTimestamp(n.createdAt, account.seed.asOf),
                style: AppTypography.sans(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            n.body,
            style: AppTypography.sans(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          if (isPinReset) ...[
            const SizedBox(height: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                    size: 13,
                    color: AppColors.statusPartialText,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    n.pinValidityLabel ?? 'Valid for 72 hours',
                    style: AppTypography.sans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.statusPartialText,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                key: ValueKey('notification_dismiss_${n.id}'),
                onPressed: _dismissing ? null : _dismiss,
                child: Text(
                  'Dismiss',
                  style: AppTypography.sans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              if (isPinReset) ...[
                const SizedBox(width: AppSpacing.xs),
                ElevatedButton.icon(
                  key: ValueKey('notification_change_pin_home_${n.id}'),
                  onPressed: () {
                    _dismiss();
                    ChangePinSheet.show(context);
                  },
                  icon: const Icon(Icons.key_outlined, size: 15),
                  label: const Text('Change PIN'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.forestGreen,
                    foregroundColor: AppColors.pureWhite,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
              if (canPay) ...[
                const SizedBox(width: AppSpacing.xs),
                ElevatedButton(
                  onPressed: () =>
                      ref.read(homePayRentProvider.notifier).openPayRent(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mintAccent,
                    foregroundColor: AppColors.pureWhite,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Pay rent'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

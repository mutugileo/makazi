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

/// Unread notifications at the top of Home, newest first, until dismissed.
class NotificationCards extends ConsumerWidget {
  const NotificationCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationsProvider).take(3).toList();
    if (unread.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        for (final n in unread) ...[
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
    final account = ref.watch(tenantAccountProvider);
    final canPay =
        n.isPaymentReminder && account.isActive && account.balance > 0;

    return Container(
      key: ValueKey('notification_${n.id}'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.terracottaLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.statusUnpaidBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.notifications_active_outlined,
                size: 20,
                color: AppColors.terracotta,
              ),
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

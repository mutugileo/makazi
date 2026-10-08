import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../billing/presentation/state/tenant_account_providers.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../domain/models/repair_ticket.dart';
import '../state/repairs_providers.dart';
import '../widgets/report_repair_form_view.dart';

class RepairsScreen extends ConsumerWidget {
  const RepairsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(repairsProvider);
    final notifier = ref.read(repairsProvider.notifier);
    final theme = Theme.of(context);
    final motion =
        theme.extension<AppMotionThemeExtension>() ??
        const AppMotionThemeExtension.regular();

    ref.listen(repairsProvider, (previous, next) {
      if (next.newlyCreatedTicket != null &&
          previous?.newlyCreatedTicket != next.newlyCreatedTicket) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Request ${next.newlyCreatedTicket!.id} submitted',
              style: AppTypography.sans(
                fontSize: 14,
                color: AppColors.pureWhite,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: AppColors.forestGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
        notifier.dismissNewlyCreatedTicketFeedback();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        bottom: false,
        child: AnimatedSwitcher(
          duration: motion.stateTransitionDuration,
          switchInCurve: motion.standardEasing,
          switchOutCurve: motion.standardEasing,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: state.isNewRequestOpen
              ? const ReportRepairFormView(
                  key: ValueKey('report_repair_form_view'),
                )
              : _RepairsListView(
                  key: const ValueKey('repairs_list_view'),
                  tickets: state.tickets,
                  // Former tenants keep their history but can't raise new
                  // requests (enforced by RLS in Phase 2).
                  onNewRequestPressed: ref.watch(tenantAccountProvider).isActive
                      ? notifier.openNewRequest
                      : null,
                ),
        ),
      ),
    );
  }
}

class _RepairsListView extends StatelessWidget {
  const _RepairsListView({
    super.key,
    required this.tickets,
    required this.onNewRequestPressed,
  });

  final List<RepairTicket> tickets;
  final VoidCallback? onNewRequestPressed;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final systemBottomPadding = mediaQuery.padding.bottom;
    final scrollBottomPadding = systemBottomPadding + 86.0;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        scrollBottomPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Repairs',
                  style: AppTypography.editorialSerif(
                    fontSize: 38,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (onNewRequestPressed != null)
                ElevatedButton(
                  onPressed: onNewRequestPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.forestGreen,
                    foregroundColor: AppColors.pureWhite,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(
                    'New request',
                    style: AppTypography.sans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.pureWhite,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (tickets.isEmpty)
            EmptyState(
              icon: Icons.build_outlined,
              title: 'No repair requests yet',
              message: onNewRequestPressed == null
                  ? 'Your tenancy has ended, so new requests are closed.'
                  : 'Report a problem and follow it here until it is fixed.',
            ),
          for (int i = 0; i < tickets.length; i++) ...[
            _RepairTicketCard(ticket: tickets[i]),
            if (i < tickets.length - 1) const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _RepairTicketCard extends StatelessWidget {
  const _RepairTicketCard({required this.ticket});

  final RepairTicket ticket;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${ticket.id} · ${ticket.category.label}',
                  style: AppTypography.sans(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              _RepairStatusBadge(status: ticket.status),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            ticket.title,
            style: AppTypography.sans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Row(
            children: [
              Expanded(
                child: Text(
                  ticket.subtitle,
                  style: AppTypography.sans(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (ticket.hasPhoto) ...[
                const SizedBox(width: AppSpacing.xs),
                const Icon(
                  Icons.camera_alt_outlined,
                  size: 16,
                  color: AppColors.textSubtle,
                ),
              ],
            ],
          ),
          if (ticket.visit != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _VisitPanel(visit: ticket.visit!),
          ],
        ],
      ),
    );
  }
}

/// Who's coming to fix it, their number and when, as staff entered them.
class _VisitPanel extends StatelessWidget {
  const _VisitPanel({required this.visit});

  final RepairVisit visit;

  Future<void> _call(BuildContext context) async {
    final phone = visit.phone;
    if (phone == null) return;
    var opened = false;
    try {
      opened = await launchUrl(Uri(scheme: 'tel', path: phone));
    } catch (_) {}
    if (opened || !context.mounted) return;
    // No phone app (tablet, simulator): hand over the number instead.
    await Clipboard.setData(ClipboardData(text: visit.phoneLabel ?? phone));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Number copied')));
  }

  @override
  Widget build(BuildContext context) {
    final phoneLabel = visit.phoneLabel;
    return Container(
      key: const ValueKey('repair_visit_panel'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.pageBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.mintBackground,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.handyman_outlined,
              size: 18,
              color: AppColors.mintAccent,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  visit.name,
                  style: AppTypography.sans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (phoneLabel != null)
                  Text(
                    phoneLabel,
                    style: AppTypography.sans(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                Text(
                  visit.whenLabel == null
                      ? 'Visit time to be confirmed'
                      : 'Visit ${visit.whenLabel}',
                  style: AppTypography.sans(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (visit.phone != null) ...[
            const SizedBox(width: AppSpacing.xs),
            Semantics(
              button: true,
              label: 'Call ${visit.name}',
              child: Material(
                color: AppColors.mintAccent,
                shape: const CircleBorder(),
                child: InkWell(
                  key: const ValueKey('repair_visit_call'),
                  customBorder: const CircleBorder(),
                  onTap: () => _call(context),
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(
                      Icons.call_rounded,
                      size: 18,
                      color: AppColors.pureWhite,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RepairStatusBadge extends StatelessWidget {
  const _RepairStatusBadge({required this.status});

  final RepairStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      RepairStatus.resolved => (
        AppColors.statusResolvedBackground,
        AppColors.statusResolvedText,
      ),
      RepairStatus.open => (
        AppColors.statusPartialBackground,
        AppColors.statusPartialText,
      ),
      RepairStatus.inProgress => (
        AppColors.statusCreditBackground,
        AppColors.statusCreditText,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        status.label,
        style: AppTypography.sans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: fg,
        ),
      ),
    );
  }
}

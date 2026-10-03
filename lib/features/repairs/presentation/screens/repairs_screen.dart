import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
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
                  onNewRequestPressed: notifier.openNewRequest,
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
  final VoidCallback onNewRequestPressed;

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
      RepairStatus.inReview => (
        const Color(0xFFFEF3C7),
        const Color(0xFFB45309),
      ),
      RepairStatus.inProgress => (
        const Color(0xFFE0F2FE),
        const Color(0xFF0369A1),
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

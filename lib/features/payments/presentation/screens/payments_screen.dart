import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/payment_receipt.dart';
import '../state/payments_providers.dart';
import '../widgets/receipt_detail_view.dart';

class PaymentsScreen extends ConsumerWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uiState = ref.watch(paymentsProvider);
    final notifier = ref.read(paymentsProvider.notifier);
    final theme = Theme.of(context);
    final motion =
        theme.extension<AppMotionThemeExtension>() ??
        const AppMotionThemeExtension.regular();

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
                  begin: const Offset(0, 0.03),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: uiState.selectedReceipt != null
              ? ReceiptDetailView(
                  key: ValueKey(uiState.selectedReceipt!.id),
                  receipt: uiState.selectedReceipt!,
                  onBackPressed: notifier.clearSelectedReceipt,
                )
              : _PaymentsListView(
                  key: const ValueKey('payments_list_view'),
                  receipts: uiState.receipts,
                  onReceiptSelected: notifier.selectReceipt,
                ),
        ),
      ),
    );
  }
}

class _PaymentsListView extends StatelessWidget {
  const _PaymentsListView({
    super.key,
    required this.receipts,
    required this.onReceiptSelected,
  });

  final List<PaymentReceipt> receipts;
  final ValueChanged<PaymentReceipt> onReceiptSelected;

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
          Text(
            'Payments',
            style: AppTypography.editorialSerif(
              fontSize: 38,
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Row(
            children: [
              Expanded(
                child: _StatCard(title: 'Paid in 2026', amount: 'KES 855,000'),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: _StatCard(title: 'Balance', amount: 'KES 45,000'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'RECEIPTS',
            style: AppTypography.sans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              children: [
                for (int i = 0; i < receipts.length; i++) ...[
                  if (i > 0)
                    const Divider(height: 1, color: AppColors.borderLight),
                  _ReceiptTile(
                    receipt: receipts[i],
                    onTap: () => onReceiptSelected(receipts[i]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.amount});

  final String title;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.sans(fontSize: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            amount,
            style: AppTypography.editorialSerif(
              fontSize: 26,
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ReceiptTile extends StatelessWidget {
  const _ReceiptTile({required this.receipt, required this.onTap});

  final PaymentReceipt receipt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.mintBackground,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  receipt.initial,
                  style: AppTypography.sans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mintAccent,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    receipt.forDescription,
                    style: AppTypography.sans(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    receipt.receiptNumber,
                    style: AppTypography.sans(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              receipt.amount,
              style: AppTypography.sans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

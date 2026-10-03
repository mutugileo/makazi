import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/payment_receipt.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../navigation/presentation/state/navigation_providers.dart';
import '../../../payments/presentation/state/payments_providers.dart';
import '../state/home_pay_rent_providers.dart';
import '../widgets/action_needed_card.dart';
import '../widgets/hero_balance_card.dart';
import '../widgets/pay_rent_flow_view.dart';
import '../widgets/recent_transactions_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navNotifier = ref.read(navigationProvider.notifier);
    final payRentState = ref.watch(homePayRentProvider);
    final payRentNotifier = ref.read(homePayRentProvider.notifier);
    final paymentsState = ref.watch(paymentsProvider);
    final theme = Theme.of(context);
    final motion =
        theme.extension<AppMotionThemeExtension>() ??
        const AppMotionThemeExtension.regular();

    ref.listen(homePayRentProvider, (previous, next) {
      if (next.completedReceipt != null &&
          previous?.completedReceipt != next.completedReceipt) {
        ref.read(paymentsProvider.notifier).addReceipt(next.completedReceipt!);
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
                  begin: const Offset(0, 0.05),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: payRentState.isPayRentOpen
              ? const PayRentFlowView(key: ValueKey('pay_rent_flow_view'))
              : _HomeDashboardView(
                  key: const ValueKey('home_dashboard_view'),
                  isPaid: payRentState.isBalancePaid,
                  transactions: paymentsState.receipts,
                  onPayRentPressed: payRentNotifier.openPayRent,
                  onSeeAllPressed: () {
                    ref.read(paymentsProvider.notifier).clearSelectedReceipt();
                    navNotifier.navigateToPayments();
                  },
                  onActionNeededPressed: navNotifier.navigateToMessages,
                  onTransactionTapped: (index) {
                    final receipts = paymentsState.receipts;
                    if (index < receipts.length) {
                      ref
                          .read(paymentsProvider.notifier)
                          .selectReceipt(receipts[index]);
                      navNotifier.navigateToPayments();
                    }
                  },
                ),
        ),
      ),
    );
  }
}

class _HomeDashboardView extends StatelessWidget {
  const _HomeDashboardView({
    super.key,
    required this.isPaid,
    required this.transactions,
    required this.onPayRentPressed,
    required this.onSeeAllPressed,
    required this.onActionNeededPressed,
    required this.onTransactionTapped,
  });

  final bool isPaid;
  final List<PaymentReceipt> transactions;
  final VoidCallback onPayRentPressed;
  final VoidCallback onSeeAllPressed;
  final VoidCallback onActionNeededPressed;
  final ValueChanged<int> onTransactionTapped;

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Riverside Court · 5A',
                      style: AppTypography.sans(
                        fontSize: 13,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Habari, David',
                      style: AppTypography.editorialSerif(
                        fontSize: 34,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.avatarBackground,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    'DM',
                    style: AppTypography.sans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.avatarText,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          HeroBalanceCard(isPaid: isPaid, onPayRentPressed: onPayRentPressed),
          const SizedBox(height: AppSpacing.md),
          ActionNeededCard(onActionPressed: onActionNeededPressed),
          const SizedBox(height: AppSpacing.lg),
          RecentTransactionsCard(
            transactions: transactions,
            onSeeAllPressed: onSeeAllPressed,
            onTransactionTapped: onTransactionTapped,
          ),
        ],
      ),
    );
  }
}

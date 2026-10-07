import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/billing/billing_engine.dart';
import '../../../../core/config/features.dart';
import '../../../../core/billing/billing_models.dart';
import '../../../../core/models/payment_receipt.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../billing/presentation/state/tenant_account_providers.dart';
import '../../../billing/presentation/state/tenant_account_state.dart';
import '../../../navigation/presentation/state/navigation_providers.dart';
import '../../../payments/presentation/state/payments_providers.dart';
import '../../../payments/presentation/state/payments_ui_state.dart';
import '../state/home_pay_rent_providers.dart';
import '../widgets/account_sheet.dart';
import '../widgets/action_needed_card.dart';
import '../widgets/current_bill_card.dart';
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
    final account = ref.watch(tenantAccountProvider);
    final paymentsNotifier = ref.read(paymentsProvider.notifier);
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
                  account: account,
                  onRefresh: () async {
                    await ref
                        .read(tenantAccountProvider.notifier)
                        .refreshFromDatabase();
                  },
                  onPayRentPressed: payRentNotifier.openPayRent,
                  onSeeAllPressed: () {
                    paymentsNotifier.resetToList(PaymentsView.receipts);
                    navNotifier.navigateToPayments();
                  },
                  onActionNeededPressed: navNotifier.navigateToMessages,
                  onBillPressed: (bill) {
                    paymentsNotifier.selectBill(bill.month);
                    navNotifier.navigateToPayments();
                  },
                  onTransactionTapped: (index) {
                    final receipts = account.receipts;
                    if (index < receipts.length) {
                      paymentsNotifier
                        ..resetToList(PaymentsView.receipts)
                        ..selectReceipt(receipts[index]);
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
    required this.account,
    required this.onRefresh,
    required this.onPayRentPressed,
    required this.onSeeAllPressed,
    required this.onActionNeededPressed,
    required this.onBillPressed,
    required this.onTransactionTapped,
  });

  final TenantAccountState account;
  final Future<void> Function() onRefresh;
  final VoidCallback onPayRentPressed;
  final VoidCallback onSeeAllPressed;
  final VoidCallback onActionNeededPressed;
  final ValueChanged<MonthlyBill> onBillPressed;
  final ValueChanged<int> onTransactionTapped;

  List<PaymentReceipt> get transactions => account.receipts;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final systemBottomPadding = mediaQuery.padding.bottom;
    final scrollBottomPadding = systemBottomPadding + 86.0;

    return RefreshIndicator(
      color: AppColors.forestGreen,
      backgroundColor: AppColors.cardBackground,
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
                        account.unitTitle,
                        style: AppTypography.sans(
                          fontSize: 13,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Habari, ${account.tenant.firstName}',
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
                Semantics(
                  button: true,
                  label: 'Account',
                  child: GestureDetector(
                    key: const ValueKey('account_avatar'),
                    onTap: () => showModalBottomSheet<void>(
                      context: context,
                      backgroundColor: AppColors.cardBackground,
                      showDragHandle: true,
                      builder: (_) => AccountSheet(account: account),
                    ),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppColors.avatarBackground,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          account.tenant.initials,
                          style: AppTypography.sans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.avatarText,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            HeroBalanceCard(
              bill: account.currentBill,
              isActive: account.isActive,
              asOf: account.seed.asOf,
              recordsKeptUntil: account.recordsKeptUntil,
              firstBillDate: account.firstBillDate,
              onPayRentPressed: onPayRentPressed,
              onBillPressed: account.currentBill != null
                  ? () => onBillPressed(account.currentBill!)
                  : null,
            ),
            if (kLeasesEnabled && account.tenancy.renewal != null) ...[
              const SizedBox(height: AppSpacing.md),
              ActionNeededCard(
                subtitle:
                    'From ${BillingDates.formatDayMonth(account.tenancy.renewal!.start)} '
                    '${account.tenancy.renewal!.start.substring(0, 4)} · '
                    '${formatKes(account.tenancy.renewal!.rent)} / month',
                onActionPressed: onActionNeededPressed,
              ),
            ],
            if (account.currentBill != null) ...[
              const SizedBox(height: AppSpacing.md),
              CurrentBillCard(
                bill: account.currentBill!,
                onTap: () => onBillPressed(account.currentBill!),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            RecentTransactionsCard(
              transactions: transactions,
              onSeeAllPressed: onSeeAllPressed,
              onTransactionTapped: onTransactionTapped,
            ),
          ],
        ),
      ),
    );
  }
}

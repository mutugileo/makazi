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
import '../../../notifications/presentation/screens/notifications_screen.dart';
import '../../../notifications/presentation/state/notifications_providers.dart';
import '../../../notifications/presentation/widgets/notification_cards.dart';
import '../../../payments/presentation/state/payments_providers.dart';
import '../../../payments/presentation/state/payments_ui_state.dart';
import '../state/home_pay_rent_providers.dart';
import '../widgets/account_sheet.dart';
import '../widgets/action_needed_card.dart';
import '../widgets/ask_nyumbani_promo_card.dart';
import '../widgets/current_bill_card.dart';
import '../widgets/hero_balance_card.dart';
import '../widgets/pay_rent_flow_view.dart';
import '../widgets/recent_transactions_card.dart';
import '../../../auth/presentation/state/auth_providers.dart';
import '../../../auth/presentation/widgets/change_pin_sheet.dart';
import '../../../shell/presentation/widgets/app_side_nav_drawer.dart';
import '../../../app_update/presentation/state/app_update_providers.dart';
import '../../../app_update/presentation/state/app_update_ui_state.dart';
import '../../../app_update/presentation/widgets/app_update_sheet.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navNotifier = ref.read(navigationProvider.notifier);
    final payRentState = ref.watch(homePayRentProvider);
    final payRentNotifier = ref.read(homePayRentProvider.notifier);
    final account = ref.watch(tenantAccountProvider);
    final unreadCount = ref.watch(unreadNotificationsProvider).length;
    final updateState = ref.watch(appUpdateProvider);
    final paymentsNotifier = ref.read(paymentsProvider.notifier);
    final theme = Theme.of(context);
    final motion =
        theme.extension<AppMotionThemeExtension>() ??
        const AppMotionThemeExtension.regular();

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      drawer: const AppSideNavDrawer(),
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
                  unreadCount: unreadCount,
                  isTemporaryPin: ref.watch(authProvider).isTemporaryPin,
                  updateState: updateState,
                  onDismissUpdate: () => ref
                      .read(appUpdateProvider.notifier)
                      .dismissUpdateNotice(),
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
    required this.unreadCount,
    required this.isTemporaryPin,
    required this.updateState,
    required this.onDismissUpdate,
    required this.onRefresh,
    required this.onPayRentPressed,
    required this.onSeeAllPressed,
    required this.onActionNeededPressed,
    required this.onBillPressed,
    required this.onTransactionTapped,
  });

  final TenantAccountState account;
  final int unreadCount;
  final bool isTemporaryPin;
  final AppUpdateUiState updateState;
  final VoidCallback onDismissUpdate;
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

    final companyTheme = account.company.settings.theme;

    return RefreshIndicator(
      color: companyTheme.primaryColor,
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
                  child: Row(
                    children: [
                      Builder(
                        builder: (scaffoldContext) => Semantics(
                          button: true,
                          label: 'Navigation menu',
                          child: GestureDetector(
                            key: const ValueKey('home_side_nav_button'),
                            onTap: () =>
                                Scaffold.of(scaffoldContext).openDrawer(),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.cardBackground,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.borderLight,
                                ),
                              ),
                              child: const Icon(
                                Icons.menu_rounded,
                                color: AppColors.textPrimary,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Habari, ${account.tenant.firstName}',
                              style: AppTypography.editorialSerif(
                                fontSize: 26,
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
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Semantics(
                      button: true,
                      label: 'Notifications',
                      child: GestureDetector(
                        key: const ValueKey('home_notifications_bell'),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const NotificationsScreen(),
                          ),
                        ),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              const Icon(
                                Icons.notifications_none_rounded,
                                color: AppColors.textPrimary,
                                size: 22,
                              ),
                              if (unreadCount > 0)
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: companyTheme.primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Semantics(
                      button: true,
                      label: 'Account',
                      child: GestureDetector(
                        key: const ValueKey('account_avatar'),
                        onTap: () => showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: AppColors.cardBackground,
                          showDragHandle: true,
                          builder: (_) => AccountSheet(account: account),
                        ),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: companyTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              account.tenant.initials,
                              style: AppTypography.sans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: companyTheme.onPrimaryColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (updateState.isUpdateAvailable &&
                !updateState.hasDismissedNotice) ...[
              Container(
                key: const ValueKey('home_update_banner'),
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: companyTheme.primaryColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: companyTheme.primaryColor.withValues(
                          alpha: 0.12,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.system_update_rounded,
                        color: companyTheme.primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  'Update Available',
                                  style: AppTypography.sans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.mintBackground,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'v${updateState.updateInfo.latestVersion}',
                                  style: AppTypography.sans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.mintAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Vacation notice & move-out inspection',
                            style: AppTypography.sans(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    ElevatedButton(
                      key: const ValueKey('home_update_banner_button'),
                      onPressed: () => AppUpdateSheet.show(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: companyTheme.primaryColor,
                        foregroundColor: companyTheme.onPrimaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Update',
                        style: AppTypography.sans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: companyTheme.onPrimaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      key: const ValueKey('home_update_banner_dismiss'),
                      tooltip: 'Dismiss update notice',
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      onPressed: onDismissUpdate,
                    ),
                  ],
                ),
              ),
            ],
            const NotificationCards(),
            if (isTemporaryPin) ...[
              Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.terracottaLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.terracotta.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.terracotta.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.lock_clock_outlined,
                        color: AppColors.terracotta,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Temporary PIN · 72h window',
                            style: AppTypography.sans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.terracotta,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            'Choose your personal 4-digit PIN to secure your account.',
                            style: AppTypography.sans(
                              fontSize: 11,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    ElevatedButton(
                      key: const ValueKey('home_set_permanent_pin_button'),
                      onPressed: () =>
                          ChangePinSheet.show(context, isTemporaryPrompt: true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: companyTheme.primaryColor,
                        foregroundColor: companyTheme.onPrimaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Set PIN',
                        style: AppTypography.sans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: companyTheme.onPrimaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            HeroBalanceCard(
              bill: account.currentBill,
              isActive: account.isActive,
              asOf: account.seed.asOf,
              recordsKeptUntil: account.recordsKeptUntil,
              firstBillDate: account.firstBillDate,
              theme: companyTheme,
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
              theme: companyTheme,
              onSeeAllPressed: onSeeAllPressed,
              onTransactionTapped: onTransactionTapped,
            ),
            const SizedBox(height: AppSpacing.lg),
            const AskNyumbaniPromoCard(),
          ],
        ),
      ),
    );
  }
}

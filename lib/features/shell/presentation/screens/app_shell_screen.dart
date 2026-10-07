import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../billing/presentation/state/tenant_account_providers.dart';
import '../../../home/domain/models/pay_rent_models.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../home/presentation/state/home_pay_rent_providers.dart';
import '../../../messages/presentation/screens/messages_screen.dart';
import '../../../navigation/domain/models/app_tab.dart';
import '../../../navigation/presentation/state/navigation_providers.dart';
import '../../../navigation/presentation/widgets/floating_pill_nav_bar.dart';
import '../../../payments/presentation/screens/payments_screen.dart';
import '../../../payments/presentation/state/payments_providers.dart';
import '../../../repairs/presentation/screens/repairs_screen.dart';
import '../../../repairs/presentation/state/repairs_providers.dart';

class AppShellScreen extends ConsumerWidget {
  const AppShellScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navState = ref.watch(navigationProvider);
    final theme = Theme.of(context);
    final motion =
        theme.extension<AppMotionThemeExtension>() ??
        const AppMotionThemeExtension.regular();

    final isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final canHandleBack = _canHandleBack(ref);

    return PopScope(
      canPop: !canHandleBack,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack(ref);
      },
      child: Scaffold(
        backgroundColor: AppColors.pageBackground,
        extendBody: true,
        body: AnimatedSwitcher(
          duration: motion.stateTransitionDuration,
          switchInCurve: motion.standardEasing,
          switchOutCurve: motion.standardEasing,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.02, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: _buildCurrentScreen(navState.currentTab),
        ),
        bottomNavigationBar: isKeyboardOpen
            ? null
            : FloatingPillNavBar(
                currentTab: navState.currentTab,
                onTabSelected: (tab) {
                  ref.read(navigationProvider.notifier).selectTab(tab);
                  if (tab == AppTab.home) {
                    ref
                        .read(tenantAccountProvider.notifier)
                        .refreshFromDatabase();
                  }
                },
              ),
      ),
    );
  }

  bool _canHandleBack(WidgetRef ref) {
    final navState = ref.watch(navigationProvider);
    switch (navState.currentTab) {
      case AppTab.home:
        final payRent = ref.watch(homePayRentProvider);
        if (payRent.isPayRentOpen) return true;
        return navState.canPopTab;
      case AppTab.payments:
        final payments = ref.watch(paymentsProvider);
        if (payments.showingStatement ||
            payments.selectedReceipt != null ||
            payments.selectedBillMonth != null) {
          return true;
        }
        return navState.canPopTab;
      case AppTab.repairs:
        final repairs = ref.watch(repairsProvider);
        if (repairs.isNewRequestOpen) return true;
        return navState.canPopTab;
      case AppTab.messages:
        return navState.canPopTab;
    }
  }

  void _handleBack(WidgetRef ref) {
    final navNotifier = ref.read(navigationProvider.notifier);
    final navState = ref.read(navigationProvider);

    switch (navState.currentTab) {
      case AppTab.home:
        final payRent = ref.read(homePayRentProvider);
        final payRentNotifier = ref.read(homePayRentProvider.notifier);
        if (payRent.isPayRentOpen) {
          if (payRent.showingReceiptDetail) {
            payRentNotifier.closeReceiptDetail();
          } else if (payRent.step == PayRentStep.confirming) {
            // Dismissal is ignored while a payment is actively confirming.
          } else if (payRent.step == PayRentStep.received) {
            payRentNotifier.finishPayRent();
          } else {
            payRentNotifier.closePayRent();
          }
          return;
        }
        if (navState.canPopTab) {
          navNotifier.popTab();
        }
        return;

      case AppTab.payments:
        final payments = ref.read(paymentsProvider);
        final paymentsNotifier = ref.read(paymentsProvider.notifier);
        if (payments.showingStatement) {
          paymentsNotifier.closeStatement();
          return;
        }
        if (payments.selectedReceipt != null) {
          paymentsNotifier.clearSelectedReceipt();
          return;
        }
        if (payments.selectedBillMonth != null) {
          paymentsNotifier.clearSelectedBill();
          return;
        }
        if (navState.canPopTab) {
          navNotifier.popTab();
        }
        return;

      case AppTab.repairs:
        final repairs = ref.read(repairsProvider);
        final repairsNotifier = ref.read(repairsProvider.notifier);
        if (repairs.isNewRequestOpen) {
          repairsNotifier.closeNewRequest();
          return;
        }
        if (navState.canPopTab) {
          navNotifier.popTab();
        }
        return;

      case AppTab.messages:
        if (navState.canPopTab) {
          navNotifier.popTab();
        }
        return;
    }
  }

  Widget _buildCurrentScreen(AppTab tab) {
    switch (tab) {
      case AppTab.home:
        return const HomeScreen(key: ValueKey(AppTab.home));
      case AppTab.payments:
        return const PaymentsScreen(key: ValueKey(AppTab.payments));
      case AppTab.repairs:
        return const RepairsScreen(key: ValueKey(AppTab.repairs));
      case AppTab.messages:
        return const MessagesScreen(key: ValueKey(AppTab.messages));
    }
  }
}

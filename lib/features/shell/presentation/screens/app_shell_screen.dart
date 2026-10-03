import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../messages/presentation/screens/messages_screen.dart';
import '../../../navigation/domain/models/app_tab.dart';
import '../../../navigation/presentation/state/navigation_providers.dart';
import '../../../navigation/presentation/widgets/floating_pill_nav_bar.dart';
import '../../../payments/presentation/screens/payments_screen.dart';
import '../../../repairs/presentation/screens/repairs_screen.dart';

class AppShellScreen extends ConsumerWidget {
  const AppShellScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navState = ref.watch(navigationProvider);
    final theme = Theme.of(context);
    final motion =
        theme.extension<AppMotionThemeExtension>() ??
        const AppMotionThemeExtension.regular();

    return Scaffold(
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
      bottomNavigationBar: FloatingPillNavBar(
        currentTab: navState.currentTab,
        onTabSelected: (tab) {
          ref.read(navigationProvider.notifier).selectTab(tab);
        },
      ),
    );
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

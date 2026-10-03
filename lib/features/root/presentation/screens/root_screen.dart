import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/models/root_navigation_destination.dart';
import '../state/root_navigation_providers.dart';
import '../widgets/root_destination_view.dart';

class RootScreen extends ConsumerWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uiState = ref.watch(rootNavigationProvider);
    final theme = Theme.of(context);
    final spacing =
        theme.extension<AppSpacingThemeExtension>() ??
        const AppSpacingThemeExtension.regular();
    final motion =
        theme.extension<AppMotionThemeExtension>() ??
        const AppMotionThemeExtension.regular();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideLayout = constraints.maxWidth >= 720;

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(spacing.radiusSm),
                  ),
                  child: const Icon(
                    Icons.real_estate_agent_rounded,
                    color: AppColors.pureWhite,
                    size: 18,
                  ),
                ),
                SizedBox(width: spacing.sm),
                Text(
                  'EstatePulse',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.search_rounded),
                tooltip: 'Search portfolio',
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none_rounded),
                tooltip: 'Notifications',
              ),
              SizedBox(width: spacing.xs),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(color: theme.dividerTheme.color, height: 1),
            ),
          ),
          body: Row(
            children: [
              if (isWideLayout)
                NavigationRail(
                  selectedIndex: uiState.selectedDestination.index,
                  onDestinationSelected: (index) {
                    final destination = RootNavigationDestination.values[index];
                    ref
                        .read(rootNavigationProvider.notifier)
                        .selectNavigationDestination(destination);
                  },
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    for (final destination in RootNavigationDestination.values)
                      NavigationRailDestination(
                        icon: Icon(destination.icon),
                        selectedIcon: Icon(destination.selectedIcon),
                        label: Text(destination.label),
                      ),
                  ],
                ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: motion.stateTransitionDuration,
                  switchInCurve: motion.standardEasing,
                  switchOutCurve: motion.standardEasing,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.015, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: RootDestinationView(
                    key: ValueKey(uiState.selectedDestination),
                    destination: uiState.selectedDestination,
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: isWideLayout
              ? null
              : NavigationBar(
                  selectedIndex: uiState.selectedDestination.index,
                  onDestinationSelected: (index) {
                    final destination = RootNavigationDestination.values[index];
                    ref
                        .read(rootNavigationProvider.notifier)
                        .selectNavigationDestination(destination);
                  },
                  destinations: [
                    for (final destination in RootNavigationDestination.values)
                      NavigationDestination(
                        icon: Icon(destination.icon),
                        selectedIcon: Icon(destination.selectedIcon),
                        label: destination.label,
                      ),
                  ],
                ),
        );
      },
    );
  }
}

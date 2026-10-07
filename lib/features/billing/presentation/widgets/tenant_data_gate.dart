import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/data/data_mode.dart';
import '../../../../core/data/supabase_billing_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../auth/presentation/state/auth_providers.dart';
import '../state/tenant_account_providers.dart';
import 'account_skeleton.dart';

/// Shows [child] only once the tenant's own data has loaded from the
/// database. Until then: a shimmering outline of the home screen, or what
/// went wrong with a retry.
/// Never demo data. Outside live mode it shows [child] straight away.
class TenantDataGate extends ConsumerWidget {
  const TenantDataGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(liveDataProvider)) return child;
    ref.watch(tenantRealtimeProvider);
    final data = ref.watch(liveTenantSeedProvider);
    final motion =
        Theme.of(context).extension<AppMotionThemeExtension>() ??
        const AppMotionThemeExtension.regular();

    final Widget gateView;
    if (data.value != null) {
      if (!data.hasError || data.isLoading) {
        gateView = KeyedSubtree(
          key: const ValueKey('tenant_data_content'),
          child: child,
        );
      } else {
        // A refresh failed: keep showing what loaded, and say so.
        gateView = Stack(
          key: const ValueKey('tenant_data_stale'),
          children: [
            child,
            Positioned(
              top: MediaQuery.paddingOf(context).top + AppSpacing.xs,
              left: AppSpacing.md,
              right: AppSpacing.md,
              child: _StaleBanner(
                onRetry: () => ref.invalidate(liveTenantSeedProvider),
              ),
            ),
          ],
        );
      }
    } else if (data.isLoading || !data.hasError) {
      // First load: the home screen's outline, shimmering, in place of the
      // content that's on its way.
      gateView = const Scaffold(
        key: ValueKey('tenant_data_loading_scaffold'),
        backgroundColor: AppColors.pageBackground,
        body: SafeArea(
          child: AccountSkeleton(key: ValueKey('tenant_data_loading')),
        ),
      );
    } else {
      final Widget body;
      if (data.error is NoTenancyFound) {
        body = _Problem(
          key: const ValueKey('tenant_data_none'),
          icon: Icons.home_outlined,
          title: 'No home linked to this number yet',
          message:
              'Your property manager adds you when your lease starts. '
              'If you think this is a mistake, contact them.',
          onRetry: () => ref.invalidate(liveTenantSeedProvider),
        );
      } else {
        body = _Problem(
          key: const ValueKey('tenant_data_error'),
          icon: Icons.wifi_off_rounded,
          title: 'Couldn\'t load your account',
          message: 'Check your connection and try again.',
          onRetry: () => ref.invalidate(liveTenantSeedProvider),
        );
      }

      gateView = Scaffold(
        key: const ValueKey('tenant_data_problem_scaffold'),
        backgroundColor: AppColors.pageBackground,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                body,
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: () => ref.read(authProvider.notifier).signOut(),
                  child: Text(
                    'Sign out',
                    style: AppTypography.sans(
                      fontSize: 14,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return AnimatedSwitcher(
      duration: motion.stateTransitionDuration,
      switchInCurve: motion.standardEasing,
      switchOutCurve: motion.standardEasing,
      child: gateView,
    );
  }
}

class _Problem extends StatelessWidget {
  const _Problem({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        EmptyState(icon: icon, title: title, message: message),
        ElevatedButton(
          onPressed: onRetry,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.mintAccent,
            foregroundColor: AppColors.pureWhite,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text('Try again'),
        ),
      ],
    );
  }
}

class _StaleBanner extends StatelessWidget {
  const _StaleBanner({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.forestGreen,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.only(left: AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Couldn\'t refresh. Showing your account as last loaded.',
                style: AppTypography.sans(
                  fontSize: 13,
                  color: AppColors.pureWhite,
                ),
              ),
            ),
            TextButton(
              onPressed: onRetry,
              child: Text(
                'Retry',
                style: AppTypography.sans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.pureWhite,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

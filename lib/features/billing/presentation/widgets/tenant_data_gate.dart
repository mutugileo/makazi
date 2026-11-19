import 'package:prop_mgt_app/core/theme/brand_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/data/data_mode.dart';
import '../../../../core/data/supabase_billing_repository.dart';
import '../../../../core/platform/platform_channel_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
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
      final isNoTenancy = data.error is NoTenancyFound;
      final body = isNoTenancy
          ? _Problem(
              key: const ValueKey('tenant_data_none'),
              icon: Icons.home_outlined,
              iconColor: context.brand.link,
              iconBackground: context.brand.link.withValues(alpha: 0.12),
              title: 'No home linked to this number yet',
              message:
                  'Your property manager adds you when your lease starts. '
                  'If you think this is a mistake, contact them.',
              onRetry: () => ref.invalidate(liveTenantSeedProvider),
            )
          : _Problem(
              key: const ValueKey('tenant_data_error'),
              icon: Icons.wifi_off_rounded,
              iconColor: AppColors.terracotta,
              iconBackground: AppColors.terracottaLight,
              title: 'No internet connection',
              message:
                  'We couldn\'t reach Makazi. Check your Wi-Fi or mobile data and try again.',
              onRetry: () => ref.invalidate(liveTenantSeedProvider),
              onOpenSettings: () =>
                  ref.read(networkStatusProvider.notifier).openSettings(),
            );

      gateView = Scaffold(
        key: const ValueKey('tenant_data_problem_scaffold'),
        backgroundColor: AppColors.pageBackground,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    body,
                    const SizedBox(height: AppSpacing.md),
                    TextButton(
                      onPressed: () =>
                          ref.read(authProvider.notifier).signOut(),
                      child: Text(
                        'Sign out',
                        style: AppTypography.sans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.message,
    required this.onRetry,
    this.onOpenSettings,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String message;
  final VoidCallback onRetry;
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: iconBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28, color: iconColor),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.editorialSerif(
              fontSize: 22,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.sans(
              fontSize: 14,
              color: AppColors.textMuted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.brand.button,
                foregroundColor: context.brand.onButton,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Try again',
                style: AppTypography.sans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (onOpenSettings != null) ...[
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton(
                onPressed: onOpenSettings,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.borderLight),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Network settings',
                  style: AppTypography.sans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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

class _StaleBanner extends StatelessWidget {
  const _StaleBanner({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.brand.ink,
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

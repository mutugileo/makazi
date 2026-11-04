import 'package:prop_mgt_app/core/theme/brand_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/state/auth_providers.dart';
import '../../../auth/presentation/widgets/change_pin_sheet.dart';
import '../../../billing/presentation/state/tenant_account_providers.dart';
import '../../../billing/presentation/state/tenant_account_state.dart';
import '../../../navigation/presentation/state/navigation_providers.dart';
import '../../../notifications/presentation/screens/notifications_screen.dart';
import '../../../notifications/presentation/state/notifications_providers.dart';
import '../../../payments/presentation/state/payments_providers.dart';
import '../../../vacation_notice/presentation/widgets/vacation_notice_sheet.dart';
import '../../../shell/presentation/widgets/app_side_nav_drawer.dart';
import '../../../app_update/presentation/state/app_update_providers.dart';
import '../../../app_update/presentation/widgets/app_update_sheet.dart';
import '../state/home_pay_rent_providers.dart';

/// Tenant profile and settings sheet.
class AccountSheet extends ConsumerWidget {
  const AccountSheet({super.key, required this.account});

  final TenantAccountState account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationsProvider);
    final updateState = ref.watch(appUpdateProvider);
    final authState = ref.watch(authProvider);
    final bioLabel = authState.biometricLabel;
    final isFace = bioLabel?.toLowerCase().contains('face') ?? false;

    final companyTheme = account.company.settings.theme;

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                account.tenant.name,
                style: AppTypography.editorialSerif(
                  fontSize: 26,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${account.tenant.phone} · ${account.unitTitle}\n'
                'Landlord: ${account.company.name}',
                style: AppTypography.sans(
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Material(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(18),
                clipBehavior: Clip.antiAlias,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    children: [
                      InkWell(
                        key: const ValueKey('account_change_pin_tile'),
                        onTap: () {
                          Navigator.of(context).pop();
                          ChangePinSheet.show(context);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: companyTheme.accentColor.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.key_outlined,
                                  color: companyTheme.primaryColor,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Change 4-digit PIN',
                                      style: AppTypography.sans(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      'Update the PIN used to log in',
                                      style: AppTypography.sans(
                                        fontSize: 12,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.textMuted,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (bioLabel != null) ...[
                        const Divider(height: 1, color: AppColors.borderLight),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: companyTheme.primaryColor.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  isFace
                                      ? Icons.face_rounded
                                      : Icons.fingerprint_rounded,
                                  color: companyTheme.primaryColor,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isFace
                                          ? 'Face unlock'
                                          : 'Fingerprint unlock',
                                      style: AppTypography.sans(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      'Quick unlock without typing your PIN',
                                      style: AppTypography.sans(
                                        fontSize: 12,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch.adaptive(
                                key: const ValueKey(
                                  'account_biometrics_switch',
                                ),
                                value: authState.biometricsEnabled,
                                activeTrackColor: companyTheme.primaryColor,
                                onChanged: (enabled) {
                                  ref
                                      .read(authProvider.notifier)
                                      .toggleBiometrics(enabled);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                      const Divider(height: 1, color: AppColors.borderLight),
                      InkWell(
                        key: const ValueKey('account_notifications_tile'),
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const NotificationsScreen(),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: companyTheme.primaryColor.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.notifications_none_rounded,
                                  color: companyTheme.primaryColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Notifications',
                                      style: AppTypography.sans(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      unread.isEmpty
                                          ? 'No unread alerts'
                                          : '${unread.length} unread notification${unread.length == 1 ? '' : 's'}',
                                      style: AppTypography.sans(
                                        fontSize: 12,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (unread.isNotEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.limeSoft,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${unread.length}',
                                    style: AppTypography.sans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: context.brand.ink,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                              ],
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.textMuted,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 1, color: AppColors.borderLight),
                      InkWell(
                        key: const ValueKey('account_vacation_notice_tile'),
                        onTap: () {
                          Navigator.of(context).pop();
                          VacationNoticeSheet.show(context);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.mintBackground,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.door_back_door_outlined,
                                  color: AppColors.mintAccent,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Notice to Vacate',
                                      style: AppTypography.sans(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      'Schedule move-out & inspection',
                                      style: AppTypography.sans(
                                        fontSize: 12,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.textMuted,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 1, color: AppColors.borderLight),
                      InkWell(
                        key: const ValueKey('account_rate_playstore_tile'),
                        onTap: () {
                          Navigator.of(context).pop();
                          AppSideNavDrawer.launchPlayStoreRating(context);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.statusPartialBackground,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.star_rate_rounded,
                                  color: AppColors.statusPartialText,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Rate Makazi on Play Store',
                                      style: AppTypography.sans(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      'Rate on Google Play',
                                      style: AppTypography.sans(
                                        fontSize: 12,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.textMuted,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 1, color: AppColors.borderLight),
                      InkWell(
                        key: const ValueKey('account_check_updates_tile'),
                        onTap: () {
                          Navigator.of(context).pop();
                          AppUpdateSheet.show(context);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: companyTheme.primaryColor.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.system_update_outlined,
                                  color: companyTheme.primaryColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Check for Updates',
                                      style: AppTypography.sans(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      updateState.isUpdateAvailable
                                          ? 'Version ${updateState.updateInfo.latestVersion} available'
                                          : 'App is up to date (v${updateState.updateInfo.currentVersion})',
                                      style: AppTypography.sans(
                                        fontSize: 12,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (updateState.isUpdateAvailable) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.mintBackground,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'NEW',
                                    style: AppTypography.sans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.mintAccent,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                              ],
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.textMuted,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'To update your registered phone number, contact your property manager.',
                style: AppTypography.sans(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () async {
                    final container = ProviderScope.containerOf(
                      context,
                      listen: false,
                    );
                    Navigator.of(context).pop();
                    await container.read(authProvider.notifier).signOut();
                    container
                      ..invalidate(tenantAccountProvider)
                      ..invalidate(homePayRentProvider)
                      ..invalidate(paymentsProvider)
                      ..invalidate(navigationProvider);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.borderLight),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Sign out',
                    style: AppTypography.sans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.statusUnpaidText,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

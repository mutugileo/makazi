import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/billing/billing_engine.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/state/auth_providers.dart';
import '../../../auth/presentation/widgets/change_pin_sheet.dart';
import '../../../billing/presentation/state/tenant_account_providers.dart';
import '../../../home/presentation/state/home_pay_rent_providers.dart';
import '../../../navigation/domain/models/app_tab.dart';
import '../../../navigation/presentation/state/navigation_providers.dart';
import '../../../notifications/presentation/screens/notifications_screen.dart';
import '../../../notifications/presentation/state/notifications_providers.dart';
import '../../../payments/presentation/state/payments_providers.dart';
import '../../../vacation_notice/presentation/state/vacation_notice_providers.dart';
import '../../../vacation_notice/presentation/widgets/vacation_notice_sheet.dart';
import '../../../app_update/presentation/state/app_update_providers.dart';
import '../../../app_update/presentation/widgets/app_update_sheet.dart';

class AppSideNavDrawer extends ConsumerWidget {
  const AppSideNavDrawer({super.key});

  static const String playStoreMarketUrl =
      'market://details?id=com.codzure.makazi';
  static const String playStoreWebUrl =
      'https://play.google.com/store/apps/details?id=com.codzure.makazi';

  static Future<void> launchPlayStoreRating(BuildContext context) async {
    final marketUri = Uri.parse(playStoreMarketUrl);
    final webUri = Uri.parse(playStoreWebUrl);

    try {
      final launchedMarket = await launchUrl(
        marketUri,
        mode: LaunchMode.externalApplication,
      );
      if (launchedMarket) return;
    } catch (_) {
      // Fall through to browser URL
    }

    try {
      final launchedWeb = await launchUrl(
        webUri,
        mode: LaunchMode.externalApplication,
      );
      if (launchedWeb) return;
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unable to open Google Play Store',
              style: AppTypography.sans(
                fontSize: 14,
                color: AppColors.pureWhite,
              ),
            ),
            backgroundColor: AppColors.textPrimary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(tenantAccountProvider);
    final navNotifier = ref.read(navigationProvider.notifier);
    final navState = ref.watch(navigationProvider);
    final vacationState = ref.watch(vacationNoticeProvider);
    final updateState = ref.watch(appUpdateProvider);
    final unreadCount = ref.watch(unreadNotificationsProvider).length;
    final companyTheme = account.company.settings.theme;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final drawerWidth = math.min(320.0, screenWidth * 0.84);

    return Drawer(
      key: const ValueKey('app_side_nav_drawer'),
      width: drawerWidth,
      backgroundColor: AppColors.cardBackground,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Header with tenant information
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                MediaQuery.paddingOf(context).top + 18,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              decoration: BoxDecoration(color: companyTheme.primaryColor),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: companyTheme.onPrimaryColor.withValues(
                            alpha: 0.12,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: companyTheme.onPrimaryColor.withValues(
                              alpha: 0.25,
                            ),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          account.tenant.initials,
                          style: AppTypography.editorialSerif(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: companyTheme.onPrimaryColor,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: companyTheme.onPrimaryColor.withValues(
                            alpha: 0.12,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: companyTheme.onPrimaryColor.withValues(
                              alpha: 0.25,
                            ),
                          ),
                        ),
                        child: Text(
                          'Active Tenancy',
                          style: AppTypography.sans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: companyTheme.onPrimaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    account.tenant.name,
                    style: AppTypography.editorialSerif(
                      fontSize: 22,
                      fontWeight: FontWeight.w400,
                      color: companyTheme.onPrimaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${account.unitTitle} · ${account.company.name}',
                    style: AppTypography.sans(
                      fontSize: 13,
                      color: companyTheme.onPrimaryColor.withValues(
                        alpha: 0.75,
                      ),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    account.tenant.phone,
                    style: AppTypography.sans(
                      fontSize: 12,
                      color: companyTheme.onPrimaryColor.withValues(
                        alpha: 0.75,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Menu List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                children: [
                  // PRIMARY FEATURE: Vacation Notice Button
                  Material(
                    color: AppColors.pageBackground,
                    borderRadius: BorderRadius.circular(16),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      key: const ValueKey('drawer_vacation_notice_button'),
                      onTap: () {
                        Navigator.of(context).pop(); // close drawer
                        VacationNoticeSheet.show(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: vacationState.hasActiveNotice
                                ? AppColors.statusPaidBorder
                                : AppColors.borderLight,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: vacationState.hasActiveNotice
                                    ? AppColors.statusPaidBackground
                                    : AppColors.mintBackground,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                vacationState.hasActiveNotice
                                    ? Icons.event_available_rounded
                                    : Icons.door_back_door_outlined,
                                color: vacationState.hasActiveNotice
                                    ? AppColors.statusPaidText
                                    : AppColors.mintAccent,
                                size: 22,
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
                                          'Vacation Notice',
                                          style: AppTypography.sans(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (vacationState.hasActiveNotice) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                AppColors.statusPaidBackground,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            'Active',
                                            style: AppTypography.sans(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.statusPaidText,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    vacationState.hasActiveNotice
                                        ? 'Move out: ${BillingDates.formatDayMonth(vacationState.activeNotice!.vacatingDate)}'
                                        : 'Indicate vacating & inspection dates',
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
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.textMuted,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),
                  const Divider(height: 1, color: AppColors.borderLight),
                  const SizedBox(height: AppSpacing.sm),

                  // Standard App Tabs
                  _DrawerNavItem(
                    icon: Icons.dashboard_outlined,
                    label: 'Home Dashboard',
                    isSelected: navState.currentTab == AppTab.home,
                    onTap: () {
                      Navigator.of(context).pop();
                      navNotifier.selectTab(AppTab.home);
                    },
                  ),
                  _DrawerNavItem(
                    icon: Icons.receipt_long_outlined,
                    label: 'Payments & Receipts',
                    isSelected: navState.currentTab == AppTab.payments,
                    onTap: () {
                      Navigator.of(context).pop();
                      navNotifier.selectTab(AppTab.payments);
                    },
                  ),
                  _DrawerNavItem(
                    icon: Icons.build_outlined,
                    label: 'Repairs & Requests',
                    isSelected: navState.currentTab == AppTab.repairs,
                    onTap: () {
                      Navigator.of(context).pop();
                      navNotifier.selectTab(AppTab.repairs);
                    },
                  ),
                  _DrawerNavItem(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Messages with Manager',
                    isSelected: navState.currentTab == AppTab.messages,
                    onTap: () {
                      Navigator.of(context).pop();
                      navNotifier.selectTab(AppTab.messages);
                    },
                  ),

                  const SizedBox(height: AppSpacing.sm),
                  const Divider(height: 1, color: AppColors.borderLight),
                  const SizedBox(height: AppSpacing.sm),

                  // Notifications
                  _DrawerNavItem(
                    icon: Icons.notifications_none_rounded,
                    label: 'Notifications',
                    badgeCount: unreadCount,
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );
                    },
                  ),

                  // Change PIN
                  _DrawerNavItem(
                    icon: Icons.key_outlined,
                    label: 'Change PIN',
                    onTap: () {
                      Navigator.of(context).pop();
                      ChangePinSheet.show(context);
                    },
                  ),

                  // RATE MAKAZI ON PLAY STORE (Requested Feature)
                  _DrawerNavItem(
                    key: const ValueKey('drawer_rate_playstore_button'),
                    icon: Icons.star_rate_rounded,
                    iconColor: AppColors.statusPartialText,
                    label: 'Rate Makazi on Play Store',
                    trailing: const Icon(
                      Icons.open_in_new_rounded,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      launchPlayStoreRating(context);
                    },
                  ),

                  // IN-APP UPDATE ACTION
                  _DrawerNavItem(
                    key: const ValueKey('drawer_check_updates_tile'),
                    icon: Icons.system_update_outlined,
                    iconColor: updateState.isUpdateAvailable
                        ? companyTheme.primaryColor
                        : AppColors.textSecondary,
                    label: updateState.isUpdateAvailable
                        ? 'Update available (v${updateState.updateInfo.latestVersion})'
                        : 'Check for app updates',
                    trailing: updateState.isUpdateAvailable
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.mintBackground,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'NEW',
                              style: AppTypography.sans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.mintAccent,
                              ),
                            ),
                          )
                        : null,
                    onTap: () {
                      Navigator.of(context).pop();
                      AppUpdateSheet.show(context);
                    },
                  ),
                ],
              ),
            ),

            // Footer with Version & Sign Out
            const Divider(height: 1, color: AppColors.borderLight),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Makazi Tenant',
                          style: AppTypography.sans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'v1.0.3 · Nairobi, Kenya',
                          style: AppTypography.sans(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    key: const ValueKey('drawer_sign_out_button'),
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
                        ..invalidate(navigationProvider)
                        ..invalidate(vacationNoticeProvider);
                    },
                    icon: const Icon(
                      Icons.logout_rounded,
                      size: 18,
                      color: AppColors.statusUnpaidText,
                    ),
                    label: Text(
                      'Sign out',
                      style: AppTypography.sans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.statusUnpaidText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerNavItem extends StatelessWidget {
  const _DrawerNavItem({
    super.key,
    required this.icon,
    this.iconColor,
    required this.label,
    this.isSelected = false,
    this.badgeCount = 0,
    this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final Color? iconColor;
  final String label;
  final bool isSelected;
  final int badgeCount;
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.pageBackground : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        onTap: onTap,
        dense: true,
        horizontalTitleGap: 12,
        leading: Icon(
          icon,
          size: 22,
          color:
              iconColor ??
              (isSelected ? AppColors.forestGreen : AppColors.textSecondary),
        ),
        title: Text(
          label,
          style: AppTypography.sans(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? AppColors.forestGreen : AppColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing:
            trailing ??
            (badgeCount > 0
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.limeAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$badgeCount',
                      style: AppTypography.sans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.forestGreenDark,
                      ),
                    ),
                  )
                : null),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../notifications/presentation/screens/notifications_screen.dart';
import '../../../notifications/presentation/state/notifications_providers.dart';
import '../../../billing/presentation/state/tenant_account_providers.dart';
import '../../../home/domain/models/pay_rent_models.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../home/presentation/state/home_pay_rent_providers.dart';
import '../../../messages/presentation/screens/messages_screen.dart';
import '../../../messages/presentation/state/messages_providers.dart';
import '../../../navigation/domain/models/app_tab.dart';
import '../../../navigation/presentation/state/navigation_providers.dart';
import '../../../navigation/presentation/widgets/floating_pill_nav_bar.dart';
import '../../../payments/presentation/screens/payments_screen.dart';
import '../../../payments/presentation/state/payments_providers.dart';
import '../../../repairs/presentation/screens/repairs_screen.dart';
import '../../../repairs/presentation/state/repairs_providers.dart';
import '../../../../core/platform/platform_channel_service.dart';
import '../../../auth/presentation/state/auth_providers.dart';
import '../../../auth/presentation/widgets/change_pin_sheet.dart';
import '../widgets/app_side_nav_drawer.dart';

class AppShellScreen extends ConsumerStatefulWidget {
  const AppShellScreen({super.key});

  @override
  ConsumerState<AppShellScreen> createState() => _AppShellScreenState();
}

class _AppShellScreenState extends ConsumerState<AppShellScreen> {
  bool _hasPromptedTemporaryPin = false;
  Timer? _notificationBannerTimer;
  Timer? _messageBannerTimer;

  @override
  void dispose() {
    _notificationBannerTimer?.cancel();
    _messageBannerTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkTemporaryPinPrompt();
    });
  }

  void _checkTemporaryPinPrompt() {
    if (!mounted || _hasPromptedTemporaryPin) return;
    final isTemporary = ref.read(authProvider).isTemporaryPin;
    if (isTemporary) {
      _hasPromptedTemporaryPin = true;
      ChangePinSheet.show(context, isTemporaryPrompt: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider.select((s) => s.isTemporaryPin), (prev, isTemp) {
      if (isTemp && !_hasPromptedTemporaryPin) {
        _hasPromptedTemporaryPin = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ChangePinSheet.show(context, isTemporaryPrompt: true);
          }
        });
      }
    });

    final navState = ref.watch(navigationProvider);
    _popUpNewNotifications(context, ref);
    _popUpNewMessages(context, ref);

    final hasNetwork = ref.watch(networkStatusProvider);
    final isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final canHandleBack = _canHandleBack(ref);
    final account = ref.watch(tenantAccountProvider);
    final companyTheme = account.company.settings.theme;

    return PopScope(
      canPop: !canHandleBack,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack(ref);
      },
      child: Scaffold(
        backgroundColor: AppColors.pageBackground,
        extendBody: true,
        drawer: const AppSideNavDrawer(),
        body: Column(
          children: [
            if (!hasNetwork)
              Material(
                color: AppColors.terracottaLight,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    MediaQuery.paddingOf(context).top + 4,
                    16,
                    8,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.wifi_off_rounded,
                        size: 18,
                        color: AppColors.terracotta,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No internet connection',
                          style: AppTypography.sans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.terracotta,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => ref
                            .read(networkStatusProvider.notifier)
                            .openSettings(),
                        child: Text(
                          'Settings',
                          style: AppTypography.sans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.terracotta,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: IndexedStack(
                index: navState.currentTab.index,
                children: const [
                  HomeScreen(key: ValueKey(AppTab.home)),
                  PaymentsScreen(key: ValueKey(AppTab.payments)),
                  RepairsScreen(key: ValueKey(AppTab.repairs)),
                  MessagesScreen(key: ValueKey(AppTab.messages)),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: isKeyboardOpen
            ? null
            : FloatingPillNavBar(
                currentTab: navState.currentTab,
                activeColor: companyTheme.primaryColor,
                onTabSelected: (tab) {
                  ref.read(navigationProvider.notifier).selectTab(tab);
                },
              ),
      ),
    );
  }

  /// A notification that arrives while the app is open (e.g. a payment
  /// reminder from the manager) drops down from the top. Ones that were
  /// already there when the app opened show on Home instead.
  void _popUpNewNotifications(BuildContext context, WidgetRef ref) {
    ref.listen(tenantNotificationsProvider, (previous, next) {
      final before = previous?.value;
      final after = next.value;
      if (before == null || after == null) return;
      final seen = {for (final n in before) n.id};
      final fresh = after.where((n) => n.isUnread && !seen.contains(n.id));
      if (fresh.isEmpty) return;

      for (final n in fresh) {
        ref
            .read(platformServiceProvider)
            .showSystemNotification(
              id: n.id.hashCode,
              title: n.title,
              body: n.body,
            );
      }

      final n = fresh.first;
      final companyTheme = ref
          .read(tenantAccountProvider)
          .company
          .settings
          .theme;
      final messenger = ScaffoldMessenger.of(context);
      final banner = MaterialBanner(
        key: ValueKey('notification_banner_${n.id}'),
        backgroundColor: companyTheme.primaryColor,
        leading: Icon(
          Icons.notifications_active_outlined,
          color: companyTheme.accentColor,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              n.title,
              style: AppTypography.sans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: companyTheme.onPrimaryColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              n.body,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.sans(
                fontSize: 13,
                color: companyTheme.onPrimaryColor.withValues(alpha: 0.75),
                height: 1.35,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _notificationBannerTimer?.cancel();
              messenger.hideCurrentMaterialBanner();
            },
            child: Text(
              'Close',
              style: AppTypography.sans(
                color: companyTheme.onPrimaryColor.withValues(alpha: 0.75),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              _notificationBannerTimer?.cancel();
              messenger.hideCurrentMaterialBanner();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
            child: Text(
              'View',
              style: AppTypography.sans(
                fontWeight: FontWeight.w600,
                color: companyTheme.onPrimaryColor,
              ),
            ),
          ),
        ],
      );
      messenger
        ..hideCurrentMaterialBanner()
        ..showMaterialBanner(banner);
      // It stays on Home until dismissed; the drop-down itself goes away.
      _notificationBannerTimer?.cancel();
      _notificationBannerTimer = Timer(const Duration(seconds: 8), () {
        if (mounted) messenger.hideCurrentMaterialBanner();
      });
    });
  }

  /// When a new message arrives from the manager or caretaker, show an in-app
  /// banner and native system notification.
  void _popUpNewMessages(BuildContext context, WidgetRef ref) {
    ref.listen(messagesProvider, (previous, next) {
      if (previous == null) return;
      final beforeIds = {for (final m in previous) m.id};
      final fresh = next
          .where((m) => !m.isUserMessage && !beforeIds.contains(m.id))
          .toList(growable: false);
      if (fresh.isEmpty) return;

      final currentTab = ref.read(navigationProvider).currentTab;
      final account = ref.read(tenantAccountProvider);
      final company = account.company;
      final companyTheme = company.settings.theme;

      for (final msg in fresh) {
        ref
            .read(platformServiceProvider)
            .showSystemNotification(
              id: msg.id.hashCode,
              title: 'Message from ${company.name}',
              body: msg.text,
            );

        if (currentTab != AppTab.messages) {
          final messenger = ScaffoldMessenger.of(context);
          HapticFeedback.mediumImpact();

          messenger.removeCurrentSnackBar();
          messenger.showSnackBar(
            SnackBar(
              key: ValueKey('message_popup_${msg.id}'),
              behavior: SnackBarBehavior.floating,
              elevation: 0,
              backgroundColor: Colors.transparent,
              padding: EdgeInsets.zero,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 88),
              duration: const Duration(seconds: 7),
              content: Container(
                decoration: BoxDecoration(
                  color: companyTheme.navBgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: companyTheme.accentColor.withValues(alpha: 0.35),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 14,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: companyTheme.primaryColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: companyTheme.accentColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Message from ${company.name}',
                            style: AppTypography.sans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            msg.text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.sans(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      key: ValueKey('reply_msg_btn_${msg.id}'),
                      onPressed: () {
                        messenger.hideCurrentSnackBar();
                        ref
                            .read(navigationProvider.notifier)
                            .selectTab(AppTab.messages);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: companyTheme.accentColor,
                        foregroundColor: companyTheme.navBgColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Reply',
                        style: AppTypography.sans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
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
    });
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
}

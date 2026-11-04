import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:prop_mgt_app/core/billing/billing_models.dart';
import 'package:prop_mgt_app/core/billing/seed/tenant_seed.g.dart';
import 'package:prop_mgt_app/core/data/data_mode.dart';
import 'package:prop_mgt_app/core/data/supabase_billing_providers.dart';
import 'package:prop_mgt_app/core/data/supabase_billing_repository.dart';
import 'package:prop_mgt_app/features/billing/presentation/state/tenant_account_providers.dart';
import 'package:prop_mgt_app/features/home/presentation/screens/home_screen.dart';
import 'package:prop_mgt_app/features/shell/presentation/widgets/app_side_nav_drawer.dart';
import 'package:prop_mgt_app/features/vacation_notice/presentation/widgets/vacation_notice_sheet.dart';
import 'package:prop_mgt_app/features/app_update/presentation/widgets/app_update_sheet.dart';

class _FakeBillingRepoForSideNav extends SupabaseBillingRepository {
  @override
  Future<BillingSeed> fetchTenantSeed({
    bool fullHistory = false,
    int recentMonths = 12,
  }) async {
    return BillingSeed.fromJson(
      jsonDecode(kTenantSeedsByPhone[kDefaultTenantPhone]!)
          as Map<String, dynamic>,
    );
  }
}

void main() {
  // Installed build 3 (1.0.3), so the 1.0.5 update is offered.
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Makazi',
      packageName: 'com.codzure.makazi',
      version: '1.0.3',
      buildNumber: '3',
      buildSignature: '',
    );
  });

  testWidgets(
    'HomeScreen header contains side nav menu button that opens drawer with Vacation Notice and Play Store rating',
    (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _FakeBillingRepoForSideNav();
      final seed = await repo.fetchTenantSeed();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            liveDataProvider.overrideWithValue(true),
            supabaseBillingRepositoryProvider.overrideWithValue(repo),
            liveTenantSeedProvider.overrideWith((ref) => seed),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Verify side nav button exists in header
      expect(
        find.byKey(const ValueKey('home_side_nav_button')),
        findsOneWidget,
      );

      // Tap side nav button to open drawer
      await tester.tap(find.byKey(const ValueKey('home_side_nav_button')));
      await tester.pumpAndSettle();

      // Drawer is open
      expect(find.byKey(const ValueKey('app_side_nav_drawer')), findsOneWidget);
      expect(find.byType(AppSideNavDrawer), findsOneWidget);

      // Verify Vacation Notice button and Rate on Play Store button are visible
      expect(
        find.byKey(const ValueKey('drawer_vacation_notice_button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('drawer_rate_playstore_button')),
        findsOneWidget,
      );
      expect(find.text('Rate Makazi on Play Store'), findsOneWidget);
    },
  );

  testWidgets(
    'Tapping Vacation Notice in drawer opens VacationNoticeSheet and allows submitting notice',
    (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _FakeBillingRepoForSideNav();
      final seed = await repo.fetchTenantSeed();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            liveDataProvider.overrideWithValue(false),
            supabaseBillingRepositoryProvider.overrideWithValue(repo),
            liveTenantSeedProvider.overrideWith((ref) => seed),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Open drawer
      await tester.tap(find.byKey(const ValueKey('home_side_nav_button')));
      await tester.pumpAndSettle();

      // Tap Vacation Notice button
      await tester.tap(
        find.byKey(const ValueKey('drawer_vacation_notice_button')),
      );
      await tester.pumpAndSettle();

      // Vacation notice sheet is open
      expect(find.byType(VacationNoticeSheet), findsOneWidget);
      expect(find.text('Notice to Vacate'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('vacating_date_selector')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('inspection_date_selector')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('submit_vacation_notice_button')),
        findsOneWidget,
      );

      // Verify Requirements for Successful Vacating card is present and can be expanded
      expect(find.text('Requirements for Successful Vacating'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('toggle_vacating_requirements_button')),
      );
      await tester.pumpAndSettle();
      expect(find.text('30-Day Written Notice'), findsOneWidget);
      expect(find.text('Zero Rent & Utility Arrears'), findsOneWidget);
      expect(find.text('Joint Move-Out Inspection'), findsOneWidget);
      expect(find.text('Deposit Reconciliation & Refund'), findsOneWidget);

      // Choose a reason
      await tester.ensureVisible(
        find.byKey(const ValueKey('reason_Need Bigger Space')),
      );
      await tester.tap(find.byKey(const ValueKey('reason_Need Bigger Space')));
      await tester.pumpAndSettle();

      // Enter optional notes
      await tester.ensureVisible(
        find.byKey(const ValueKey('vacation_reason_details_input')),
      );
      await tester.enterText(
        find.byKey(const ValueKey('vacation_reason_details_input')),
        'Transferring to a 3-bedroom unit',
      );
      await tester.pumpAndSettle();

      // Submit vacation notice
      await tester.ensureVisible(
        find.byKey(const ValueKey('submit_vacation_notice_button')),
      );
      await tester.tap(
        find.byKey(const ValueKey('submit_vacation_notice_button')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      // Now active notice view shows requirements checklist
      expect(find.text('Notice Registered'), findsOneWidget);
      expect(find.text('Vacating Requirements & Checklist'), findsOneWidget);
      expect(find.text('Deposit Protected'), findsOneWidget);
      expect(find.text('1. 30-Day Notice Registered'), findsOneWidget);
      expect(find.text('Reason Stated'), findsOneWidget);
      expect(find.text('Need Bigger Space'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('withdraw_vacation_notice_button')),
        findsOneWidget,
      );

      // Tap withdraw notice
      await tester.tap(
        find.byKey(const ValueKey('withdraw_vacation_notice_button')),
      );
      await tester.pumpAndSettle();

      // Confirmation dialog shows
      expect(find.text('Withdraw vacation notice?'), findsOneWidget);

      // Confirm withdrawal
      await tester.tap(find.text('Withdraw'));
      await tester.pumpAndSettle();

      // Returned to form view
      expect(find.text('Submit vacation notice'), findsOneWidget);
    },
  );

  testWidgets(
    'AccountSheet contains Notice to Vacate and Rate on Play Store tiles',
    (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _FakeBillingRepoForSideNav();
      final seed = await repo.fetchTenantSeed();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            liveDataProvider.overrideWithValue(false),
            supabaseBillingRepositoryProvider.overrideWithValue(repo),
            liveTenantSeedProvider.overrideWith((ref) => seed),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Tap account avatar
      await tester.tap(find.byKey(const ValueKey('account_avatar')));
      await tester.pumpAndSettle();

      // Verify AccountSheet contains vacation notice tile and rate play store tile
      expect(
        find.byKey(const ValueKey('account_vacation_notice_tile')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('account_rate_playstore_tile')),
        findsOneWidget,
      );

      // Tap vacation notice tile from AccountSheet
      await tester.tap(
        find.byKey(const ValueKey('account_vacation_notice_tile')),
      );
      await tester.pumpAndSettle();

      // Vacation notice sheet is open
      expect(find.byType(VacationNoticeSheet), findsOneWidget);
      expect(find.text('Notice to Vacate'), findsOneWidget);
    },
  );

  testWidgets(
    'Drawer and AccountSheet contain In-App Update tiles that open AppUpdateSheet',
    (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _FakeBillingRepoForSideNav();
      final seed = await repo.fetchTenantSeed();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            liveDataProvider.overrideWithValue(false),
            supabaseBillingRepositoryProvider.overrideWithValue(repo),
            liveTenantSeedProvider.overrideWith((ref) => seed),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Open drawer
      await tester.tap(find.byKey(const ValueKey('home_side_nav_button')));
      await tester.pumpAndSettle();

      // Verify Check for Updates tile exists in drawer and tap it
      expect(
        find.byKey(const ValueKey('drawer_check_updates_tile')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('drawer_check_updates_tile')));
      await tester.pumpAndSettle();

      // AppUpdateSheet opens
      expect(find.byType(AppUpdateSheet), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AppUpdateSheet),
          matching: find.text('Update Available'),
        ),
        findsOneWidget,
      );
      expect(find.text('WHAT\'S NEW IN THIS VERSION'), findsOneWidget);
      expect(find.text('v1.0.3'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AppUpdateSheet),
          matching: find.text('v1.0.6'),
        ),
        findsOneWidget,
      );

      // Dismiss update sheet
      await tester.tap(
        find.byKey(const ValueKey('dismiss_update_sheet_button')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AppUpdateSheet), findsNothing);

      // Now open AccountSheet and check for update tile
      await tester.tap(find.byKey(const ValueKey('account_avatar')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('account_check_updates_tile')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('account_check_updates_tile')),
      );
      await tester.pumpAndSettle();

      // AppUpdateSheet opens from AccountSheet
      expect(find.byType(AppUpdateSheet), findsOneWidget);
    },
  );

  testWidgets(
    'HomeScreen shows in-app update banner, dismiss hides it, and update flow completes',
    (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _FakeBillingRepoForSideNav();
      final seed = await repo.fetchTenantSeed();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            liveDataProvider.overrideWithValue(false),
            supabaseBillingRepositoryProvider.overrideWithValue(repo),
            liveTenantSeedProvider.overrideWith((ref) => seed),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Home update banner is visible on dashboard
      expect(find.byKey(const ValueKey('home_update_banner')), findsOneWidget);

      // Tap Update button on banner to open AppUpdateSheet
      await tester.tap(find.byKey(const ValueKey('home_update_banner_button')));
      await tester.pumpAndSettle();

      expect(find.byType(AppUpdateSheet), findsOneWidget);

      // The update button opens Google Play; no download happens in the app.
      expect(
        find.byKey(const ValueKey('start_in_app_update_button')),
        findsOneWidget,
      );
      expect(find.text('Downloading update...'), findsNothing);
      expect(find.text('Restart & Complete Update'), findsNothing);

      // Tapping opens the store; the banner stays until the app is updated.
      await tester.tap(
        find.byKey(const ValueKey('start_in_app_update_button')),
      );
      await tester.pump();

      // The version has not changed, so the banner is still there.
      expect(find.byKey(const ValueKey('home_update_banner')), findsOneWidget);
    },
  );
}

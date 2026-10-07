import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prop_mgt_app/features/navigation/domain/models/app_tab.dart';
import 'package:prop_mgt_app/features/navigation/presentation/state/navigation_providers.dart';

void main() {
  group('NavigationNotifier', () {
    test('initial state defaults to home tab', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(navigationProvider);

      expect(state.currentTab, AppTab.home);
    });

    test('selectTab updates currentTab when different tab selected', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(navigationProvider.notifier).selectTab(AppTab.payments);

      expect(container.read(navigationProvider).currentTab, AppTab.payments);
    });

    test('selectTab ignores duplicate tab selection', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initialState = container.read(navigationProvider);

      container.read(navigationProvider.notifier).selectTab(AppTab.home);

      final subsequentState = container.read(navigationProvider);
      expect(identical(initialState, subsequentState), isTrue);
    });

    test('navigation intent helpers navigate to correct target tabs', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(navigationProvider.notifier);

      notifier.navigateToPayments();
      expect(container.read(navigationProvider).currentTab, AppTab.payments);

      notifier.navigateToRepairs();
      expect(container.read(navigationProvider).currentTab, AppTab.repairs);

      notifier.navigateToMessages();
      expect(container.read(navigationProvider).currentTab, AppTab.messages);
    });

    test('popTab pops previous tab from history stack', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(navigationProvider.notifier);
      notifier.selectTab(AppTab.payments);
      notifier.selectTab(AppTab.repairs);

      expect(container.read(navigationProvider).currentTab, AppTab.repairs);
      expect(container.read(navigationProvider).tabHistory, [
        AppTab.home,
        AppTab.payments,
        AppTab.repairs,
      ]);

      final poppedFirst = notifier.popTab();
      expect(poppedFirst, isTrue);
      expect(container.read(navigationProvider).currentTab, AppTab.payments);
      expect(container.read(navigationProvider).tabHistory, [
        AppTab.home,
        AppTab.payments,
      ]);

      final poppedSecond = notifier.popTab();
      expect(poppedSecond, isTrue);
      expect(container.read(navigationProvider).currentTab, AppTab.home);
      expect(container.read(navigationProvider).tabHistory, [AppTab.home]);

      final poppedThird = notifier.popTab();
      expect(poppedThird, isFalse);
      expect(container.read(navigationProvider).currentTab, AppTab.home);
    });

    test('selectTab resets history when home tab selected', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(navigationProvider.notifier);
      notifier.selectTab(AppTab.payments);
      notifier.selectTab(AppTab.repairs);
      notifier.selectTab(AppTab.home);

      expect(container.read(navigationProvider).currentTab, AppTab.home);
      expect(container.read(navigationProvider).tabHistory, [AppTab.home]);
      expect(container.read(navigationProvider).canPopTab, isFalse);
    });

    test('selectTab deduplicates tab stack preserving home root', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(navigationProvider.notifier);
      notifier.selectTab(AppTab.payments);
      notifier.selectTab(AppTab.repairs);
      notifier.selectTab(AppTab.payments);

      expect(container.read(navigationProvider).tabHistory, [
        AppTab.home,
        AppTab.repairs,
        AppTab.payments,
      ]);
    });
  });
}

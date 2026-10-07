import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/app_tab.dart';
import 'navigation_ui_state.dart';

class NavigationNotifier extends Notifier<NavigationUiState> {
  @override
  NavigationUiState build() {
    return const NavigationUiState(
      currentTab: AppTab.home,
      tabHistory: [AppTab.home],
    );
  }

  void selectTab(AppTab tab) {
    if (state.currentTab == tab) {
      return;
    }

    if (tab == AppTab.home) {
      state = state.copyWith(
        currentTab: AppTab.home,
        tabHistory: const [AppTab.home],
      );
      return;
    }

    final newHistory = [...state.tabHistory.where((t) => t != tab), tab];
    if (!newHistory.contains(AppTab.home)) {
      newHistory.insert(0, AppTab.home);
    }
    state = state.copyWith(currentTab: tab, tabHistory: newHistory);
  }

  bool popTab() {
    if (state.tabHistory.length <= 1) return false;
    final newHistory = List<AppTab>.from(state.tabHistory)..removeLast();
    state = state.copyWith(currentTab: newHistory.last, tabHistory: newHistory);
    return true;
  }

  void navigateToPayments() {
    selectTab(AppTab.payments);
  }

  void navigateToRepairs() {
    selectTab(AppTab.repairs);
  }

  void navigateToMessages() {
    selectTab(AppTab.messages);
  }
}

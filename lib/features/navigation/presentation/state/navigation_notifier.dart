import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/app_tab.dart';
import 'navigation_ui_state.dart';

class NavigationNotifier extends Notifier<NavigationUiState> {
  @override
  NavigationUiState build() {
    return const NavigationUiState(currentTab: AppTab.home);
  }

  void selectTab(AppTab tab) {
    if (state.currentTab == tab) {
      return;
    }
    state = state.copyWith(currentTab: tab);
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

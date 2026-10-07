import 'package:flutter/foundation.dart';
import '../../domain/models/app_tab.dart';

@immutable
class NavigationUiState {
  const NavigationUiState({
    required this.currentTab,
    this.tabHistory = const [AppTab.home],
  });

  final AppTab currentTab;
  final List<AppTab> tabHistory;

  bool get canPopTab => tabHistory.length > 1;

  NavigationUiState copyWith({AppTab? currentTab, List<AppTab>? tabHistory}) {
    return NavigationUiState(
      currentTab: currentTab ?? this.currentTab,
      tabHistory: tabHistory ?? this.tabHistory,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NavigationUiState &&
          runtimeType == other.runtimeType &&
          currentTab == other.currentTab &&
          listEquals(tabHistory, other.tabHistory);

  @override
  int get hashCode => Object.hash(currentTab, Object.hashAll(tabHistory));
}

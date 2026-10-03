import 'package:flutter/foundation.dart';
import '../../domain/models/app_tab.dart';

@immutable
class NavigationUiState {
  const NavigationUiState({required this.currentTab});

  final AppTab currentTab;

  NavigationUiState copyWith({AppTab? currentTab}) {
    return NavigationUiState(currentTab: currentTab ?? this.currentTab);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NavigationUiState &&
          runtimeType == other.runtimeType &&
          currentTab == other.currentTab;

  @override
  int get hashCode => currentTab.hashCode;
}

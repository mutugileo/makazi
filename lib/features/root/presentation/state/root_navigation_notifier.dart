import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/root_navigation_destination.dart';
import 'root_navigation_ui_state.dart';

class RootNavigationNotifier extends Notifier<RootNavigationUiState> {
  @override
  RootNavigationUiState build() {
    return const RootNavigationUiState(
      selectedDestination: RootNavigationDestination.dashboard,
      isCompactLayout: true,
    );
  }

  void selectNavigationDestination(RootNavigationDestination destination) {
    if (state.selectedDestination == destination) {
      return;
    }
    state = state.copyWith(selectedDestination: destination);
  }

  void updateScreenLayoutMode({required bool isCompact}) {
    if (state.isCompactLayout == isCompact) {
      return;
    }
    state = state.copyWith(isCompactLayout: isCompact);
  }
}

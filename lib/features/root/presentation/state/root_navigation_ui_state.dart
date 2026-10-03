import 'package:flutter/foundation.dart';
import '../../domain/models/root_navigation_destination.dart';

@immutable
class RootNavigationUiState {
  const RootNavigationUiState({
    required this.selectedDestination,
    required this.isCompactLayout,
  });

  final RootNavigationDestination selectedDestination;
  final bool isCompactLayout;

  RootNavigationUiState copyWith({
    RootNavigationDestination? selectedDestination,
    bool? isCompactLayout,
  }) {
    return RootNavigationUiState(
      selectedDestination: selectedDestination ?? this.selectedDestination,
      isCompactLayout: isCompactLayout ?? this.isCompactLayout,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RootNavigationUiState &&
          runtimeType == other.runtimeType &&
          selectedDestination == other.selectedDestination &&
          isCompactLayout == other.isCompactLayout;

  @override
  int get hashCode => Object.hash(selectedDestination, isCompactLayout);
}

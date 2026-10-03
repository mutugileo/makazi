import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'root_navigation_notifier.dart';
import 'root_navigation_ui_state.dart';

final rootNavigationProvider =
    NotifierProvider<RootNavigationNotifier, RootNavigationUiState>(
      RootNavigationNotifier.new,
    );

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'navigation_notifier.dart';
import 'navigation_ui_state.dart';

final navigationProvider =
    NotifierProvider<NavigationNotifier, NavigationUiState>(
      NavigationNotifier.new,
    );

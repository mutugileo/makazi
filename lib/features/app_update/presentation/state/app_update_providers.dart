import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_update_notifier.dart';
import 'app_update_ui_state.dart';

final appUpdateProvider = NotifierProvider<AppUpdateNotifier, AppUpdateUiState>(
  AppUpdateNotifier.new,
);

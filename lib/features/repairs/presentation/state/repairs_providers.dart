import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'repairs_notifier.dart';
import 'repairs_ui_state.dart';

final repairsProvider = NotifierProvider<RepairsNotifier, RepairsUiState>(
  RepairsNotifier.new,
);

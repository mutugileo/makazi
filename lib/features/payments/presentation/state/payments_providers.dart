import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'payments_notifier.dart';
import 'payments_ui_state.dart';

final paymentsProvider = NotifierProvider<PaymentsNotifier, PaymentsUiState>(
  PaymentsNotifier.new,
);

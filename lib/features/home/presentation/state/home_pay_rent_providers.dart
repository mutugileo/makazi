import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'home_pay_rent_notifier.dart';
import 'home_pay_rent_ui_state.dart';

final homePayRentProvider =
    NotifierProvider<HomePayRentNotifier, HomePayRentUiState>(
      HomePayRentNotifier.new,
    );

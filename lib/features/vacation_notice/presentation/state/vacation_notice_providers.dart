import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'vacation_notice_notifier.dart';
import 'vacation_notice_ui_state.dart';

final vacationNoticeProvider =
    NotifierProvider<VacationNoticeNotifier, VacationNoticeUiState>(
      VacationNoticeNotifier.new,
    );

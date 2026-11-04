import 'package:flutter/foundation.dart';
import '../../domain/models/app_update_info.dart';

@immutable
class AppUpdateUiState {
  const AppUpdateUiState({
    required this.updateInfo,
    this.isChecking = false,
    this.errorMessage,
    this.hasDismissedNotice = false,
  });

  final AppUpdateInfo updateInfo;
  final bool isChecking;
  final String? errorMessage;
  final bool hasDismissedNotice;

  bool get isUpdateAvailable => updateInfo.isUpdateAvailable;

  AppUpdateUiState copyWith({
    AppUpdateInfo? updateInfo,
    bool? isChecking,
    String? Function()? errorMessage,
    bool? hasDismissedNotice,
  }) {
    return AppUpdateUiState(
      updateInfo: updateInfo ?? this.updateInfo,
      isChecking: isChecking ?? this.isChecking,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      hasDismissedNotice: hasDismissedNotice ?? this.hasDismissedNotice,
    );
  }
}

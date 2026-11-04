import 'package:flutter/foundation.dart';

enum AppUpdatePriority {
  flexible('Flexible', 'Recommended update; can be downloaded in background'),
  immediate('Immediate', 'Required update for continued system operation');

  const AppUpdatePriority(this.label, this.description);
  final String label;
  final String description;
}

@immutable
class AppUpdateInfo {
  const AppUpdateInfo({
    required this.currentVersion,
    required this.currentBuildNumber,
    required this.latestVersion,
    required this.latestBuildNumber,
    required this.isUpdateAvailable,
    this.isForceUpdate = false,
    this.releaseNotes = const [],
    this.releaseDate = '',
    this.priority = AppUpdatePriority.flexible,
    this.playStoreUrl =
        'https://play.google.com/store/apps/details?id=com.codzure.makazi',
  });

  final String currentVersion;
  final int currentBuildNumber;
  final String latestVersion;
  final int latestBuildNumber;
  final bool isUpdateAvailable;
  final bool isForceUpdate;
  final List<String> releaseNotes;
  final String releaseDate;
  final AppUpdatePriority priority;
  final String playStoreUrl;

  AppUpdateInfo copyWith({
    String? currentVersion,
    int? currentBuildNumber,
    String? latestVersion,
    int? latestBuildNumber,
    bool? isUpdateAvailable,
    bool? isForceUpdate,
    List<String>? releaseNotes,
    String? releaseDate,
    AppUpdatePriority? priority,
    String? playStoreUrl,
  }) {
    return AppUpdateInfo(
      currentVersion: currentVersion ?? this.currentVersion,
      currentBuildNumber: currentBuildNumber ?? this.currentBuildNumber,
      latestVersion: latestVersion ?? this.latestVersion,
      latestBuildNumber: latestBuildNumber ?? this.latestBuildNumber,
      isUpdateAvailable: isUpdateAvailable ?? this.isUpdateAvailable,
      isForceUpdate: isForceUpdate ?? this.isForceUpdate,
      releaseNotes: releaseNotes ?? this.releaseNotes,
      releaseDate: releaseDate ?? this.releaseDate,
      priority: priority ?? this.priority,
      playStoreUrl: playStoreUrl ?? this.playStoreUrl,
    );
  }
}

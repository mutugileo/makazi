import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/models/app_update_info.dart';
import 'app_update_ui_state.dart';

class AppUpdateNotifier extends Notifier<AppUpdateUiState> {
  /// The newest release published on Google Play. Bump these with each
  /// release. The installed version is read from the app itself, at runtime.
  static const String latestAppVersion = '1.0.8';
  static const int latestAppBuildNumber = 8;

  static const List<String> latestReleaseNotes = [
    'In-app notification pop-up for messages with tactile feedback',
    'Quick reply to staff and landlord messages',
    'Repair request photo attachments from camera & gallery',
    'Biometric fingerprint login and security improvements',
  ];

  @override
  AppUpdateUiState build() {
    // Nothing is shown until the installed version is known.
    Future<void>.microtask(() => checkForUpdates());
    return const AppUpdateUiState(
      updateInfo: AppUpdateInfo(
        currentVersion: '',
        currentBuildNumber: 0,
        latestVersion: latestAppVersion,
        latestBuildNumber: latestAppBuildNumber,
        isUpdateAvailable: false,
        releaseNotes: latestReleaseNotes,
        releaseDate: '3 Nov 2026',
        priority: AppUpdatePriority.flexible,
      ),
    );
  }

  Future<void> checkForUpdates({bool userInitiated = false}) async {
    state = state.copyWith(isChecking: true, errorMessage: () => null);

    if (userInitiated) {
      await Future<void>.delayed(const Duration(milliseconds: 600));
    }

    final PackageInfo installed;
    try {
      installed = await PackageInfo.fromPlatform();
    } catch (_) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isChecking: false,
        errorMessage: () => 'Could not read the installed app version.',
      );
      return;
    }

    if (!ref.mounted) return;

    final installedBuild = int.tryParse(installed.buildNumber) ?? 0;
    state = state.copyWith(
      isChecking: false,
      hasDismissedNotice: false,
      updateInfo: state.updateInfo.copyWith(
        currentVersion: installed.version,
        currentBuildNumber: installedBuild,
        latestVersion: latestAppVersion,
        latestBuildNumber: latestAppBuildNumber,
        isUpdateAvailable: latestAppBuildNumber > installedBuild,
        releaseNotes: latestReleaseNotes,
        releaseDate: '26 Oct 2026',
      ),
    );
  }

  Future<bool> launchPlayStoreUpdate() async {
    final marketUri = Uri.parse('market://details?id=com.codzure.makazi');
    final webUri = Uri.parse(
      'https://play.google.com/store/apps/details?id=com.codzure.makazi',
    );

    try {
      if (await canLaunchUrl(marketUri)) {
        await launchUrl(marketUri, mode: LaunchMode.externalApplication);
        return true;
      }
    } catch (_) {}

    try {
      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
        return true;
      }
    } catch (_) {}

    return false;
  }

  void dismissUpdateNotice() {
    state = state.copyWith(hasDismissedNotice: true);
  }

  void resetDismissedNotice() {
    state = state.copyWith(hasDismissedNotice: false);
  }
}

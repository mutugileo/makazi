import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/config/supabase_config.dart';
import '../../domain/models/app_update_info.dart';
import 'app_update_ui_state.dart';

class AppUpdateNotifier extends Notifier<AppUpdateUiState> {
  /// Fallback version metadata when offline or in demo mode.
  /// Live production checks read from `public.app_releases` in Supabase.
  static const String latestAppVersion = '1.0.11';
  static const int latestAppBuildNumber = 11;

  static const List<String> latestReleaseNotes = [
    'Paste M-Pesa or bank confirmation messages to confirm rent payments faster',
    'Edit or delete rejected payment confirmation messages',
    'Paginated bills and payment receipts for faster scrolling',
    'In-app notification pop-ups for payment confirmations and reminders',
    'Improved offline connection recovery',
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
        releaseDate: '19 Nov 2026',
        priority: AppUpdatePriority.flexible,
      ),
    );
  }

  Future<void> checkForUpdates({bool userInitiated = false}) async {
    state = state.copyWith(isChecking: true, errorMessage: () => null);

    if (userInitiated) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
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
    var targetVersion = latestAppVersion;
    var targetBuild = latestAppBuildNumber;
    var minSupportedBuild = 1;
    var notes = latestReleaseNotes;
    var releaseDate = '19 Nov 2026';
    var storeUrl =
        'https://play.google.com/store/apps/details?id=com.codzure.makazi';

    if (SupabaseConfig.isConfigured) {
      try {
        final platform = defaultTargetPlatform == TargetPlatform.iOS
            ? 'ios'
            : 'android';
        final row = await Supabase.instance.client
            .from('app_releases')
            .select(
              'latest_version, latest_build_number, min_supported_build_number, '
              'release_notes, release_date, store_url',
            )
            .eq('platform', platform)
            .maybeSingle()
            .timeout(const Duration(seconds: 6));

        if (!ref.mounted) return;
        if (row != null) {
          targetVersion =
              (row['latest_version'] as String?) ?? latestAppVersion;
          targetBuild =
              (row['latest_build_number'] as num?)?.toInt() ??
              latestAppBuildNumber;
          minSupportedBuild =
              (row['min_supported_build_number'] as num?)?.toInt() ?? 1;
          final rawNotes = row['release_notes'];
          if (rawNotes is List) {
            notes = [for (final item in rawNotes) item.toString()];
          }
          releaseDate = (row['release_date'] as String?) ?? releaseDate;
          storeUrl = (row['store_url'] as String?) ?? storeUrl;
        }
      } catch (_) {
        if (!ref.mounted) return;
        if (userInitiated) {
          state = state.copyWith(
            isChecking: false,
            errorMessage: () =>
                'Could not check for updates. Check your connection and try again.',
            updateInfo: state.updateInfo.copyWith(
              currentVersion: installed.version,
              currentBuildNumber: installedBuild,
            ),
          );
          return;
        }
      }
    }

    final isAvailable = installedBuild > 0 && targetBuild > installedBuild;
    final isForced = installedBuild > 0 && installedBuild < minSupportedBuild;

    state = state.copyWith(
      isChecking: false,
      hasDismissedNotice: false,
      updateInfo: state.updateInfo.copyWith(
        currentVersion: installed.version,
        currentBuildNumber: installedBuild,
        latestVersion: targetVersion,
        latestBuildNumber: targetBuild,
        isUpdateAvailable: isAvailable,
        isForceUpdate: isForced,
        priority: isForced
            ? AppUpdatePriority.immediate
            : AppUpdatePriority.flexible,
        releaseNotes: notes,
        releaseDate: releaseDate,
        playStoreUrl: storeUrl,
      ),
    );
  }

  Future<bool> launchPlayStoreUpdate() async {
    final marketUri = Uri.parse('market://details?id=com.codzure.makazi');
    final webUri = Uri.parse(state.updateInfo.playStoreUrl);

    try {
      if (await launchUrl(marketUri, mode: LaunchMode.externalApplication)) {
        return true;
      }
    } catch (_) {}

    try {
      if (await launchUrl(webUri, mode: LaunchMode.externalApplication)) {
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

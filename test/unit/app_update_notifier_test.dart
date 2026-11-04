import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:prop_mgt_app/features/app_update/domain/models/app_update_info.dart';
import 'package:prop_mgt_app/features/app_update/presentation/state/app_update_notifier.dart';
import 'package:prop_mgt_app/features/app_update/presentation/state/app_update_providers.dart';

void _installed(String version, String build) {
  PackageInfo.setMockInitialValues(
    appName: 'Makazi',
    packageName: 'com.codzure.makazi',
    version: version,
    buildNumber: build,
    buildSignature: '',
  );
}

ProviderContainer _container() {
  final c = ProviderContainer();
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('AppUpdateNotifier', () {
    test('shows nothing until the installed version has been read', () {
      _installed('1.0.3', '3');
      final container = _container();

      final state = container.read(appUpdateProvider);
      expect(state.isUpdateAvailable, isFalse);
      expect(state.updateInfo.currentVersion, '');
      expect(
        state.updateInfo.latestVersion,
        AppUpdateNotifier.latestAppVersion,
      );
      expect(
        state.updateInfo.latestBuildNumber,
        AppUpdateNotifier.latestAppBuildNumber,
      );
      expect(state.updateInfo.priority, AppUpdatePriority.flexible);
      expect(state.updateInfo.releaseNotes.isNotEmpty, isTrue);
      expect(state.isChecking, isFalse);
      expect(state.hasDismissedNotice, isFalse);
    });

    test('an older installed build is offered the latest release', () async {
      _installed('1.0.3', '3');
      final container = _container();

      await container.read(appUpdateProvider.notifier).checkForUpdates();

      final state = container.read(appUpdateProvider);
      expect(state.isChecking, isFalse);
      expect(state.isUpdateAvailable, isTrue);
      expect(state.updateInfo.currentVersion, '1.0.3');
      expect(state.updateInfo.currentBuildNumber, 3);
    });

    test('the latest build is not offered its own update', () async {
      _installed(
        AppUpdateNotifier.latestAppVersion,
        '${AppUpdateNotifier.latestAppBuildNumber}',
      );
      final container = _container();

      await container.read(appUpdateProvider.notifier).checkForUpdates();

      final state = container.read(appUpdateProvider);
      expect(state.isUpdateAvailable, isFalse);
      expect(
        state.updateInfo.currentVersion,
        AppUpdateNotifier.latestAppVersion,
      );
      expect(
        state.updateInfo.currentBuildNumber,
        AppUpdateNotifier.latestAppBuildNumber,
      );
    });

    test('an unreadable build number counts as build 0', () async {
      PackageInfo.setMockInitialValues(
        appName: 'Makazi',
        packageName: 'com.codzure.makazi',
        version: '',
        buildNumber: 'not-a-number',
        buildSignature: '',
      );
      final container = _container();

      await container.read(appUpdateProvider.notifier).checkForUpdates();

      final state = container.read(appUpdateProvider);
      expect(state.isChecking, isFalse);
      // An unreadable build number counts as build 0, so it is offered the
      // update; the version itself is still what the device reports.
      expect(state.updateInfo.currentBuildNumber, 0);
      expect(state.isUpdateAvailable, isTrue);
    });

    test('dismissUpdateNotice and resetDismissedNotice toggle flag', () {
      _installed('1.0.3', '3');
      final container = _container();

      final notifier = container.read(appUpdateProvider.notifier);
      expect(container.read(appUpdateProvider).hasDismissedNotice, isFalse);

      notifier.dismissUpdateNotice();
      expect(container.read(appUpdateProvider).hasDismissedNotice, isTrue);

      notifier.resetDismissedNotice();
      expect(container.read(appUpdateProvider).hasDismissedNotice, isFalse);
    });
  });
}

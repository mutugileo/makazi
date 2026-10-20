import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlatformChannelService {
  const PlatformChannelService([
    this._channel = const MethodChannel('com.codzure.propmgt/platform'),
  ]);

  final MethodChannel _channel;

  Future<bool> checkNotificationPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'checkNotificationPermission',
      );
      return result ?? true;
    } catch (_) {
      return true;
    }
  }

  Future<bool> requestNotificationPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'requestNotificationPermission',
      );
      return result ?? true;
    } catch (_) {
      return true;
    }
  }

  Future<void> openNotificationSettings() async {
    try {
      await _channel.invokeMethod('openNotificationSettings');
    } catch (_) {}
  }

  Future<bool> checkNetworkState() async {
    try {
      final result = await _channel.invokeMethod<bool>('checkNetworkState');
      return result ?? true;
    } catch (_) {
      return true;
    }
  }

  Future<void> openNetworkSettings() async {
    try {
      await _channel.invokeMethod('openNetworkSettings');
    } catch (_) {}
  }

  Future<void> showSystemNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      await _channel.invokeMethod('showSystemNotification', {
        'id': id,
        'title': title,
        'body': body,
      });
    } catch (_) {}
  }
}

final platformServiceProvider = Provider<PlatformChannelService>((ref) {
  return const PlatformChannelService();
});

class NotificationPermissionNotifier extends Notifier<bool> {
  @override
  bool build() {
    _checkInitial();
    return true;
  }

  Future<void> _checkInitial() async {
    final service = ref.read(platformServiceProvider);
    final granted = await service.checkNotificationPermission();
    if (state != granted) {
      state = granted;
    }
  }

  Future<bool> requestPermission() async {
    final service = ref.read(platformServiceProvider);
    final granted = await service.requestNotificationPermission();
    state = granted;
    return granted;
  }

  Future<void> openSettings() async {
    final service = ref.read(platformServiceProvider);
    await service.openNotificationSettings();
    await Future<void>.delayed(const Duration(seconds: 1));
    await _checkInitial();
  }
}

final notificationPermissionProvider =
    NotifierProvider<NotificationPermissionNotifier, bool>(
      NotificationPermissionNotifier.new,
    );

class NetworkStatusNotifier extends Notifier<bool> {
  @override
  bool build() {
    _checkInitial();
    return true;
  }

  Future<void> _checkInitial() async {
    final service = ref.read(platformServiceProvider);
    final connected = await service.checkNetworkState();
    if (state != connected) {
      state = connected;
    }
  }

  Future<void> refresh() async {
    final service = ref.read(platformServiceProvider);
    final connected = await service.checkNetworkState();
    state = connected;
  }

  Future<void> openSettings() async {
    final service = ref.read(platformServiceProvider);
    await service.openNetworkSettings();
    await Future<void>.delayed(const Duration(seconds: 1));
    await refresh();
  }
}

final networkStatusProvider = NotifierProvider<NetworkStatusNotifier, bool>(
  NetworkStatusNotifier.new,
);

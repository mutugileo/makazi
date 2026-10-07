import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// What this phone remembers after the tenant signs in with their password
/// once: who they are, a salted hash of their app PIN, whether fingerprint /
/// Face ID may unlock instead, and how many wrong PINs in a row so far (so
/// closing the app doesn't reset the count).
///
/// The PIN itself is never stored or sent anywhere. The Supabase session
/// sits beside this record in the Keychain / Keystore
/// (see core/data/secure_session_storage.dart).
class DeviceLock {
  const DeviceLock({
    required this.userId,
    required this.phone,
    required this.salt,
    required this.pinHash,
    this.firstName,
    this.biometricsEnabled = false,
    this.failedAttempts = 0,
  });

  /// Creates the record for a newly chosen PIN.
  factory DeviceLock.create({
    required String userId,
    required String phone,
    required String pin,
    String? firstName,
  }) {
    final random = Random.secure();
    final salt = base64Url.encode(
      List<int>.generate(16, (_) => random.nextInt(256)),
    );
    return DeviceLock(
      userId: userId,
      phone: phone,
      salt: salt,
      pinHash: hashPin(pin, salt: salt, userId: userId),
      firstName: firstName,
    );
  }

  factory DeviceLock.fromJson(Map<String, dynamic> json) => DeviceLock(
    userId: json['userId'] as String,
    phone: json['phone'] as String,
    salt: json['salt'] as String,
    pinHash: json['pinHash'] as String,
    firstName: json['firstName'] as String?,
    biometricsEnabled: json['biometricsEnabled'] == true,
    failedAttempts: (json['failedAttempts'] as num?)?.toInt() ?? 0,
  );

  final String userId;
  final String phone;
  final String salt;
  final String pinHash;

  /// For "Karibu tena, …" before the account has loaded.
  final String? firstName;
  final bool biometricsEnabled;
  final int failedAttempts;

  bool matches(String pin) =>
      _constantTimeEquals(hashPin(pin, salt: salt, userId: userId), pinHash);

  DeviceLock copyWith({
    String? firstName,
    bool? biometricsEnabled,
    int? failedAttempts,
  }) => DeviceLock(
    userId: userId,
    phone: phone,
    salt: salt,
    pinHash: pinHash,
    firstName: firstName ?? this.firstName,
    biometricsEnabled: biometricsEnabled ?? this.biometricsEnabled,
    failedAttempts: failedAttempts ?? this.failedAttempts,
  );

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'phone': phone,
    'salt': salt,
    'pinHash': pinHash,
    'firstName': firstName,
    'biometricsEnabled': biometricsEnabled,
    'failedAttempts': failedAttempts,
  };

  /// Salted and stretched so the stored value doesn't give the PIN away at a
  /// glance. With only 10,000 PINs the real protection is the Keychain /
  /// Keystore and the 5-attempt limit.
  static String hashPin(
    String pin, {
    required String salt,
    required String userId,
  }) {
    var digest = sha256.convert(utf8.encode('$salt:$userId:$pin')).bytes;
    for (var i = 0; i < 5000; i++) {
      digest = sha256.convert([...digest, ...utf8.encode(salt)]).bytes;
    }
    return base64Url.encode(digest);
  }

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}

abstract interface class DeviceLockStore {
  Future<DeviceLock?> read();
  Future<void> write(DeviceLock lock);
  Future<void> clear();
}

/// Keychain (iOS) / Keystore-encrypted storage (Android).
class SecureDeviceLockStore implements DeviceLockStore {
  SecureDeviceLockStore([FlutterSecureStorage? storage])
    : _storage = storage ?? kSecureStorage;

  static const _key = 'makazi.device_lock';
  final FlutterSecureStorage _storage;

  @override
  Future<DeviceLock?> read() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw == null) return null;
      return DeviceLock.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Unreadable (e.g. restored onto a new phone): start from the password.
      await clear();
      return null;
    }
  }

  @override
  Future<void> write(DeviceLock lock) =>
      _storage.write(key: _key, value: jsonEncode(lock.toJson()));

  @override
  Future<void> clear() async {
    try {
      await _storage.delete(key: _key);
    } catch (_) {}
  }
}

/// Tests and the offline demo build.
class MemoryDeviceLockStore implements DeviceLockStore {
  MemoryDeviceLockStore([this._lock]);

  DeviceLock? _lock;

  @override
  Future<DeviceLock?> read() async => _lock;

  @override
  Future<void> write(DeviceLock lock) async => _lock = lock;

  @override
  Future<void> clear() async => _lock = null;
}

/// Shared settings: on Android, data is encrypted with a Keystore key; on
/// iOS, readable only while the phone is unlocked and never synced to
/// another device through iCloud.
const FlutterSecureStorage kSecureStorage = FlutterSecureStorage(
  iOptions: IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  ),
);

import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/data/device_lock_store.dart';

/// Keeps the Supabase session (access + refresh token) in the Keychain /
/// Keystore instead of plain app preferences. Once a tenant has signed in
/// with their password, this session is what their PIN or fingerprint
/// unlocks, so it gets the same protection as the PIN record.
class SecureSessionStorage extends LocalStorage {
  const SecureSessionStorage();

  static const _key = 'makazi.supabase_session';

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async => (await accessToken()) != null;

  @override
  Future<String?> accessToken() async {
    try {
      final raw = await kSecureStorage.read(key: _key);
      if (raw == null) return null;
      // Only hand back something Supabase can parse.
      jsonDecode(raw);
      return raw;
    } catch (_) {
      await removePersistedSession();
      return null;
    }
  }

  @override
  Future<void> removePersistedSession() async {
    try {
      await kSecureStorage.delete(key: _key);
    } catch (_) {}
  }

  @override
  Future<void> persistSession(String persistSessionString) =>
      kSecureStorage.write(key: _key, value: persistSessionString);
}

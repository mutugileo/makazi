import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../billing/billing_models.dart';

/// The last company theme this device loaded, so the loading screens can use
/// the company's colours before the account arrives. Colours only, never
/// tenant data. Failures are ignored: the app falls back to Makazi colours.
abstract final class BrandThemeCache {
  static const _key = 'brand_theme_v1';
  static const _storage = FlutterSecureStorage();

  static Future<CompanyTheme?> read() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw == null) return null;
      return CompanyTheme.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<void> write(CompanyTheme theme) async {
    try {
      await _storage.write(key: _key, value: jsonEncode(theme.toJson()));
    } catch (_) {
      // Not saving the colours only means the next launch starts in Makazi's.
    }
  }
}

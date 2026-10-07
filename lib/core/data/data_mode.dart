import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// True when the app reads and writes the real database. False in tests and
/// in the offline demo build, which use the bundled seed instead. In live
/// mode nothing ever falls back to seed data.
final liveDataProvider = Provider<bool>((ref) {
  try {
    return Supabase.instance.isInitialized;
  } catch (_) {
    return false;
  }
});

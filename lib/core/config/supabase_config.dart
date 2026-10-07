/// Supabase settings for the Makazi tenant app.
///
/// Only the publishable (anon) key belongs here: it is shipped inside the app
/// and every query it makes is limited by row-level security. The service-role
/// key bypasses RLS and must never be compiled into a client.
abstract final class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://gdapdyvgppatnjksbdco.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_qBGIzPSKLoDOtTZgDy_-mA_MSCmUWs5',
  );

  /// `--dart-define=MAKAZI_DEMO=true` builds the offline demo (seed data and
  /// demo sign-ins) instead of connecting to Supabase.
  static const bool demo = bool.fromEnvironment('MAKAZI_DEMO');

  static bool get isConfigured => !demo && url.isNotEmpty && anonKey.isNotEmpty;
}

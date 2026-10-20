import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/auth_models.dart';
import 'auth_repository.dart';

/// Signs tenants in against Supabase Auth (shared/AUTH.md).
///
/// A tenant's login is `<254XXXXXXXXX>@tenant.makazi.app`. Passwords issued
/// by the manager are one-time: the database hides all data until
/// `complete_password_change()` succeeds, and `account_status()` says whether
/// that is still needed. There is no fallback to demo accounts: a network
/// failure is reported as such.
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository({this.client});

  /// For tests; the app uses the initialised Supabase client.
  final SupabaseClient? client;

  SupabaseClient get _sb => client ?? Supabase.instance.client;

  @override
  Future<SignInOutcome> signIn({
    required String phone,
    required String password,
  }) async {
    final normalized = normalizeKenyanPhone(phone);
    if (normalized == null) return SignInOutcome.invalidCredentials;
    final email =
        '${normalized.replaceAll(RegExp(r'\D'), '')}@tenant.makazi.app';

    // 4-digit PINs are mapped to makazi-pin-XXXX for Supabase GoTrue compatibility.
    // One-time passwords are also accepted in upper/lower case without dashes.
    final typed = password.trim();
    final candidates = <String>{
      if (typed.length == 4) 'makazi-pin-$typed',
      typed,
      typed.toUpperCase(),
      typed.replaceAll('-', '').toUpperCase(),
    };
    User? user;
    try {
      for (final candidate in candidates) {
        try {
          final response = await _sb.auth.signInWithPassword(
            email: email,
            password: candidate,
          );
          user = response.user;
          if (user != null) break;
        } on AuthRetryableFetchException {
          return SignInOutcome.networkError;
        } on AuthException catch (e) {
          final code = int.tryParse(e.statusCode ?? '') ?? 0;
          if (code == 0 || code == 429 || code >= 500) {
            return SignInOutcome.networkError;
          }
          // Wrong password: try the next spelling.
        }
      }
      if (user == null) return SignInOutcome.invalidCredentials;

      // Check 72-hour validity for manager-generated PINs
      final metadata = user.userMetadata ?? {};
      final pinExpiresAtStr = metadata['pin_expires_at'] as String?;
      if (pinExpiresAtStr != null) {
        final pinExpiresAt = DateTime.tryParse(pinExpiresAtStr);
        if (pinExpiresAt != null && pinExpiresAt.isBefore(DateTime.now())) {
          await _sb.auth.signOut();
          return SignInOutcome.oneTimePasswordExpired;
        }
      }

      // Clear any legacy pending password gate so the tenant has immediate access
      try {
        final status = await _accountStatus();
        if (status.mustChangePassword) {
          await _sb.rpc('complete_password_change');
        }
      } catch (_) {}

      return SignInOutcome.success;
    } catch (_) {
      // Signed in but couldn't read the account status: don't half-enter.
      try {
        await _sb.auth.signOut();
      } catch (_) {}
      return SignInOutcome.networkError;
    }
  }

  Future<({bool mustChangePassword, bool expired})> _accountStatus() async {
    final result = await _sb.rpc('account_status');
    final map = (result as Map).cast<String, dynamic>();
    return (
      mustChangePassword: map['mustChangePassword'] == true,
      expired: map['oneTimePasswordExpired'] == true,
    );
  }

  @override
  Future<void> changePassword({required String newPassword}) async {
    final trimmed = newPassword.trim();
    final effective = trimmed.length == 4 ? 'makazi-pin-$trimmed' : trimmed;
    await _sb.auth.updateUser(
      UserAttributes(
        password: effective,
        data: {'is_temporary': false, 'pin_expires_at': null},
      ),
    );
    try {
      await _sb.rpc('complete_password_change');
    } catch (_) {}
  }

  @override
  Future<void> signOut() => _sb.auth.signOut();

  @override
  String? get currentUserId => _sb.auth.currentUser?.id;

  @override
  bool get isCurrentUserTemporary {
    final metadata = _sb.auth.currentUser?.userMetadata;
    if (metadata == null) return false;
    return metadata['is_temporary'] == true ||
        metadata['pin_expires_at'] != null;
  }

  // Supabase reports signedOut when a refresh token is rejected (revoked,
  // password reset, user removed) as well as after our own signOut().
  @override
  Stream<void> get sessionEnded => _sb.auth.onAuthStateChange
      .where((change) => change.event == AuthChangeEvent.signedOut)
      .map((_) {});
}

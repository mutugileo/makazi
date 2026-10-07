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

    // One-time passwords are shown as ABCD-EFGH-JKLM; accept them typed in
    // lower case or without the dashes.
    final typed = password.trim();
    final candidates = <String>{
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

      final status = await _accountStatus();
      if (status.expired) {
        await _sb.auth.signOut();
        return SignInOutcome.oneTimePasswordExpired;
      }
      final isTemporary =
          status.mustChangePassword ||
          user.userMetadata?['is_temporary'] == true;
      return isTemporary
          ? SignInOutcome.mustChangePassword
          : SignInOutcome.success;
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
    await _sb.auth.updateUser(
      UserAttributes(password: newPassword, data: {'is_temporary': false}),
    );
    await _sb.rpc('complete_password_change');
    final status = await _accountStatus();
    if (status.mustChangePassword) throw const OneTimePasswordExpired();
  }

  @override
  Future<void> signOut() => _sb.auth.signOut();

  @override
  String? get currentUserId => _sb.auth.currentUser?.id;

  // Supabase reports signedOut when a refresh token is rejected (revoked,
  // password reset, user removed) as well as after our own signOut().
  @override
  Stream<void> get sessionEnded => _sb.auth.onAuthStateChange
      .where((change) => change.event == AuthChangeEvent.signedOut)
      .map((_) {});
}

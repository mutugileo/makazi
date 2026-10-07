import '../domain/auth_models.dart';
import 'demo_credentials.dart';

/// Server side of sign-in. Phase 2 implements this with Supabase Auth:
/// accounts are created by the manager's onboarding (phone pre-confirmed, no
/// SMS), `signInWithPassword(phone:, password:)` signs in, and the
/// must-change-password flag lives in app_metadata, which users can't edit.
abstract interface class AuthRepository {
  Future<SignInOutcome> signIn({
    required String phone,
    required String password,
  });

  Future<void> changePassword({required String newPassword});

  Future<void> signOut();

  /// The signed-in account's id, or null when nobody is signed in. Ties the
  /// PIN on this phone to one account.
  String? get currentUserId;

  /// Fires when the server ends the session (e.g. the manager reset the
  /// password), so the app goes back to password sign-in.
  Stream<void> get sessionEnded;
}

/// In-memory stand-in so the prototype runs without a backend.
class DemoAuthRepository implements AuthRepository {
  DemoAuthRepository({this.latency = const Duration(milliseconds: 600)})
    : _accounts = {
        for (final account in kDemoAccounts)
          normalizeKenyanPhone(account.phone)!: _DemoAccount(
            password: account.password,
            mustChangePassword: account.isTemporary,
          ),
      };

  /// Simulated network delay.
  final Duration latency;
  final Map<String, _DemoAccount> _accounts;
  String? _signedInPhone;

  @override
  Future<SignInOutcome> signIn({
    required String phone,
    required String password,
  }) async {
    await Future<void>.delayed(latency);
    final account = _accounts[phone];
    // Same answer for unknown numbers and wrong passwords, so the screen
    // doesn't reveal who is a tenant.
    if (account == null || account.password != password) {
      return SignInOutcome.invalidCredentials;
    }
    _signedInPhone = phone;
    return account.mustChangePassword
        ? SignInOutcome.mustChangePassword
        : SignInOutcome.success;
  }

  @override
  Future<void> changePassword({required String newPassword}) async {
    await Future<void>.delayed(latency);
    final phone = _signedInPhone;
    if (phone == null) throw StateError('Not signed in');
    _accounts[phone] = _DemoAccount(
      password: newPassword,
      mustChangePassword: false,
    );
  }

  @override
  Future<void> signOut() async {
    _signedInPhone = null;
  }

  @override
  String? get currentUserId => _signedInPhone;

  @override
  Stream<void> get sessionEnded => const Stream.empty();
}

class _DemoAccount {
  const _DemoAccount({
    required this.password,
    required this.mustChangePassword,
  });

  final String password;
  final bool mustChangePassword;
}

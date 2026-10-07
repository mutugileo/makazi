/// Where the tenant is in the sign-in journey.
enum AuthStage {
  /// No session: phone number + password.
  signedOut,

  /// Signed in with a temporary password from the property manager; must
  /// choose their own before seeing any data.
  mustChangePassword,

  /// Signed in on this phone for the first time; choose an app PIN.
  createPin,

  /// PIN chosen; offer fingerprint / Face ID if the phone has it.
  enableBiometrics,

  /// Session kept on this phone but the app is locked: the PIN or
  /// fingerprint opens it. Also where a cold start lands after the first
  /// sign-in, so the password is only needed once per phone.
  locked,

  unlocked,
}

enum SignInOutcome {
  success,
  mustChangePassword,
  invalidCredentials,

  /// The manager's one-time password is past its 72 hours.
  oneTimePasswordExpired,

  /// Couldn't reach the server. Never treated as a sign-in.
  networkError,
}

/// The new password was saved but the server didn't accept it as replacing
/// the one-time password (it expired meanwhile).
class OneTimePasswordExpired implements Exception {
  const OneTimePasswordExpired();
}

const int kPinLength = 4;
const int kMaxPinAttempts = 5;
const int kMinPasswordLength = 8;

/// Lock the app when it has been in the background this long.
const Duration kAutoLockAfter = Duration(minutes: 1);

/// Accepts 07XX…, 01XX…, 2547XX… or +2547XX… and returns +254XXXXXXXXX.
String? normalizeKenyanPhone(String input) {
  final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
  String? local;
  if (digits.length == 10 && digits.startsWith('0')) {
    local = digits.substring(1);
  } else if (digits.length == 12 && digits.startsWith('254')) {
    local = digits.substring(3);
  } else if (digits.length == 9) {
    local = digits;
  }
  if (local == null || !(local.startsWith('7') || local.startsWith('1'))) {
    return null;
  }
  return '+254$local';
}

/// Why a new password can't be used, or null if it can.
String? passwordProblem(String password, {required String phone}) {
  if (password.length < kMinPasswordLength) {
    return 'Use at least $kMinPasswordLength characters';
  }
  final phoneDigits = phone.replaceAll(RegExp(r'[^0-9]'), '');
  final localDigits = phoneDigits.length >= 9
      ? phoneDigits.substring(phoneDigits.length - 9)
      : phoneDigits;
  if (localDigits.isNotEmpty && password.contains(localDigits)) {
    return "Don't use your phone number in your password";
  }
  if (RegExp(r'^(.)\1+$').hasMatch(password)) {
    return 'Choose a password that is harder to guess';
  }
  return null;
}

/// Why a PIN is too easy to guess, or null if it's fine.
String? pinProblem(String pin) {
  if (pin.length != kPinLength || int.tryParse(pin) == null) {
    return 'Enter $kPinLength digits';
  }
  if (RegExp(r'^(\d)\1+$').hasMatch(pin)) {
    return 'Avoid repeating the same digit';
  }
  const ascending = '0123456789';
  const descending = '9876543210';
  if (ascending.contains(pin) || descending.contains(pin)) {
    return 'Avoid number sequences like 1234';
  }
  return null;
}

/// What a cold start finds on this phone: whether a valid session and
/// device lock exist, and what biometric capabilities are enabled.
class RestoredDevice {
  const RestoredDevice({
    required this.hasSession,
    this.phone,
    this.firstName,
    this.biometricsEnabled = false,
    this.biometricLabel,
    this.failedAttempts = 0,
  });

  const RestoredDevice.none()
    : hasSession = false,
      phone = null,
      firstName = null,
      biometricsEnabled = false,
      biometricLabel = null,
      failedAttempts = 0;

  final bool hasSession;
  final String? phone;
  final String? firstName;
  final bool biometricsEnabled;
  final String? biometricLabel;
  final int failedAttempts;

  bool get canUnlockWithPin => hasSession && phone != null;
  bool get canUnlockWithBiometrics =>
      canUnlockWithPin && biometricsEnabled && biometricLabel != null;
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/data/data_mode.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../billing/presentation/state/tenant_account_providers.dart';
import '../../../billing/presentation/widgets/tenant_data_gate.dart';
import '../../../shell/presentation/screens/app_shell_screen.dart';
import '../../domain/auth_models.dart';
import '../state/auth_providers.dart';
import 'change_password_screen.dart';
import 'create_pin_screen.dart';
import 'enable_biometrics_screen.dart';
import 'sign_in_screen.dart';
import 'unlock_screen.dart';

/// Shows the app only once the tenant is signed in and unlocked, and locks it
/// again after it has been in the background for [kAutoLockAfter].
class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate>
    with WidgetsBindingObserver {
  DateTime? _backgroundedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    if (lifecycle == AppLifecycleState.paused) {
      _backgroundedAt = DateTime.now();
    } else if (lifecycle == AppLifecycleState.resumed) {
      final since = _backgroundedAt;
      _backgroundedAt = null;
      if (since != null && DateTime.now().difference(since) >= kAutoLockAfter) {
        ref.read(authProvider.notifier).lock();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stage = ref.watch(authProvider.select((s) => s.stage));
    final motion =
        Theme.of(context).extension<AppMotionThemeExtension>() ??
        const AppMotionThemeExtension.regular();

    if (ref.watch(liveDataProvider) &&
        stage != AuthStage.signedOut &&
        stage != AuthStage.mustChangePassword) {
      ref.listen(liveTenantSeedProvider, (_, _) {});
    }

    return AnimatedSwitcher(
      duration: motion.stateTransitionDuration,
      switchInCurve: motion.standardEasing,
      switchOutCurve: motion.standardEasing,
      child: switch (stage) {
        AuthStage.signedOut => const SignInScreen(key: ValueKey('sign_in')),
        AuthStage.mustChangePassword => const ChangePasswordScreen(
          key: ValueKey('change_password'),
        ),
        AuthStage.createPin => const CreatePinScreen(
          key: ValueKey('create_pin'),
        ),
        AuthStage.enableBiometrics => const EnableBiometricsScreen(
          key: ValueKey('enable_biometrics'),
        ),
        AuthStage.locked => const UnlockScreen(key: ValueKey('unlock')),
        AuthStage.unlocked => const TenantDataGate(
          key: ValueKey('app_shell'),
          child: AppShellScreen(),
        ),
      },
    );
  }
}

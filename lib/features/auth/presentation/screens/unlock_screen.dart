import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../state/auth_providers.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/pin_pad.dart';

class UnlockScreen extends ConsumerStatefulWidget {
  const UnlockScreen({super.key});

  @override
  ConsumerState<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends ConsumerState<UnlockScreen> {
  bool _promptedBiometrics = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = ref.read(authProvider);
      if (!_promptedBiometrics && state.biometricLabel != null) {
        _promptedBiometrics = true;
        ref.read(authProvider.notifier).unlockWithBiometrics();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);
    final notifier = ref.read(authProvider.notifier);
    final firstName = state.firstName;
    final title = (firstName != null && firstName.isNotEmpty)
        ? 'Karibu tena, $firstName'
        : 'Karibu tena';

    final bioLabel = state.biometricLabel;
    final isFace = bioLabel?.toLowerCase().contains('face') ?? false;

    return AuthScaffold(
      title: title,
      subtitle: 'Enter your PIN to open Makazi.',
      child: Column(
        children: [
          AuthErrorText(state.errorText),
          const SizedBox(height: 24),
          PinPad(
            onCompleted: notifier.unlock,
            footer: TextButton(
              onPressed: notifier.forgotPin,
              child: Text(
                'Forgot\nPIN?',
                textAlign: TextAlign.center,
                style: AppTypography.sans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mintAccent,
                ),
              ),
            ),
          ),
          if (bioLabel != null) ...[
            const SizedBox(height: AppSpacing.md),
            TextButton.icon(
              key: const ValueKey('biometric_unlock_button'),
              onPressed: notifier.unlockWithBiometrics,
              icon: Icon(
                isFace ? Icons.face_rounded : Icons.fingerprint_rounded,
                color: AppColors.forestGreen,
                size: 22,
              ),
              label: Text(
                'Unlock with $bioLabel',
                style: AppTypography.sans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.forestGreen,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

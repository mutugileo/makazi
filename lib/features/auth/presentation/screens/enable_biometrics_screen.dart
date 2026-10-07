import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../state/auth_providers.dart';
import '../widgets/auth_scaffold.dart';

/// Screen presented right after setting up an app PIN, prompting the user
/// to enable Fingerprint or Face ID / Touch ID if supported on the device.
class EnableBiometricsScreen extends ConsumerWidget {
  const EnableBiometricsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authProvider);
    final notifier = ref.read(authProvider.notifier);
    final label = state.biometricLabel ?? 'fingerprint';
    final isFace = label.toLowerCase().contains('face');

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        notifier.skipBiometrics();
      },
      child: AuthScaffold(
        title: 'Enable $label?',
        subtitle:
            'Open Makazi faster next time with your $label. Your PIN will always remain as a backup.',
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.mintAccent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.mintAccent.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  isFace ? Icons.face_rounded : Icons.fingerprint_rounded,
                  size: 44,
                  color: AppColors.forestGreen,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            AuthPrimaryButton(
              label: 'Enable $label',
              onPressed: notifier.enableBiometrics,
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: TextButton(
                onPressed: notifier.skipBiometrics,
                child: Text(
                  'Maybe later',
                  style: AppTypography.sans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

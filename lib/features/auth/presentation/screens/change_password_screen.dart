import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/auth_models.dart';
import '../state/auth_providers.dart';
import '../widgets/auth_scaffold.dart';

/// First sign-in with a one-time password: the tenant chooses their own.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    ref
        .read(authProvider.notifier)
        .changePassword(
          newPassword: _password.text,
          confirmation: _confirm.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);
    final toggle = IconButton(
      onPressed: () => setState(() => _obscure = !_obscure),
      icon: Icon(
        _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        color: AppColors.textMuted,
      ),
      tooltip: _obscure ? 'Show password' : 'Hide password',
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        ref.read(authProvider.notifier).signOut();
      },
      child: AuthScaffold(
        title: 'Choose a password',
        subtitle:
            'The password from your property manager works once. Pick your own '
            'to keep your account safe.',
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                key: const ValueKey('new_password'),
                controller: _password,
                obscureText: _obscure,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.next,
                decoration: authInputDecoration(
                  label: 'New password',
                  suffix: toggle,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                key: const ValueKey('confirm_password'),
                controller: _confirm,
                obscureText: _obscure,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                decoration: authInputDecoration(label: 'Confirm password'),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'At least $kMinPasswordLength characters. A short phrase is '
                'easier to remember than random letters.',
                style: AppTypography.sans(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              AuthErrorText(state.errorText),
              const SizedBox(height: AppSpacing.lg),
              AuthPrimaryButton(
                label: 'Save password',
                isBusy: state.isBusy,
                onPressed: _submit,
              ),
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: TextButton(
                  onPressed: () => ref.read(authProvider.notifier).signOut(),
                  child: Text(
                    'Cancel and sign out',
                    style: AppTypography.sans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mintAccent,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

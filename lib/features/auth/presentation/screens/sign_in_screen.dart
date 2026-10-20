import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/config/demo_data.dart';
import '../../data/auth_repository.dart';
import '../../data/demo_credentials.dart';
import '../state/auth_providers.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/tenant_faq_dialog.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  late final TextEditingController _phone;
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    final known = ref.read(authProvider).phone;
    _phone = TextEditingController(
      text: known == null ? '' : '0${known.substring(4)}',
    );
  }

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    ref
        .read(authProvider.notifier)
        .signIn(phone: _phone.text, password: _password.text);
  }

  void _useDemoAccount(DemoAccount account) {
    setState(() {
      _phone.text = account.phone;
      _password.text = account.password;
    });
    ref.read(authProvider.notifier).clearError();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);
    // Only the prototype's demo sign-in shows this; the Supabase repository
    // in Phase 2 never does.
    final isDemo =
        kDemoDataAvailable &&
        ref.watch(authRepositoryProvider) is DemoAuthRepository;

    return AuthScaffold(
      title: 'Sign in',
      subtitle:
          'Use the phone number your property manager has for you and the '
          '4-digit PIN they gave you.',
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              key: const ValueKey('sign_in_phone'),
              controller: _phone,
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumber],
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
                LengthLimitingTextInputFormatter(16),
              ],
              decoration: authInputDecoration(
                label: 'Phone number',
                hint: '07XX XXX XXX',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              key: const ValueKey('sign_in_password'),
              controller: _password,
              obscureText: _obscure,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              onSubmitted: (_) => _submit(),
              decoration: authInputDecoration(
                label: '4-digit PIN',
                hint: '4 digits',
                suffix: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.textMuted,
                  ),
                  tooltip: _obscure ? 'Show PIN' : 'Hide PIN',
                ),
              ),
            ),
            AuthErrorText(state.errorText),
            const SizedBox(height: AppSpacing.lg),
            AuthPrimaryButton(
              label: 'Sign in',
              isBusy: state.isBusy,
              onPressed: _submit,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Forgot your PIN? Ask your property manager for a new '
              '4-digit PIN. They can reset it for you.',
              style: AppTypography.sans(
                fontSize: 13,
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton.icon(
              key: const ValueKey('sign_in_faq'),
              onPressed: () => showTenantFaqDialog(context),
              icon: const Icon(Icons.help_outline),
              label: const Text('Frequently asked questions'),
            ),
            if (isDemo)
              for (final account in kDemoAccounts) ...[
                const SizedBox(height: AppSpacing.sm),
                _DemoAccountHint(
                  key: ValueKey('demo_account_hint_${account.phone}'),
                  account: account,
                  onUse: () => _useDemoAccount(account),
                ),
              ],
          ],
        ),
      ),
    );
  }
}

/// Prototype only: the demo tenant's sign-in details.
class _DemoAccountHint extends StatelessWidget {
  const _DemoAccountHint({
    super.key,
    required this.account,
    required this.onUse,
  });

  final DemoAccount account;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    TextStyle label() =>
        AppTypography.sans(fontSize: 12, color: AppColors.textMuted);
    TextStyle value() => AppTypography.sans(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
      tabularFigures: true,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.limeSoft.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.limeAccent),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DEMO ACCOUNT',
                  style: AppTypography.sans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.forestGreen,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: 'Phone  ', style: label()),
                      TextSpan(text: account.phone, style: value()),
                    ],
                  ),
                ),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: 'Password  ', style: label()),
                      TextSpan(text: account.password, style: value()),
                    ],
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onUse,
            child: Text(
              'Fill in',
              style: AppTypography.sans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.forestGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

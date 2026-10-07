import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/state/auth_providers.dart';
import '../../../billing/presentation/state/tenant_account_providers.dart';
import '../../../billing/presentation/state/tenant_account_state.dart';
import '../../../navigation/presentation/state/navigation_providers.dart';
import '../../../payments/presentation/state/payments_providers.dart';
import '../state/home_pay_rent_providers.dart';

/// Who's signed in, and the way out.
class AccountSheet extends ConsumerWidget {
  const AccountSheet({super.key, required this.account});

  final TenantAccountState account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              account.tenant.name,
              style: AppTypography.editorialSerif(
                fontSize: 26,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${account.tenant.phone} · ${account.unitTitle}\n'
              'Landlord: ${account.company.name}',
              style: AppTypography.sans(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'To change your password or phone number, contact your '
              'property manager.',
              style: AppTypography.sans(
                fontSize: 13,
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () async {
                  // The sheet is disposed once popped, so keep the container.
                  final container = ProviderScope.containerOf(
                    context,
                    listen: false,
                  );
                  Navigator.of(context).pop();
                  await container.read(authProvider.notifier).signOut();
                  // Nothing from this session survives sign-out.
                  container
                    ..invalidate(tenantAccountProvider)
                    ..invalidate(homePayRentProvider)
                    ..invalidate(paymentsProvider)
                    ..invalidate(navigationProvider);
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.borderLight),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Sign out',
                  style: AppTypography.sans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.statusUnpaidText,
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/billing/billing_engine.dart';
import '../../../../core/billing/payment_claim.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../billing/presentation/state/tenant_account_providers.dart';

/// Payment messages the tenant sent that the manager hasn't confirmed:
/// waiting, or not confirmed with the reason. Hidden when there are none.
class PaymentClaimsCard extends ConsumerWidget {
  const PaymentClaimsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final claims = ref.watch(paymentClaimsProvider).value ?? const [];
    if (claims.isEmpty) return const SizedBox.shrink();
    final companyName = ref.watch(
      tenantAccountProvider.select((a) => a.company.name),
    );

    return Container(
      key: const ValueKey('payment_claims_card'),
      margin: const EdgeInsets.only(top: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment messages',
            style: AppTypography.sans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          for (final claim in claims) ...[
            const SizedBox(height: AppSpacing.sm),
            _ClaimRow(claim: claim, companyName: companyName),
          ],
        ],
      ),
    );
  }
}

class _ClaimRow extends StatelessWidget {
  const _ClaimRow({required this.claim, required this.companyName});

  final PaymentClaim claim;
  final String companyName;

  @override
  Widget build(BuildContext context) {
    final rejected = claim.status == PaymentClaimStatus.rejected;
    final title = [
      if (claim.amount != null) formatKes(claim.amount!),
      if (claim.reference != null) claim.reference!,
    ].join(' · ');
    final sentOn = BillingDates.formatDayMonth(
      claim.createdAt.substring(0, 10),
    );
    final detail = rejected
        ? 'Not confirmed: ${claim.reviewNote ?? 'contact $companyName'}'
        : 'Waiting for $companyName to confirm · sent $sentOn';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 3),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: rejected
                ? AppColors.statusUnpaidBackground
                : AppColors.statusPartialBackground,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
          child: Text(
            rejected ? 'Not confirmed' : 'Waiting',
            style: AppTypography.sans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: rejected
                  ? AppColors.statusUnpaidText
                  : AppColors.statusPartialText,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.isNotEmpty ? title : 'Payment message',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.sans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                style: AppTypography.sans(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

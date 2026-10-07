import 'package:flutter/material.dart';
import '../../../../core/billing/billing_engine.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../billing/presentation/state/tenant_account_state.dart';

/// Statement of account: the same content and totals as the admin's
/// printable statement (PropAdmin/src/pages/statement/[id].astro), so a tenant
/// can show proof of payment, e.g. to an employer.
class StatementView extends StatelessWidget {
  const StatementView({
    super.key,
    required this.account,
    required this.onBackPressed,
  });

  final TenantAccountState account;
  final VoidCallback onBackPressed;

  @override
  Widget build(BuildContext context) {
    final bills = account.bills;
    final receipts = account.receipts.reversed.toList(growable: false);
    final totalBilled = bills.fold(0, (sum, b) => sum + b.newCharges);
    final totalPaid = account.totalPaid;
    final balance = account.balance;
    final tenancy = account.tenancy;
    final period = bills.isEmpty
        ? '—'
        : '${BillingDates.monthLabel(bills.first.month)} – '
              '${BillingDates.monthLabel(bills.last.month)}';

    TextStyle label() => AppTypography.sans(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: AppColors.textMuted,
      letterSpacing: 1.1,
    );
    TextStyle value() => AppTypography.sans(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
      tabularFigures: true,
    );

    Widget total(String title, String amount, {Color? color}) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: label()),
          const SizedBox(height: 2),
          Text(amount, style: value().copyWith(color: color)),
        ],
      ),
    );

    Widget card(List<Widget> children) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xxl + AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onBackPressed,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.cardBackground,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_left_rounded,
                    size: 24,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Statement',
                  style: AppTypography.editorialSerif(
                    fontSize: 34,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          card([
            Text(account.company.name, style: value()),
            Text(
              'KRA PIN ${account.company.kraPin} · Issued '
              '${BillingDates.formatDate(account.seed.asOf)}',
              style: AppTypography.sans(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Divider(height: 1, color: AppColors.borderLight),
            ),
            Text(account.tenant.name, style: value()),
            Text(
              '${account.unitTitle} · tenancy '
              '${BillingDates.formatDate(tenancy.moveIn)} – '
              '${tenancy.moveOut == null ? 'present' : BillingDates.formatDate(tenancy.moveOut!)}',
              style: AppTypography.sans(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('PERIOD', style: label()),
            Text(period, style: value()),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                total('Total billed', formatKes(totalBilled)),
                total('Total paid', formatKes(totalPaid)),
                total(
                  balance < 0 ? 'Credit' : 'Balance',
                  formatKes(balance.abs()),
                  color: balance > 0
                      ? AppColors.statusUnpaidText
                      : AppColors.statusPaidText,
                ),
              ],
            ),
          ]),
          const SizedBox(height: AppSpacing.lg),
          Text('BILLS', style: label()),
          const SizedBox(height: AppSpacing.xs),
          card([
            for (final b in bills)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        BillingDates.monthLabel(b.month),
                        style: AppTypography.sans(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    // Two lines so long amounts fit a phone width.
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${formatKes(b.totalDue)} due',
                          style: AppTypography.sans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            tabularFigures: true,
                          ),
                        ),
                        Text(
                          'paid ${formatKes(b.amountPaid)}',
                          style: AppTypography.sans(
                            fontSize: 12,
                            color: AppColors.textMuted,
                            tabularFigures: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ]),
          const SizedBox(height: AppSpacing.lg),
          Text('PAYMENTS RECEIVED', style: label()),
          const SizedBox(height: AppSpacing.xs),
          card([
            if (receipts.isEmpty)
              Text(
                'No payments in this period.',
                style: AppTypography.sans(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
            for (final r in receipts)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${r.dateLabel} · ${r.method} · ${r.receiptNumber}',
                        style: AppTypography.sans(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Text(
                      r.amountLabel,
                      style: AppTypography.sans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        tabularFigures: true,
                      ),
                    ),
                  ],
                ),
              ),
          ]),
          if (account.recordsKeptUntil != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Records for this tenancy are kept until '
              '${BillingDates.formatDate(account.recordsKeptUntil!)}.',
              style: AppTypography.sans(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'PDF statements not available yet. Your property manager '
                    'can print one for you.',
                    style: AppTypography.sans(
                      fontSize: 14,
                      color: AppColors.pureWhite,
                    ),
                  ),
                  backgroundColor: AppColors.forestGreen,
                  behavior: SnackBarBehavior.floating,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.mintAccent,
                foregroundColor: AppColors.pureWhite,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Download PDF',
                style: AppTypography.sans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.pureWhite,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

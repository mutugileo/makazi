import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/receipt_detail_view.dart';
import '../../domain/models/pay_rent_models.dart';
import '../state/home_pay_rent_providers.dart';

class PayRentFlowView extends ConsumerWidget {
  const PayRentFlowView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homePayRentProvider);
    final notifier = ref.read(homePayRentProvider.notifier);
    final theme = Theme.of(context);
    final motion =
        theme.extension<AppMotionThemeExtension>() ??
        const AppMotionThemeExtension.regular();

    if (state.showingReceiptDetail && state.completedReceipt != null) {
      return ReceiptDetailView(
        key: const ValueKey('pay_rent_completed_receipt'),
        receipt: state.completedReceipt!,
        onBackPressed: notifier.closeReceiptDetail,
      );
    }

    return AnimatedSwitcher(
      duration: motion.stateTransitionDuration,
      switchInCurve: motion.standardEasing,
      switchOutCurve: motion.standardEasing,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: switch (state.step) {
        PayRentStep.form => _PayRentFormView(
          key: const ValueKey('pay_rent_form_view'),
        ),
        PayRentStep.confirming => _ConfirmingPaymentView(
          key: const ValueKey('pay_rent_confirming_view'),
        ),
        PayRentStep.received => _PaymentReceivedView(
          key: const ValueKey('pay_rent_received_view'),
        ),
      },
    );
  }
}

class _PayRentFormView extends ConsumerWidget {
  const _PayRentFormView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homePayRentProvider);
    final notifier = ref.read(homePayRentProvider.notifier);

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
                onTap: notifier.closePayRent,
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
                  'Pay rent',
                  style: AppTypography.editorialSerif(
                    fontSize: 34,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: Text(
              'AMOUNT  ·  KES',
              style: AppTypography.sans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Center(
            child: Text(
              '${state.amountValue}',
              style: AppTypography.editorialSerif(
                fontSize: 54,
                fontWeight: FontWeight.w400,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _AmountOptionChip(
                    label: 'Full balance · KES 45,000',
                    isSelected:
                        state.amountOption == PayRentAmountOption.fullBalance,
                    onTap: () => notifier.selectAmountOption(
                      PayRentAmountOption.fullBalance,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _AmountOptionChip(
                    label: 'Half · KES 22,500',
                    isSelected: state.amountOption == PayRentAmountOption.half,
                    onTap: () =>
                        notifier.selectAmountOption(PayRentAmountOption.half),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _PaymentMethodCard(
            title: 'M-Pesa',
            subtitle: 'STK push to your phone · Paybill 522 533',
            isSelected: state.paymentMethod == PayRentMethod.mpesa,
            onTap: () => notifier.selectPaymentMethod(PayRentMethod.mpesa),
          ),
          const SizedBox(height: AppSpacing.md),
          _PaymentMethodCard(
            title: 'Bank transfer',
            subtitle: 'NCBA · reflects in 1 working day',
            isSelected: state.paymentMethod == PayRentMethod.bankTransfer,
            onTap: () =>
                notifier.selectPaymentMethod(PayRentMethod.bankTransfer),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (state.paymentMethod == PayRentMethod.mpesa) ...[
            Text(
              'M-Pesa number',
              style: AppTypography.sans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Container(
              width: double.infinity,
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Text(
                state.mpesaNumber,
                style: AppTypography.sans(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: notifier.submitPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mintAccent,
                  foregroundColor: AppColors.pureWhite,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Pay ${state.amountFormatted}',
                  style: AppTypography.sans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.pureWhite,
                  ),
                ),
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                children: const [
                  _BankRow(label: 'Bank', value: 'NCBA Bank, Westlands'),
                  SizedBox(height: AppSpacing.sm),
                  _BankRow(label: 'Account', value: '1004  5582  31'),
                  SizedBox(height: AppSpacing.sm),
                  _BankRow(label: 'Reference', value: 'RC-5A'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Clipboard.setData(
                    const ClipboardData(
                      text:
                          'Bank: NCBA Bank, Westlands\nAccount: 1004558231\nReference: RC-5A',
                    ),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Bank details copied to clipboard',
                        style: AppTypography.sans(
                          fontSize: 14,
                          color: AppColors.pureWhite,
                        ),
                      ),
                      backgroundColor: AppColors.forestGreen,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mintAccent,
                  foregroundColor: AppColors.pureWhite,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Copy bank details',
                  style: AppTypography.sans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.pureWhite,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AmountOptionChip extends StatelessWidget {
  const _AmountOptionChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.textPrimary : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppColors.textPrimary : AppColors.borderLight,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.sans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? AppColors.pureWhite : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  const _PaymentMethodCard({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.mintAccent : AppColors.borderLight,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.sans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    subtitle,
                    style: AppTypography.sans(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.mintAccent
                      : const Color(0xFFD1D5DB),
                  width: isSelected ? 2.0 : 1.5,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.mintAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _BankRow extends StatelessWidget {
  const _BankRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.sans(fontSize: 14, color: AppColors.textMuted),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTypography.sans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ConfirmingPaymentView extends ConsumerWidget {
  const _ConfirmingPaymentView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(homePayRentProvider.notifier);

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
                onTap: notifier.closePayRent,
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
                  'Pay rent',
                  style: AppTypography.editorialSerif(
                    fontSize: 34,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 140),
          Center(
            child: SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(
                strokeWidth: 3.5,
                color: AppColors.mintAccent,
                backgroundColor: AppColors.mintBackground,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: Text(
              'Confirming payment',
              style: AppTypography.editorialSerif(
                fontSize: 30,
                fontWeight: FontWeight.w400,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                'Waiting for M-Pesa to confirm. Your receipt will be ready in a moment.',
                textAlign: TextAlign.center,
                style: AppTypography.sans(
                  fontSize: 15,
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentReceivedView extends ConsumerWidget {
  const _PaymentReceivedView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homePayRentProvider);
    final notifier = ref.read(homePayRentProvider.notifier);

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
                onTap: notifier.finishPayRent,
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
                  'Pay rent',
                  style: AppTypography.editorialSerif(
                    fontSize: 34,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 70),
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.forestGreen,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.forestGreen.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.pureWhite,
                size: 34,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Payment received',
              style: AppTypography.editorialSerif(
                fontSize: 32,
                fontWeight: FontWeight.w400,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              state.amountFormatted,
              style: AppTypography.sans(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              '${state.completedReceipt?.receiptNumber ?? 'RCT-2610-0423'} · ${state.completedReceipt?.reference ?? 'SJAEEMDE4J'}',
              style: AppTypography.sans(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: notifier.viewCompletedReceipt,
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.cardBackground,
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.borderLight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'View receipt',
                style: AppTypography.sans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: notifier.finishPayRent,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.mintAccent,
                foregroundColor: AppColors.pureWhite,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Done',
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

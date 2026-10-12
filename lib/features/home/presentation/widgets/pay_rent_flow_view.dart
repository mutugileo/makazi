import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/billing/billing_engine.dart';
import '../../../../core/data/data_mode.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/receipt_detail_view.dart';
import '../../../billing/presentation/state/tenant_account_providers.dart';
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
        PayRentStep.awaitingApproval => _MpesaPromptView(
          key: const ValueKey('pay_rent_prompt_view'),
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
    final account = ref.watch(tenantAccountProvider);
    final company = account.company;
    // Until M-Pesa (Daraja) is connected, the live app shows Paybill details
    // instead of a simulated STK push: only a real payment makes a receipt.
    final isLive = ref.watch(liveDataProvider);
    final testMode = isLive && company.settings.mpesaSimulation;
    final canPush = !isLive || testMode;
    final amountError = state.amountError;
    final showError =
        amountError != null &&
        (state.amountOption == PayRentAmountOption.fullBalance ||
            state.otherAmountText.isNotEmpty);

    // iOS number pads have no return key: tapping outside closes it.
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                groupThousands(state.amountValue),
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
                    if (state.fullBalance > 0) ...[
                      _AmountOptionChip(
                        label: 'Full balance · ${formatKes(state.fullBalance)}',
                        isSelected:
                            state.amountOption ==
                            PayRentAmountOption.fullBalance,
                        onTap: () => notifier.selectAmountOption(
                          PayRentAmountOption.fullBalance,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    _AmountOptionChip(
                      label: 'Other amount',
                      isSelected:
                          state.amountOption == PayRentAmountOption.other,
                      onTap: () => notifier.selectAmountOption(
                        PayRentAmountOption.other,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (state.amountOption == PayRentAmountOption.other) ...[
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                key: const ValueKey('pay_rent_other_amount'),
                initialValue: state.otherAmountText,
                onChanged: notifier.updateOtherAmount,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(7),
                ],
                style: AppTypography.sans(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                  tabularFigures: true,
                ),
                decoration: InputDecoration(
                  prefixText: 'KES  ',
                  hintText: 'Amount',
                  filled: true,
                  fillColor: AppColors.cardBackground,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.borderLight),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.borderLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppColors.mintAccent,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
            if (showError) ...[
              const SizedBox(height: AppSpacing.xs),
              Center(
                child: Text(
                  amountError,
                  textAlign: TextAlign.center,
                  style: AppTypography.sans(
                    fontSize: 13,
                    color: AppColors.statusUnpaidText,
                  ),
                ),
              ),
            ] else if (state.creditAfterPayment > 0) ...[
              const SizedBox(height: AppSpacing.xs),
              Center(
                child: Text(
                  '${formatKes(state.creditAfterPayment)} will carry to your next bill as credit',
                  textAlign: TextAlign.center,
                  style: AppTypography.sans(
                    fontSize: 13,
                    color: AppColors.statusCreditText,
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            _PaymentMethodCard(
              title: 'M-Pesa',
              subtitle: !canPush
                  ? 'Paybill ${account.effectiveMpesaPaybill} · '
                        'Account ${account.accountNumber}'
                  : 'STK push to your phone · Paybill ${account.effectiveMpesaPaybill} · '
                        'Account ${account.accountNumber}',
              isSelected: state.paymentMethod == PayRentMethod.mpesa,
              onTap: () => notifier.selectPaymentMethod(PayRentMethod.mpesa),
            ),
            const SizedBox(height: AppSpacing.md),
            _PaymentMethodCard(
              title: 'Bank transfer',
              subtitle:
                  '${account.effectiveBankName} · reflects in 1 working day',
              isSelected: state.paymentMethod == PayRentMethod.bankTransfer,
              onTap: () =>
                  notifier.selectPaymentMethod(PayRentMethod.bankTransfer),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (state.paymentMethod == PayRentMethod.mpesa && !canPush) ...[
              Container(
                key: const ValueKey('mpesa_paybill_details'),
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  children: [
                    _BankRow(
                      label: 'Paybill',
                      value: account.effectiveMpesaPaybill,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _BankRow(label: 'Account', value: account.accountNumber),
                    const SizedBox(height: AppSpacing.sm),
                    _BankRow(label: 'Amount', value: state.amountFormatted),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Pay from M-Pesa, then your receipt appears here once '
                '${company.name} records the payment.',
                style: AppTypography.sans(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _MpesaPayNowButton(
                paybill: account.effectiveMpesaPaybill,
                accountNumber: account.accountNumber,
                amount: state.amountFormatted,
                companyName: company.name,
                enabled: state.amountError == null,
              ),
            ] else if (state.paymentMethod == PayRentMethod.mpesa) ...[
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
                  account.tenant.phone,
                  style: AppTypography.sans(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (testMode) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  key: const ValueKey('mpesa_test_mode_note'),
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.statusPartialBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.statusPartialBorder),
                  ),
                  child: Text(
                    'M-Pesa test mode: the request is simulated and no money '
                    'moves. The payment is recorded as a test payment.',
                    style: AppTypography.sans(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
              if (state.errorText != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  state.errorText!,
                  key: const ValueKey('pay_rent_error'),
                  style: AppTypography.sans(
                    fontSize: 13,
                    color: AppColors.statusUnpaidText,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  key: const ValueKey('mpesa_stk_pay_now'),
                  onPressed: state.canSubmit
                      ? () {
                          FocusScope.of(context).unfocus();
                          notifier.submitPayment();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mintAccent,
                    foregroundColor: AppColors.pureWhite,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Pay now',
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
                  children: [
                    _BankRow(label: 'Bank', value: account.effectiveBankName),
                    const SizedBox(height: AppSpacing.sm),
                    _BankRow(
                      label: 'Account',
                      value: _spacedAccount(account.effectiveBankAccount),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _BankRow(label: 'Reference', value: account.accountNumber),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _CopyDetailsButton(
                label: 'Copy bank details',
                text:
                    'Bank: ${account.effectiveBankName}\n'
                    'Account: ${account.effectiveBankAccount}\n'
                    'Reference: ${account.accountNumber}',
                confirmation: 'Bank details copied to clipboard',
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _spacedAccount(String account) => account
      .replaceAllMapped(RegExp(r'.{1,4}'), (m) => '${m.group(0)}  ')
      .trim();
}

/// M-Pesa in the live app. Until Daraja (STK push) is connected, "Pay now"
/// walks the tenant through Lipa na M-Pesa with this bill's details; the
/// receipt appears once the payment is recorded. Nothing here claims a
/// payment went through.
class _MpesaPayNowButton extends StatelessWidget {
  const _MpesaPayNowButton({
    required this.paybill,
    required this.accountNumber,
    required this.amount,
    required this.companyName,
    required this.enabled,
  });

  final String paybill;
  final String accountNumber;
  final String amount;
  final String companyName;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        key: const ValueKey('mpesa_pay_now'),
        onPressed: enabled
            ? () {
                FocusScope.of(context).unfocus();
                showModalBottomSheet<void>(
                  context: context,
                  backgroundColor: AppColors.cardBackground,
                  showDragHandle: true,
                  isScrollControlled: true,
                  builder: (_) => _MpesaStepsSheet(
                    paybill: paybill,
                    accountNumber: accountNumber,
                    amount: amount,
                    companyName: companyName,
                  ),
                );
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.mintAccent,
          foregroundColor: AppColors.pureWhite,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          'Pay now',
          style: AppTypography.sans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.pureWhite,
          ),
        ),
      ),
    );
  }
}

class _MpesaStepsSheet extends StatelessWidget {
  const _MpesaStepsSheet({
    required this.paybill,
    required this.accountNumber,
    required this.amount,
    required this.companyName,
  });

  final String paybill;
  final String accountNumber;
  final String amount;
  final String companyName;

  @override
  Widget build(BuildContext context) {
    final steps = [
      'Open M-Pesa and choose Lipa na M-Pesa, then Pay Bill',
      'Business number: $paybill',
      'Account number: $accountNumber',
      'Amount: $amount',
      'Enter your M-Pesa PIN and confirm',
    ];
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
              'Pay with M-Pesa',
              style: AppTypography.editorialSerif(
                fontSize: 28,
                fontWeight: FontWeight.w400,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (var i = 0; i < steps.length; i++) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.mintBackground,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: AppTypography.sans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mintAccent,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        steps[i],
                        style: AppTypography.sans(
                          fontSize: 15,
                          color: AppColors.textPrimary,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (i < steps.length - 1) const SizedBox(height: AppSpacing.sm),
            ],
            const SizedBox(height: AppSpacing.md),
            Text(
              'Your receipt appears in Payments once $companyName records '
              'the payment.',
              style: AppTypography.sans(
                fontSize: 13,
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _CopyDetailsButton(
              label: 'Copy Paybill details',
              text:
                  'Paybill: $paybill\n'
                  'Account: $accountNumber\n'
                  'Amount: $amount',
              confirmation: 'Paybill details copied to clipboard',
            ),
          ],
        ),
      ),
    );
  }
}

class _CopyDetailsButton extends StatelessWidget {
  const _CopyDetailsButton({
    required this.label,
    required this.text,
    required this.confirmation,
  });

  final String label;
  final String text;
  final String confirmation;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: () async {
          await Clipboard.setData(ClipboardData(text: text));
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                confirmation,
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
          label,
          style: AppTypography.sans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.pureWhite,
          ),
        ),
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
                      : AppColors.borderStrong,
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

/// The M-Pesa request as it reaches the tenant's phone. In the live app this
/// is M-Pesa test mode, so the prompt is shown here in the app. It never
/// asks for the M-Pesa PIN: a real prompt comes from the phone itself, and
/// Makazi must not teach tenants to type their PIN into an app.
class _MpesaPromptView extends ConsumerWidget {
  const _MpesaPromptView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homePayRentProvider);
    final notifier = ref.read(homePayRentProvider.notifier);
    final account = ref.watch(tenantAccountProvider);
    final company = account.company;

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
                onTap: notifier.declineMpesaPush,
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
          const SizedBox(height: 48),
          const Center(
            child: Icon(
              Icons.phone_iphone_rounded,
              size: 44,
              color: AppColors.mintAccent,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: Text(
              state.promptShown ? 'Check your phone' : 'Sending request…',
              style: AppTypography.editorialSerif(
                fontSize: 30,
                fontWeight: FontWeight.w400,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Center(
            child: Text(
              'M-Pesa request to ${account.tenant.phone}',
              textAlign: TextAlign.center,
              style: AppTypography.sans(
                fontSize: 15,
                color: AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: !state.promptShown
                ? const Center(
                    key: ValueKey('mpesa_prompt_sending'),
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: CircularProgressIndicator(
                        color: AppColors.mintAccent,
                        backgroundColor: AppColors.mintBackground,
                      ),
                    ),
                  )
                : Container(
                    key: const ValueKey('mpesa_prompt_card'),
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2B2F2D),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'M-PESA',
                          style: AppTypography.sans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.limeAccent,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Pay ${state.amountFormatted} to '
                          '${company.name.toUpperCase()}, Paybill '
                          '${account.effectiveMpesaPaybill}, account '
                          '${account.accountNumber}?',
                          style: AppTypography.sans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.pureWhite,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'A real request asks for your M-Pesa PIN on your '
                          'phone\'s own M-Pesa screen. Makazi never asks for it.',
                          style: AppTypography.sans(
                            fontSize: 12,
                            color: const Color(0xFFB9C2BD),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                key: const ValueKey('mpesa_prompt_decline'),
                                onPressed: notifier.declineMpesaPush,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.pureWhite,
                                  side: const BorderSide(
                                    color: Color(0xFF59615D),
                                  ),
                                  minimumSize: const Size.fromHeight(48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text('Decline'),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: ElevatedButton(
                                key: const ValueKey('mpesa_prompt_approve'),
                                onPressed: notifier.approveMpesaPush,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.limeAccent,
                                  foregroundColor: AppColors.forestGreenDark,
                                  elevation: 0,
                                  minimumSize: const Size.fromHeight(48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text('Approve'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: Text(
              ref.watch(liveDataProvider)
                  ? 'M-Pesa test mode: no money moves.'
                  : 'Demo: no money moves.',
              style: AppTypography.sans(
                fontSize: 12,
                color: AppColors.textMuted,
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
    final receipt = state.completedReceipt;
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
              receipt == null
                  ? 'Your receipt will appear in Payments shortly.'
                  : '${receipt.receiptNumber} · ${receipt.reference}',
              style: AppTypography.sans(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
          ),
          if (receipt?.isTest ?? false) ...[
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: Container(
                key: const ValueKey('test_payment_pill'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.statusPartialBackground,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  border: Border.all(color: AppColors.statusPartialBorder),
                ),
                child: Text(
                  'Test payment · no money moved',
                  style: AppTypography.sans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.statusPartialText,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 40),
          if (receipt != null)
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

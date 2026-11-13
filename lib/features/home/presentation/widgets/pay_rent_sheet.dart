import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prop_mgt_app/core/theme/brand_colors.dart';
import '../../../../core/billing/billing_engine.dart';
import '../../../../core/billing/payment_claim.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../billing/presentation/state/tenant_account_providers.dart';
import '../../../billing/presentation/state/tenant_account_state.dart';
import '../state/home_pay_rent_providers.dart';

/// Pay rent: where to pay, then the confirmation message to send once paid.
/// The app shell shows it as a bottom sheet whenever [homePayRentProvider]
/// opens.
class PayRentSheet extends ConsumerStatefulWidget {
  const PayRentSheet({super.key});

  @override
  ConsumerState<PayRentSheet> createState() => _PayRentSheetState();
}

class _PayRentSheetState extends ConsumerState<PayRentSheet> {
  final _message = TextEditingController();

  @override
  void initState() {
    super.initState();
    final initialMessage = ref.read(homePayRentProvider).message;
    if (initialMessage.isNotEmpty) {
      _message.text = initialMessage;
    }
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text?.trim();
    if (text == null || text.isEmpty || !mounted) return;
    _message.text = text;
    ref.read(homePayRentProvider.notifier).updateMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homePayRentProvider);
    final account = ref.watch(tenantAccountProvider);
    final sent = state.sentClaim;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: sent != null
              ? _SentView(claim: sent, companyName: account.company.name)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.isEditing ? 'Edit payment message' : 'Pay rent',
                      style: AppTypography.editorialSerif(
                        fontSize: 28,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      _balanceLine(account.balance),
                      key: const ValueKey('pay_rent_balance'),
                      style: AppTypography.sans(
                        fontSize: 15,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _PaymentDetails(account: account),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Already paid?',
                            style: AppTypography.sans(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          key: const ValueKey('pay_rent_paste'),
                          onPressed: state.isSending ? null : _paste,
                          icon: const Icon(
                            Icons.content_paste_rounded,
                            size: 18,
                          ),
                          label: const Text('Paste'),
                          style: TextButton.styleFrom(
                            foregroundColor: context.brand.link,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Paste the confirmation message from M-Pesa or your '
                      'bank. ${account.company.name} checks the reference and '
                      'amount against their statement, then your receipt '
                      'appears in Payments.',
                      style: AppTypography.sans(
                        fontSize: 13,
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      key: const ValueKey('pay_rent_message'),
                      controller: _message,
                      enabled: !state.isSending,
                      onChanged: ref
                          .read(homePayRentProvider.notifier)
                          .updateMessage,
                      minLines: 4,
                      maxLines: 8,
                      maxLength: 1000,
                      keyboardType: TextInputType.multiline,
                      style: AppTypography.sans(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Paste the whole message here',
                        filled: true,
                        fillColor: AppColors.cardBackground,
                        contentPadding: const EdgeInsets.all(AppSpacing.md),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: AppColors.borderLight,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: AppColors.borderLight,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: context.brand.link,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    if (state.errorText != null) ...[
                      const SizedBox(height: AppSpacing.xs),
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
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        key: const ValueKey('pay_rent_send'),
                        onPressed: state.canSend
                            ? () {
                                FocusScope.of(context).unfocus();
                                ref
                                    .read(homePayRentProvider.notifier)
                                    .sendMessage();
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.brand.button,
                          foregroundColor: context.brand.onButton,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          state.isSending
                              ? 'Sending…'
                              : state.isEditing
                              ? 'Update & resend'
                              : 'Send for confirmation',
                          style: AppTypography.sans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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

  static String _balanceLine(int balance) => balance > 0
      ? 'Balance due ${formatKes(balance)}'
      : balance < 0
      ? '${formatKes(-balance)} credit on your account'
      : 'Nothing due right now';
}

/// Where to send the money: Paybill and bank, with the tenant's account.
class _PaymentDetails extends StatefulWidget {
  const _PaymentDetails({required this.account});

  final TenantAccountState account;

  @override
  State<_PaymentDetails> createState() => _PaymentDetailsState();
}

class _PaymentDetailsState extends State<_PaymentDetails> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    final account = widget.account;
    final pesalink = account.effectivePesalinkPhone;
    final rows = [
      ('Paybill', account.effectiveMpesaPaybill),
      ('Account', account.accountNumber),
      ('Bank', account.effectiveBankName),
      ('Bank account', account.effectiveBankAccount),
      if (pesalink != null) ('PesaLink phone', pesalink),
    ];

    return Container(
      key: const ValueKey('pay_rent_details'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          for (final (label, value) in rows) ...[
            _DetailRow(label: label, value: value),
            const SizedBox(height: AppSpacing.sm),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(
                    text: [
                      for (final (label, value) in rows) '$label: $value',
                    ].join('\n'),
                  ),
                );
                if (mounted) setState(() => _copied = true);
              },
              icon: Icon(
                _copied ? Icons.check_rounded : Icons.copy_rounded,
                size: 18,
              ),
              label: Text(_copied ? 'Copied' : 'Copy payment details'),
              style: TextButton.styleFrom(foregroundColor: context.brand.link),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.sans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _SentView extends StatelessWidget {
  const _SentView({required this.claim, required this.companyName});

  final PaymentClaim claim;
  final String companyName;

  @override
  Widget build(BuildContext context) {
    final read = [
      if (claim.amount != null) formatKes(claim.amount!),
      if (claim.reference != null) claim.reference!,
    ].join(' · ');

    return Column(
      key: const ValueKey('pay_rent_sent'),
      children: [
        const SizedBox(height: AppSpacing.md),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: context.brand.primary,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_rounded,
            color: context.brand.onPrimary,
            size: 34,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Sent for confirmation',
          textAlign: TextAlign.center,
          style: AppTypography.editorialSerif(
            fontSize: 28,
            fontWeight: FontWeight.w400,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          read.isNotEmpty
              ? read
              : "We couldn't read the amount or reference. $companyName "
                    'will check your message.',
          textAlign: TextAlign.center,
          style: AppTypography.sans(
            fontSize: 15,
            fontWeight: read.isNotEmpty ? FontWeight.w600 : FontWeight.w400,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Your balance updates once $companyName confirms the payment.',
          textAlign: TextAlign.center,
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
          child: ElevatedButton(
            key: const ValueKey('pay_rent_done'),
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.brand.button,
              foregroundColor: context.brand.onButton,
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
              ),
            ),
          ),
        ),
      ],
    );
  }
}

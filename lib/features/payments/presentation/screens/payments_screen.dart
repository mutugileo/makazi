import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/billing/billing_engine.dart';
import '../../../../core/billing/billing_models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/bill_status_chip.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../billing/presentation/state/tenant_account_providers.dart';
import '../../../billing/presentation/state/tenant_account_state.dart';
import '../../domain/models/payment_receipt.dart';
import '../state/payments_providers.dart';
import '../state/payments_ui_state.dart';
import '../widgets/bill_detail_view.dart';
import '../widgets/receipt_detail_view.dart';
import '../widgets/statement_view.dart';

class PaymentsScreen extends ConsumerWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uiState = ref.watch(paymentsProvider);
    final account = ref.watch(tenantAccountProvider);
    final notifier = ref.read(paymentsProvider.notifier);
    final theme = Theme.of(context);
    final motion =
        theme.extension<AppMotionThemeExtension>() ??
        const AppMotionThemeExtension.regular();

    final selectedBill = uiState.selectedBillMonth == null
        ? null
        : account.billFor(uiState.selectedBillMonth!);

    final Widget child;
    if (uiState.showingStatement) {
      child = StatementView(
        key: const ValueKey('statement_view'),
        account: account,
        onBackPressed: notifier.closeStatement,
      );
    } else if (uiState.selectedReceipt != null) {
      child = ReceiptDetailView(
        key: ValueKey(uiState.selectedReceipt!.id),
        receipt: uiState.selectedReceipt!,
        onBackPressed: notifier.clearSelectedReceipt,
      );
    } else if (selectedBill != null) {
      child = BillDetailView(
        key: ValueKey('bill_${selectedBill.month}'),
        bill: selectedBill,
        receipts: account.receipts
            .where((r) => r.billMonth == selectedBill.month)
            .toList(growable: false),
        onBackPressed: notifier.clearSelectedBill,
        onReceiptSelected: notifier.selectReceipt,
      );
    } else {
      child = _PaymentsListView(
        key: const ValueKey('payments_list_view'),
        account: account,
        view: uiState.view,
        onViewChanged: notifier.showView,
        onBillSelected: (bill) => notifier.selectBill(bill.month),
        onReceiptSelected: notifier.selectReceipt,
        onStatementPressed: notifier.showStatement,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        bottom: false,
        child: AnimatedSwitcher(
          duration: motion.stateTransitionDuration,
          switchInCurve: motion.standardEasing,
          switchOutCurve: motion.standardEasing,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.03),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: child,
        ),
      ),
    );
  }
}

class _PaymentsListView extends StatelessWidget {
  const _PaymentsListView({
    super.key,
    required this.account,
    required this.view,
    required this.onViewChanged,
    required this.onBillSelected,
    required this.onReceiptSelected,
    required this.onStatementPressed,
  });

  final TenantAccountState account;
  final PaymentsView view;
  final ValueChanged<PaymentsView> onViewChanged;
  final ValueChanged<MonthlyBill> onBillSelected;
  final ValueChanged<PaymentReceipt> onReceiptSelected;
  final VoidCallback onStatementPressed;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final systemBottomPadding = mediaQuery.padding.bottom;
    final scrollBottomPadding = systemBottomPadding + 86.0;
    final balance = account.balance;
    final bills = account.bills.reversed.toList(growable: false);
    final receipts = account.receipts;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        scrollBottomPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payments',
            style: AppTypography.editorialSerif(
              fontSize: 38,
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title:
                      'Paid since ${BillingDates.shortMonth(account.company.settings.ledgerStartMonth)}',
                  amount: formatKes(account.totalPaid),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _StatCard(
                  title: balance < 0 ? 'Credit' : 'Balance',
                  amount: formatKes(balance.abs()),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _DepositStrip(account: account),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const ValueKey('open_statement'),
              onPressed: onStatementPressed,
              icon: const Icon(
                Icons.description_outlined,
                size: 18,
                color: AppColors.mintAccent,
              ),
              label: Text(
                'Statement of payments',
                style: AppTypography.sans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mintAccent,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _ViewToggle(view: view, onChanged: onViewChanged),
          const SizedBox(height: AppSpacing.md),
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              children: view == PaymentsView.bills
                  ? [
                      if (bills.isEmpty)
                        const EmptyState(
                          icon: Icons.description_outlined,
                          title: 'No bills yet',
                          message: 'Bills are issued on the 1st of each month.',
                        ),
                      for (int i = 0; i < bills.length; i++) ...[
                        if (i > 0)
                          const Divider(
                            height: 1,
                            color: AppColors.borderLight,
                          ),
                        _BillTile(
                          bill: bills[i],
                          onTap: () => onBillSelected(bills[i]),
                        ),
                      ],
                    ]
                  : [
                      if (receipts.isEmpty)
                        const EmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: 'No payments yet',
                          message: 'Every payment gets a receipt here.',
                        ),
                      for (int i = 0; i < receipts.length; i++) ...[
                        if (i > 0)
                          const Divider(
                            height: 1,
                            color: AppColors.borderLight,
                          ),
                        _ReceiptTile(
                          receipt: receipts[i],
                          onTap: () => onReceiptSelected(receipts[i]),
                        ),
                      ],
                    ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.view, required this.onChanged});

  final PaymentsView view;
  final ValueChanged<PaymentsView> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget segment(PaymentsView value, String label) {
      final selected = view == value;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(value),
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? AppColors.textPrimary : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AppTypography.sans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.pureWhite : AppColors.textMuted,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          segment(PaymentsView.bills, 'Bills'),
          segment(PaymentsView.receipts, 'Receipts'),
        ],
      ),
    );
  }
}

class _DepositStrip extends StatelessWidget {
  const _DepositStrip({required this.account});

  final TenantAccountState account;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.mintBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            size: 18,
            color: AppColors.mintAccent,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              account.isActive
                  ? 'Deposit held · refundable when you move out'
                  : 'Deposit settled on your final bill',
              style: AppTypography.sans(
                fontSize: 13,
                color: AppColors.forestGreen,
              ),
            ),
          ),
          if (account.isActive)
            Text(
              formatKes(account.depositHeld),
              style: AppTypography.sans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.forestGreen,
                tabularFigures: true,
              ),
            ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.amount});

  final String title;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            title,
            style: AppTypography.sans(fontSize: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              style: AppTypography.editorialSerif(
                fontSize: 26,
                fontWeight: FontWeight.w400,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _BillTile extends StatelessWidget {
  const _BillTile({required this.bill, required this.onTap});

  final MonthlyBill bill;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final kindLabel = switch (bill.kind) {
      BillKind.moveIn => ' · Move-in',
      BillKind.finalBill => ' · Final',
      BillKind.monthly => '',
    };
    final subtitle = bill.outstanding > 0
        ? 'Outstanding ${formatKes(bill.outstanding)}'
        : bill.datePaid != null
        ? 'Paid ${BillingDates.formatDayMonth(bill.datePaid!)}'
        : 'Nothing to pay';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${BillingDates.monthLabel(bill.month)}$kindLabel',
                    style: AppTypography.sans(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${formatKes(bill.totalDue)} due · $subtitle',
                    style: AppTypography.sans(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            BillStatusChip(status: bill.status),
          ],
        ),
      ),
    );
  }
}

class _ReceiptTile extends StatelessWidget {
  const _ReceiptTile({required this.receipt, required this.onTap});

  final PaymentReceipt receipt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.mintBackground,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  receipt.initial,
                  style: AppTypography.sans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mintAccent,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    receipt.forDescription,
                    style: AppTypography.sans(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${receipt.receiptNumber} · ${receipt.dateLabel}',
                    style: AppTypography.sans(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              receipt.amountLabel,
              style: AppTypography.sans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                tabularFigures: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

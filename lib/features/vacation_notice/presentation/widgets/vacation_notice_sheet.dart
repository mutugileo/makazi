import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/billing/billing_engine.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../billing/presentation/state/tenant_account_providers.dart';
import '../state/vacation_notice_providers.dart';

class VacationNoticeSheet extends ConsumerWidget {
  const VacationNoticeSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const VacationNoticeSheet(),
    );
  }

  static const List<String> commonReasons = [
    'Relocation / Job Transfer',
    'Moving to Own Home',
    'Need Bigger Space',
    'Downsizing',
    'Rent / Financial',
    'Commute Distance',
    'Other',
  ];

  static const List<String> inspectionSlots = [
    'Morning (9:00 AM – 12:00 PM)',
    'Afternoon (2:00 PM – 5:00 PM)',
  ];

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select date';
    final iso =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return BillingDates.formatDayMonth(iso);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(vacationNoticeProvider);
    final notifier = ref.read(vacationNoticeProvider.notifier);
    final account = ref.watch(tenantAccountProvider);
    final companyTheme = account.company.settings.theme;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Material(
      color: AppColors.cardBackground,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        constraints: BoxConstraints(maxHeight: screenHeight * 0.90),
        padding: EdgeInsets.only(bottom: keyboardInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle and top bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                4,
                AppSpacing.lg,
                12,
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.mintBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.door_back_door_outlined,
                      color: AppColors.mintAccent,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notice to Vacate',
                          style: AppTypography.editorialSerif(
                            fontSize: 22,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          account.unitTitle,
                          style: AppTypography.sans(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('close_vacation_notice_button'),
                    icon: const Icon(Icons.close_rounded, size: 22),
                    color: AppColors.textMuted,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.borderLight),

            // Sheet body content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: state.hasActiveNotice
                    ? _ActiveNoticeView(
                        notice: state.activeNotice!,
                        primaryColor: companyTheme.primaryColor,
                        onWithdraw: () {
                          notifier.withdrawNotice();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Vacation notice withdrawn',
                                style: AppTypography.sans(
                                  fontSize: 14,
                                  color: AppColors.pureWhite,
                                ),
                              ),
                              backgroundColor: AppColors.textPrimary,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      )
                    : _NoticeFormView(
                        state: state,
                        notifier: notifier,
                        companyThemePrimary: companyTheme.primaryColor,
                        formatDate: _formatDate,
                        onSubmit: () async {
                          final success = await notifier.submitNotice();
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Vacation notice registered successfully',
                                  style: AppTypography.sans(
                                    fontSize: 14,
                                    color: AppColors.pureWhite,
                                  ),
                                ),
                                backgroundColor: companyTheme.primaryColor,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveNoticeView extends StatelessWidget {
  const _ActiveNoticeView({
    required this.notice,
    required this.primaryColor,
    required this.onWithdraw,
  });

  final dynamic notice;
  final Color primaryColor;
  final VoidCallback onWithdraw;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.statusPaidBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.statusPaidBorder),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                color: AppColors.statusPaidText,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notice Registered',
                      style: AppTypography.sans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.statusPaidText,
                      ),
                    ),
                    Text(
                      'Reference: ${notice.id}',
                      style: AppTypography.sans(
                        fontSize: 12,
                        color: AppColors.statusPaidText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Key Dates Card
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.pageBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            children: [
              _DetailRow(
                icon: Icons.event_outlined,
                title: 'Planned Move-Out Date',
                value: BillingDates.formatDayMonth(notice.vacatingDate),
              ),
              const Divider(height: 20, color: AppColors.borderLight),
              _DetailRow(
                icon: Icons.checklist_rtl_rounded,
                title: 'Joint Inspection',
                value:
                    '${BillingDates.formatDayMonth(notice.inspectionDate)}\n${notice.inspectionTimeSlot}',
              ),
              const Divider(height: 20, color: AppColors.borderLight),
              _DetailRow(
                icon: Icons.help_outline_rounded,
                title: 'Reason Stated',
                value: notice.reason,
              ),
              if (notice.depositRefundPhone != null &&
                  notice.depositRefundPhone.isNotEmpty) ...[
                const Divider(height: 20, color: AppColors.borderLight),
                _DetailRow(
                  icon: Icons.phone_android_rounded,
                  title: 'Refund Contact',
                  value: notice.depositRefundPhone,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Move-out Guide & Requirements Checklist
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Vacating Requirements & Checklist',
                      style: AppTypography.sans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.statusPaidBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Deposit Protected',
                      style: AppTypography.sans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.statusPaidText,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const _RequirementChecklistRow(
                isDone: true,
                title: '1. 30-Day Notice Registered',
                subtitle:
                    'Notice submitted and logged with property management',
              ),
              const SizedBox(height: 10),
              _RequirementChecklistRow(
                isDone: false,
                title: '2. Joint Move-out Inspection',
                subtitle:
                    'Scheduled for ${BillingDates.formatDayMonth(notice.inspectionDate)} (${notice.inspectionTimeSlot})',
              ),
              const SizedBox(height: 10),
              const _RequirementChecklistRow(
                isDone: false,
                title: '3. Utility Clearance & Meter Reading',
                subtitle:
                    'Record final water meter reading with caretaker & clear electricity tokens',
              ),
              const SizedBox(height: 10),
              const _RequirementChecklistRow(
                isDone: false,
                title: '4. Unit Cleaning & Restoration',
                subtitle:
                    'Patch nail holes and leave unit swept, clean and empty of belongings',
              ),
              const SizedBox(height: 10),
              const _RequirementChecklistRow(
                isDone: false,
                title: '5. Keys & Access Card Handover',
                subtitle:
                    'Surrender all door keys, grilles, and gate access cards on departure',
              ),
              const SizedBox(height: 10),
              _RequirementChecklistRow(
                isDone: false,
                title: '6. Security Deposit Refund',
                subtitle:
                    'Reconciled and sent to ${notice.depositRefundPhone ?? "registered contact"} within 14-30 days',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        OutlinedButton(
          key: const ValueKey('withdraw_vacation_notice_button'),
          onPressed: () {
            showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(
                  'Withdraw vacation notice?',
                  style: AppTypography.editorialSerif(
                    fontSize: 20,
                    color: AppColors.textPrimary,
                  ),
                ),
                content: Text(
                  'This will cancel your scheduled move-out date and inform property management.',
                  style: AppTypography.sans(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text(
                      'Keep notice',
                      style: AppTypography.sans(color: AppColors.textMuted),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(ctx).pop(true);
                      onWithdraw();
                    },
                    child: Text(
                      'Withdraw',
                      style: AppTypography.sans(
                        color: AppColors.terracotta,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: const BorderSide(color: AppColors.borderStrong),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            'Withdraw notice',
            style: AppTypography.sans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.terracotta,
            ),
          ),
        ),
      ],
    );
  }
}

class _NoticeFormView extends StatelessWidget {
  const _NoticeFormView({
    required this.state,
    required this.notifier,
    required this.companyThemePrimary,
    required this.formatDate,
    required this.onSubmit,
  });

  final dynamic state;
  final dynamic notifier;
  final Color companyThemePrimary;
  final String Function(DateTime?) formatDate;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Informational guideline banner
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.mintBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.mintAccent.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: AppColors.mintAccent,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Standard tenancy agreements request at least 30 days written notice before vacating.',
                  style: AppTypography.sans(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Requirements for a successful vacating
        _VacatingRequirementsCard(primaryColor: companyThemePrimary),
        const SizedBox(height: AppSpacing.lg),

        // SECTION 1: Vacating Date
        Text(
          'PLANNED MOVE-OUT DATE',
          style: AppTypography.sans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          key: const ValueKey('vacating_date_selector'),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate:
                  state.vacatingDate ?? now.add(const Duration(days: 30)),
              firstDate: now,
              lastDate: now.add(const Duration(days: 365)),
            );
            if (picked != null) {
              notifier.updateVacatingDate(picked);
            }
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderStrong),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    formatDate(state.vacatingDate),
                    style: AppTypography.sans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  'Change',
                  style: AppTypography.sans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: companyThemePrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Quick date presets
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _PresetChip(
              label: 'In 30 days',
              onTap: () => notifier.updateVacatingDate(
                DateTime(
                  now.year,
                  now.month,
                  now.day,
                ).add(const Duration(days: 30)),
              ),
            ),
            _PresetChip(
              label: 'End of next month',
              onTap: () {
                final nextMonth = DateTime(now.year, now.month + 2, 0);
                notifier.updateVacatingDate(nextMonth);
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // SECTION 2: Inspection Data
        Text(
          'MOVE-OUT INSPECTION',
          style: AppTypography.sans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          key: const ValueKey('inspection_date_selector'),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate:
                  state.inspectionDate ??
                  (state.vacatingDate ?? now.add(const Duration(days: 28))),
              firstDate: now,
              lastDate:
                  state.vacatingDate ?? now.add(const Duration(days: 365)),
            );
            if (picked != null) {
              notifier.updateInspectionDate(picked);
            }
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderStrong),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.checklist_rtl_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Inspection date: ${formatDate(state.inspectionDate)}',
                        style: AppTypography.sans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Joint inspection before handing over keys',
                        style: AppTypography.sans(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Change',
                  style: AppTypography.sans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: companyThemePrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Inspection Time Window Slots
        Text(
          'Preferred inspection window:',
          style: AppTypography.sans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: VacationNoticeSheet.inspectionSlots.map((slot) {
            final isSelected = state.inspectionTimeSlot == slot;
            return ChoiceChip(
              key: ValueKey('slot_$slot'),
              label: Text(
                slot,
                style: AppTypography.sans(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? companyThemePrimary
                      : AppColors.textSecondary,
                ),
              ),
              selected: isSelected,
              selectedColor: companyThemePrimary.withValues(alpha: 0.15),
              backgroundColor: AppColors.pageBackground,
              side: BorderSide(
                color: isSelected ? companyThemePrimary : AppColors.borderLight,
              ),
              onSelected: (selected) {
                if (selected) notifier.selectInspectionTimeSlot(slot);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.lg),

        // SECTION 3: Reason for Vacating
        Text(
          'REASON FOR VACATING',
          style: AppTypography.sans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: VacationNoticeSheet.commonReasons.map((reason) {
            final isSelected = state.selectedReason == reason;
            return ChoiceChip(
              key: ValueKey('reason_$reason'),
              label: Text(
                reason,
                style: AppTypography.sans(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? companyThemePrimary
                      : AppColors.textSecondary,
                ),
              ),
              selected: isSelected,
              selectedColor: companyThemePrimary.withValues(alpha: 0.15),
              backgroundColor: AppColors.pageBackground,
              side: BorderSide(
                color: isSelected ? companyThemePrimary : AppColors.borderLight,
              ),
              onSelected: (selected) {
                if (selected) notifier.selectReason(reason);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 12),

        // Additional notes
        TextField(
          key: const ValueKey('vacation_reason_details_input'),
          onChanged: notifier.updateReasonDetails,
          maxLines: 2,
          style: AppTypography.sans(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Additional notes or reason details for the manager',
            hintStyle: AppTypography.sans(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
            filled: true,
            fillColor: AppColors.pageBackground,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: companyThemePrimary, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // SECTION 4: Deposit Refund M-Pesa Contact
        Text(
          'SECURITY DEPOSIT REFUND NUMBER',
          style: AppTypography.sans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          key: const ValueKey('vacation_deposit_refund_phone_input'),
          controller: TextEditingController(text: state.depositRefundPhone)
            ..selection = TextSelection.fromPosition(
              TextPosition(offset: state.depositRefundPhone.length),
            ),
          onChanged: notifier.updateDepositRefundPhone,
          keyboardType: TextInputType.phone,
          style: AppTypography.sans(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'M-Pesa phone number for deposit balance settlement',
            hintStyle: AppTypography.sans(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
            prefixIcon: const Icon(Icons.phone_android_rounded, size: 20),
            filled: true,
            fillColor: AppColors.pageBackground,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: companyThemePrimary, width: 1.5),
            ),
          ),
        ),

        if (state.submitError != null) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.terracottaLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.terracotta.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.terracotta,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.submitError!,
                    style: AppTypography.sans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.terracotta,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.xl),

        // Submit Button
        SizedBox(
          height: 52,
          child: ElevatedButton(
            key: const ValueKey('submit_vacation_notice_button'),
            onPressed: state.isSubmitting ? null : onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: companyThemePrimary,
              foregroundColor: AppColors.pureWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: state.isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: AppColors.pureWhite,
                    ),
                  )
                : Text(
                    'Submit vacation notice',
                    style: AppTypography.sans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.pureWhite,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.sans(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTypography.sans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.pageBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Text(
          label,
          style: AppTypography.sans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _VacatingRequirementsCard extends StatefulWidget {
  const _VacatingRequirementsCard({required this.primaryColor});

  final Color primaryColor;

  @override
  State<_VacatingRequirementsCard> createState() =>
      _VacatingRequirementsCardState();
}

class _VacatingRequirementsCardState extends State<_VacatingRequirementsCard> {
  bool _isExpanded = false;

  static const List<_VacatingRule> _rules = [
    _VacatingRule(
      number: '1',
      title: '30-Day Written Notice',
      description:
          'Submit notice at least 30 calendar days before departure (by the 1st of your moving month) to protect your deposit.',
      icon: Icons.calendar_month_outlined,
    ),
    _VacatingRule(
      number: '2',
      title: 'Zero Rent & Utility Arrears',
      description:
          'Rent must be fully settled up to the moving date. Settle KPLC tokens and allow a final water meter delta reading.',
      icon: Icons.receipt_long_outlined,
    ),
    _VacatingRule(
      number: '3',
      title: 'Joint Move-Out Inspection',
      description:
          'Walk through the unit with the caretaker or manager to record final meter readings and verify physical condition.',
      icon: Icons.checklist_rtl_rounded,
    ),
    _VacatingRule(
      number: '4',
      title: 'Unit Cleaning & Restoration',
      description:
          'Clear all personal belongings and rubbish. Patch picture hook holes and leave walls, tiles, and fittings clean.',
      icon: Icons.cleaning_services_outlined,
    ),
    _VacatingRule(
      number: '5',
      title: 'Keys & Access Card Handover',
      description:
          'Surrender all duplicate room keys, grille keys, and electronic gate fobs or remotes during the final walk-through.',
      icon: Icons.vpn_key_outlined,
    ),
    _VacatingRule(
      number: '6',
      title: 'Deposit Reconciliation & Refund',
      description:
          'Security deposit is reconciled within 14 to 30 days post-handover, with any water or repair deductions itemized.',
      icon: Icons.payments_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.pageBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            key: const ValueKey('toggle_vacating_requirements_button'),
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: widget.primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.assignment_turned_in_outlined,
                      color: widget.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Requirements for Successful Vacating',
                          style: AppTypography.sans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _isExpanded
                              ? 'Tap to collapse move-out criteria'
                              : '6 criteria for a full deposit refund',
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
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textMuted,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            const Divider(height: 1, color: AppColors.borderLight),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Column(
                children: _rules.map((rule) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: widget.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            rule.number,
                            style: AppTypography.sans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.pureWhite,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                rule.title,
                                style: AppTypography.sans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                rule.description,
                                style: AppTypography.sans(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VacatingRule {
  const _VacatingRule({
    required this.number,
    required this.title,
    required this.description,
    required this.icon,
  });

  final String number;
  final String title;
  final String description;
  final IconData icon;
}

class _RequirementChecklistRow extends StatelessWidget {
  const _RequirementChecklistRow({
    required this.isDone,
    required this.title,
    required this.subtitle,
  });

  final bool isDone;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          margin: const EdgeInsets.only(top: 1),
          decoration: BoxDecoration(
            color: isDone ? AppColors.mintAccent : AppColors.pageBackground,
            shape: BoxShape.circle,
            border: Border.all(
              color: isDone ? AppColors.mintAccent : AppColors.borderStrong,
              width: 1.5,
            ),
          ),
          child: isDone
              ? const Icon(Icons.check, size: 13, color: AppColors.pureWhite)
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.sans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDone
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: AppTypography.sans(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

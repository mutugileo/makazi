import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/data/data_mode.dart';
import '../../../../core/data/supabase_billing_providers.dart';
import '../../../billing/presentation/state/tenant_account_providers.dart';
import '../../domain/models/vacation_notice.dart';
import 'vacation_notice_ui_state.dart';

class VacationNoticeNotifier extends Notifier<VacationNoticeUiState> {
  @override
  VacationNoticeUiState build() {
    final account = ref.watch(tenantAccountProvider);
    final now = DateTime.now();
    final defaultVacating = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 30));
    final defaultInspection = defaultVacating.subtract(const Duration(days: 2));

    return VacationNoticeUiState(
      vacatingDate: defaultVacating,
      inspectionDate: defaultInspection,
      depositRefundPhone: account.tenant.phone,
    );
  }

  void updateVacatingDate(DateTime date) {
    var inspection = state.inspectionDate;
    if (inspection == null || inspection.isAfter(date)) {
      inspection = date.subtract(const Duration(days: 2));
      if (inspection.isBefore(DateTime.now())) {
        inspection = date;
      }
    }
    state = state.copyWith(
      vacatingDate: () => date,
      inspectionDate: () => inspection,
      submitError: () => null,
    );
  }

  void updateInspectionDate(DateTime date) {
    state = state.copyWith(inspectionDate: () => date, submitError: () => null);
  }

  void selectInspectionTimeSlot(String slot) {
    state = state.copyWith(inspectionTimeSlot: slot);
  }

  void selectReason(String reason) {
    state = state.copyWith(selectedReason: reason, submitError: () => null);
  }

  void updateReasonDetails(String details) {
    state = state.copyWith(reasonDetails: details);
  }

  void updateDepositRefundPhone(String phone) {
    state = state.copyWith(depositRefundPhone: phone);
  }

  Future<bool> submitNotice() async {
    final vacating = state.vacatingDate;
    final inspection = state.inspectionDate;
    final reason = state.selectedReason.trim();

    if (vacating == null) {
      state = state.copyWith(
        submitError: () => 'Select your planned vacating date.',
      );
      return false;
    }

    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    if (vacating.isBefore(startOfToday)) {
      state = state.copyWith(
        submitError: () => 'Vacating date must be today or in the future.',
      );
      return false;
    }

    if (inspection == null) {
      state = state.copyWith(
        submitError: () => 'Select your preferred inspection date.',
      );
      return false;
    }

    if (inspection.isAfter(vacating)) {
      state = state.copyWith(
        submitError: () =>
            'Inspection date must be on or before your vacating date.',
      );
      return false;
    }

    if (reason.isEmpty) {
      state = state.copyWith(
        submitError: () => 'Please choose a reason for vacating.',
      );
      return false;
    }

    state = state.copyWith(isSubmitting: true, submitError: () => null);

    final account = ref.read(tenantAccountProvider);
    final vacatingStr =
        '${vacating.year}-${vacating.month.toString().padLeft(2, '0')}-${vacating.day.toString().padLeft(2, '0')}';
    final inspectionStr =
        '${inspection.year}-${inspection.month.toString().padLeft(2, '0')}-${inspection.day.toString().padLeft(2, '0')}';

    final notice = VacationNotice(
      id: 'VN-${DateTime.now().millisecondsSinceEpoch % 100000}',
      tenancyId: account.tenancy.id,
      unitTitle: account.unitTitle,
      vacatingDate: vacatingStr,
      inspectionDate: inspectionStr,
      inspectionTimeSlot: state.inspectionTimeSlot,
      reason: reason,
      reasonDetails: state.reasonDetails.trim().isEmpty
          ? null
          : state.reasonDetails.trim(),
      depositRefundPhone: state.depositRefundPhone.trim().isEmpty
          ? account.tenant.phone
          : state.depositRefundPhone.trim(),
      status: VacationNoticeStatus.submitted,
      submittedAt: DateTime.now().toIso8601String(),
    );

    if (ref.read(liveDataProvider)) {
      try {
        final noticeSummary =
            '[Vacation Notice] Tenant ${account.tenant.name} (${account.unitTitle}) '
            'has submitted notice to vacate.\n'
            'Vacating Date: $vacatingStr\n'
            'Inspection: $inspectionStr (${state.inspectionTimeSlot})\n'
            'Reason: $reason'
            '${state.reasonDetails.trim().isNotEmpty ? '\nNotes: ${state.reasonDetails.trim()}' : ''}\n'
            'Deposit Refund Contact: ${notice.depositRefundPhone}';

        await ref
            .read(supabaseBillingRepositoryProvider)
            .sendMessage(
              companyId: account.company.id,
              tenancyId: account.tenancy.id,
              body: noticeSummary,
            );
      } catch (_) {
        if (!ref.mounted) return false;
        state = state.copyWith(
          isSubmitting: false,
          submitError: () =>
              'Failed to submit notice to management. Check your connection.',
        );
        return false;
      }
    } else {
      await Future<void>.delayed(const Duration(milliseconds: 600));
    }

    if (!ref.mounted) return false;
    state = state.copyWith(
      isSubmitting: false,
      isSuccess: true,
      activeNotice: () => notice,
    );
    return true;
  }

  void withdrawNotice() {
    state = state.copyWith(
      activeNotice: () => null,
      isSuccess: false,
      submitError: () => null,
    );
  }

  void resetSuccess() {
    state = state.copyWith(isSuccess: false);
  }
}

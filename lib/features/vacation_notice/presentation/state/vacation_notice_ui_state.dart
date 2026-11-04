import 'package:flutter/foundation.dart';
import '../../domain/models/vacation_notice.dart';

@immutable
class VacationNoticeUiState {
  const VacationNoticeUiState({
    this.activeNotice,
    this.vacatingDate,
    this.inspectionDate,
    this.inspectionTimeSlot = 'Morning (9:00 AM – 12:00 PM)',
    this.selectedReason = 'Relocation / Job Transfer',
    this.reasonDetails = '',
    this.depositRefundPhone = '',
    this.isSubmitting = false,
    this.submitError,
    this.isSuccess = false,
  });

  final VacationNotice? activeNotice;
  final DateTime? vacatingDate;
  final DateTime? inspectionDate;
  final String inspectionTimeSlot;
  final String selectedReason;
  final String reasonDetails;
  final String depositRefundPhone;
  final bool isSubmitting;
  final String? submitError;
  final bool isSuccess;

  bool get hasActiveNotice => activeNotice != null && activeNotice!.isActive;

  VacationNoticeUiState copyWith({
    VacationNotice? Function()? activeNotice,
    DateTime? Function()? vacatingDate,
    DateTime? Function()? inspectionDate,
    String? inspectionTimeSlot,
    String? selectedReason,
    String? reasonDetails,
    String? depositRefundPhone,
    bool? isSubmitting,
    String? Function()? submitError,
    bool? isSuccess,
  }) {
    return VacationNoticeUiState(
      activeNotice: activeNotice != null ? activeNotice() : this.activeNotice,
      vacatingDate: vacatingDate != null ? vacatingDate() : this.vacatingDate,
      inspectionDate: inspectionDate != null
          ? inspectionDate()
          : this.inspectionDate,
      inspectionTimeSlot: inspectionTimeSlot ?? this.inspectionTimeSlot,
      selectedReason: selectedReason ?? this.selectedReason,
      reasonDetails: reasonDetails ?? this.reasonDetails,
      depositRefundPhone: depositRefundPhone ?? this.depositRefundPhone,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: submitError != null ? submitError() : this.submitError,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

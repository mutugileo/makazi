import 'package:flutter/foundation.dart';

enum VacationNoticeStatus {
  submitted('Submitted', 'Notice registered with management'),
  inspectionScheduled('Inspection Scheduled', 'Move-out inspection confirmed'),
  completed('Completed', 'Move-out completed & deposit settled'),
  withdrawn('Withdrawn', 'Notice cancelled by tenant');

  const VacationNoticeStatus(this.label, this.description);
  final String label;
  final String description;
}

@immutable
class VacationNotice {
  const VacationNotice({
    required this.id,
    required this.tenancyId,
    required this.unitTitle,
    required this.vacatingDate,
    required this.inspectionDate,
    required this.inspectionTimeSlot,
    required this.reason,
    this.reasonDetails,
    this.depositRefundPhone,
    required this.status,
    required this.submittedAt,
  });

  final String id;
  final String tenancyId;
  final String unitTitle;
  final String vacatingDate;
  final String inspectionDate;
  final String inspectionTimeSlot;
  final String reason;
  final String? reasonDetails;
  final String? depositRefundPhone;
  final VacationNoticeStatus status;
  final String submittedAt;

  bool get isActive =>
      status == VacationNoticeStatus.submitted ||
      status == VacationNoticeStatus.inspectionScheduled;

  VacationNotice copyWith({
    String? id,
    String? tenancyId,
    String? unitTitle,
    String? vacatingDate,
    String? inspectionDate,
    String? inspectionTimeSlot,
    String? reason,
    String? reasonDetails,
    String? depositRefundPhone,
    VacationNoticeStatus? status,
    String? submittedAt,
  }) {
    return VacationNotice(
      id: id ?? this.id,
      tenancyId: tenancyId ?? this.tenancyId,
      unitTitle: unitTitle ?? this.unitTitle,
      vacatingDate: vacatingDate ?? this.vacatingDate,
      inspectionDate: inspectionDate ?? this.inspectionDate,
      inspectionTimeSlot: inspectionTimeSlot ?? this.inspectionTimeSlot,
      reason: reason ?? this.reason,
      reasonDetails: reasonDetails ?? this.reasonDetails,
      depositRefundPhone: depositRefundPhone ?? this.depositRefundPhone,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
    );
  }
}

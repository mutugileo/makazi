import 'package:flutter_test/flutter_test.dart';
import 'package:prop_mgt_app/core/billing/billing_models.dart';
import 'package:prop_mgt_app/core/data/supabase_billing_repository.dart';
import 'package:prop_mgt_app/features/repairs/domain/models/repair_ticket.dart';
import 'package:prop_mgt_app/features/repairs/presentation/state/repairs_notifier.dart';

RepairTicketRecord _record({
  String status = 'in_progress',
  String? assignedTo = 'Otieno Fundi Services',
  String? assignedPhone = '+254712345678',
  String? visitAt = '2026-10-09T14:00:00+03:00',
}) => RepairTicketRecord(
  id: 'MT-1048',
  companyId: 'harborridge',
  tenancyId: 'L-2160',
  unitId: 'rc-5a',
  category: 'plumbing',
  priority: 'medium',
  status: status,
  title: 'Kitchen tap leaking',
  description: '',
  hasPhoto: false,
  createdAt: '2026-10-07T09:00:00+03:00',
  resolvedAt: status == 'resolved' ? '2026-10-10T12:00:00+03:00' : null,
  assignedTo: assignedTo,
  resolutionNote: null,
  assignedPhone: assignedPhone,
  visitAt: visitAt,
);

void main() {
  group('repairVisitLabel', () {
    test('reads the Nairobi time as written', () {
      expect(
        repairVisitLabel('2026-10-09T14:00:00+03:00'),
        'Fri 9 Oct, 2:00 pm',
      );
      expect(
        repairVisitLabel('2026-10-12T00:30:00+03:00'),
        'Mon 12 Oct, 12:30 am',
      );
      expect(
        repairVisitLabel('2026-10-08T12:05:00+03:00'),
        'Thu 8 Oct, 12:05 pm',
      );
    });
  });

  group('repairTicketFromRecord', () {
    test('an in-progress ticket carries who, their number and when', () {
      final visit = repairTicketFromRecord(_record()).visit!;
      expect(visit.name, 'Otieno Fundi Services');
      expect(visit.phone, '+254712345678');
      expect(visit.phoneLabel, '0712 345 678');
      expect(visit.whenLabel, 'Fri 9 Oct, 2:00 pm');
    });

    test('no visit time yet is allowed', () {
      final visit = repairTicketFromRecord(_record(visitAt: null)).visit!;
      expect(visit.whenLabel, isNull);
    });

    test('open and resolved tickets show no visit panel', () {
      expect(repairTicketFromRecord(_record(status: 'open')).visit, isNull);
      final resolved = repairTicketFromRecord(_record(status: 'resolved'));
      expect(resolved.visit, isNull);
      expect(resolved.subtitle, startsWith('Fixed by Otieno Fundi Services'));
    });

    test('in progress without an assignee shows no panel', () {
      expect(repairTicketFromRecord(_record(assignedTo: null)).visit, isNull);
    });
  });

  test('database rows map the visit fields, in Nairobi time', () {
    final record = SupabaseBillingRepository.ticketFromRow({
      'id': 'MT-1048',
      'company_id': 'harborridge',
      'tenancy_id': 'L-2160',
      'unit_id': 'rc-5a',
      'category': 'plumbing',
      'priority': 'medium',
      'status': 'in_progress',
      'title': 'Kitchen tap leaking',
      'description': '',
      'has_photo': false,
      'created_at': '2026-10-07T06:00:00+00:00',
      'resolved_at': null,
      'assigned_to': 'Otieno Fundi Services',
      'resolution_note': null,
      'assigned_phone': '+254712345678',
      'visit_at': '2026-10-09T11:00:00+00:00',
    });
    expect(record.assignedPhone, '+254712345678');
    expect(record.visitAt, '2026-10-09T14:00:00+03:00');
    expect(
      RepairVisit(name: 'x', phone: record.assignedPhone).phoneLabel,
      '0712 345 678',
    );
  });
}

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/billing/billing_engine.dart';
import '../../../../core/billing/billing_models.dart';
import '../../../../core/data/data_mode.dart';
import '../../../../core/data/supabase_billing_providers.dart';
import '../../../billing/presentation/state/tenant_account_providers.dart';
import '../../domain/models/repair_ticket.dart';
import 'repairs_ui_state.dart';

/// Turns a stored ticket into the tenant's list item.
RepairTicket repairTicketFromRecord(RepairTicketRecord record) {
  final status = RepairStatus.fromWire(record.status);
  final created = BillingDates.formatDayMonth(
    record.createdAt.substring(0, 10),
  );
  final subtitle = switch (status) {
    RepairStatus.resolved =>
      'Fixed${record.assignedTo == null ? '' : ' by ${record.assignedTo}'}, '
          '${BillingDates.formatDayMonth((record.resolvedAt ?? record.createdAt).substring(0, 10))}',
    // Who's going and when show in their own panel on the card.
    RepairStatus.inProgress => 'Submitted $created · In progress',
    RepairStatus.open => 'Submitted $created · Open',
    RepairStatus.voided => 'Closed · Deemed irrelevant / voided',
  };
  final assignee = record.assignedTo;
  return RepairTicket(
    id: record.id,
    category: RepairCategory.fromWire(record.category),
    title: record.title,
    subtitle: subtitle,
    status: status,
    priority: RepairPriority.fromWire(record.priority),
    hasPhoto: record.hasPhoto,
    visit: status == RepairStatus.inProgress && assignee != null
        ? RepairVisit(
            name: assignee,
            phone: record.assignedPhone,
            whenLabel: record.visitAt == null
                ? null
                : repairVisitLabel(record.visitAt!),
          )
        : null,
  );
}

/// "Thu 9 Oct, 2:00 pm" from a Nairobi-time ISO string, read as written
/// (the offset is already Nairobi's), so the phone's own time zone can't
/// shift it.
String repairVisitLabel(String nairobiIso) {
  final date = nairobiIso.substring(0, 10);
  final weekday =
      const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][DateTime.utc(
            int.parse(date.substring(0, 4)),
            int.parse(date.substring(5, 7)),
            int.parse(date.substring(8, 10)),
          ).weekday -
          1];
  final hour24 = int.parse(nairobiIso.substring(11, 13));
  final minute = nairobiIso.substring(14, 16);
  final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
  final meridiem = hour24 < 12 ? 'am' : 'pm';
  return '$weekday ${BillingDates.formatDayMonth(date)}, $hour12:$minute $meridiem';
}

List<RepairTicket> _ticketsNewestFirst(List<RepairTicketRecord> records) => [
  for (final r in [
    ...records,
  ]..sort((a, b) => b.createdAt.compareTo(a.createdAt)))
    repairTicketFromRecord(r),
];

class RepairsNotifier extends Notifier<RepairsUiState> {
  /// Demo build only: tickets raised on this phone (the database numbers
  /// them in the live app).
  int _raised = 0;

  int get _nextDemoTicketNumber =>
      ref.read(tenantAccountProvider).company.repairTicketSequence +
      1 +
      _raised;

  @override
  RepairsUiState build() {
    // Follow the account as it refreshes, without resetting an open form.
    ref.listen(
      tenantAccountProvider.select((a) => a.seed.repairTickets),
      (_, records) =>
          state = state.copyWith(tickets: _ticketsNewestFirst(records)),
    );
    return RepairsUiState.initial(
      _ticketsNewestFirst(ref.read(tenantAccountProvider).seed.repairTickets),
    );
  }

  void openNewRequest() {
    if (!ref.read(tenantAccountProvider).isActive) return;
    state = state.copyWith(
      isNewRequestOpen: true,
      selectedCategory: () => RepairCategory.plumbing,
      description: '',
      attachedPhotoCount: 0,
      attachedPhotoPath: () => null,
      isSubmitting: false,
      newlyCreatedTicket: () => null,
      submitError: () => null,
    );
  }

  void closeNewRequest() {
    if (state.isSubmitting) return;
    state = state.copyWith(
      isNewRequestOpen: false,
      description: '',
      attachedPhotoCount: 0,
      attachedPhotoPath: () => null,
      isSubmitting: false,
      newlyCreatedTicket: () => null,
      submitError: () => null,
    );
  }

  void selectCategory(RepairCategory category) {
    if (state.selectedCategory == category) return;
    state = state.copyWith(selectedCategory: () => category);
  }

  void updateDescription(String text) {
    state = state.copyWith(description: text);
  }

  void attachPhoto(String filePath) {
    state = state.copyWith(
      attachedPhotoPath: () => filePath,
      attachedPhotoCount: 1,
    );
  }

  void removePhoto() {
    state = state.copyWith(
      attachedPhotoPath: () => null,
      attachedPhotoCount: 0,
    );
  }

  void togglePhotoAttachment() {
    if (state.hasPhoto) {
      removePhoto();
    } else {
      state = state.copyWith(attachedPhotoCount: 1);
    }
  }

  Future<void> pickPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (picked != null) {
        attachPhoto(picked.path);
      }
    } catch (_) {
      // Permission denied or picker cancelled
    }
  }

  /// Saves the request; the confirmation shows only once it is stored.
  Future<void> submitRequest() async {
    if (state.description.trim().isEmpty || state.isSubmitting) return;

    state = state.copyWith(isSubmitting: true, submitError: () => null);

    final category = state.selectedCategory ?? RepairCategory.plumbing;
    final text = state.description.trim();
    final title = text.length > 50 ? '${text.substring(0, 47)}...' : text;
    final hasPhoto = state.hasPhoto;
    final photoPath = state.attachedPhotoPath;

    final RepairTicket newTicket;
    if (ref.read(liveDataProvider)) {
      final account = ref.read(tenantAccountProvider);
      try {
        final record = await ref
            .read(supabaseBillingRepositoryProvider)
            .submitRepairTicket(
              companyId: account.company.id,
              tenancyId: account.tenancy.id,
              unitId: account.unit.id,
              category: category.name,
              title: title,
              description: text,
              hasPhoto: hasPhoto,
            );
        newTicket = repairTicketFromRecord(record);

        if (photoPath != null) {
          try {
            final file = File(photoPath);
            if (await file.exists()) {
              final bytes = await file.readAsBytes();
              final ext = photoPath.contains('.')
                  ? photoPath.split('.').last
                  : 'jpg';
              final storagePath =
                  '${account.company.id}/${account.tenancy.id}/${record.id}.$ext';
              await Supabase.instance.client.storage
                  .from('repair-photos')
                  .uploadBinary(storagePath, bytes);
              await Supabase.instance.client.rpc(
                'set_repair_ticket_photo',
                params: {'p_ticket_id': record.id, 'p_path': storagePath},
              );
            }
          } catch (_) {
            // Upload failure doesn't block ticket creation
          }
        }
      } catch (_) {
        if (!ref.mounted) return;
        state = state.copyWith(
          isSubmitting: false,
          submitError: () =>
              'Couldn\'t send your request. Check your connection and try again.',
        );
        return;
      }
      if (!ref.mounted) return;
    } else {
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      if (!ref.mounted) return;
      // Continues the portfolio-wide MT- sequence the admin board uses.
      newTicket = RepairTicket(
        id: 'MT-$_nextDemoTicketNumber',
        category: category,
        title: title,
        subtitle: 'Submitted today · Open',
        status: RepairStatus.open,
        hasPhoto: hasPhoto,
      );
      _raised++;
    }

    state = state.copyWith(
      tickets: [newTicket, ...state.tickets.where((t) => t.id != newTicket.id)],
      isNewRequestOpen: false,
      isSubmitting: false,
      description: '',
      attachedPhotoCount: 0,
      newlyCreatedTicket: () => newTicket,
    );
    if (ref.read(liveDataProvider)) {
      await ref.read(tenantAccountProvider.notifier).refreshFromDatabase();
    }
  }

  void dismissNewlyCreatedTicketFeedback() {
    state = state.copyWith(newlyCreatedTicket: () => null);
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    RepairStatus.inProgress =>
      'In progress${record.assignedTo == null ? '' : ' · ${record.assignedTo}'}',
    RepairStatus.open => 'Submitted $created · Open',
  };
  return RepairTicket(
    id: record.id,
    category: RepairCategory.fromWire(record.category),
    title: record.title,
    subtitle: subtitle,
    status: status,
    priority: RepairPriority.fromWire(record.priority),
    hasPhoto: record.hasPhoto,
  );
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

  void togglePhotoAttachment() {
    final nextCount = state.attachedPhotoCount > 0 ? 0 : 1;
    state = state.copyWith(attachedPhotoCount: nextCount);
  }

  /// Saves the request; the confirmation shows only once it is stored.
  Future<void> submitRequest() async {
    if (state.description.trim().isEmpty || state.isSubmitting) return;

    state = state.copyWith(isSubmitting: true, submitError: () => null);

    final category = state.selectedCategory ?? RepairCategory.plumbing;
    final text = state.description.trim();
    final title = text.length > 50 ? '${text.substring(0, 47)}...' : text;
    final hasPhoto = state.attachedPhotoCount > 0;

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

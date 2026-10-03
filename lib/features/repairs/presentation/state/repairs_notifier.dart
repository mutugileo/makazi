import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/repair_ticket.dart';
import 'repairs_ui_state.dart';

class RepairsNotifier extends Notifier<RepairsUiState> {
  @override
  RepairsUiState build() {
    return const RepairsUiState.initial();
  }

  void openNewRequest() {
    state = state.copyWith(
      isNewRequestOpen: true,
      selectedCategory: () => RepairCategory.plumbing,
      description: '',
      attachedPhotoCount: 0,
      isSubmitting: false,
      newlyCreatedTicket: () => null,
    );
  }

  void closeNewRequest() {
    state = state.copyWith(
      isNewRequestOpen: false,
      description: '',
      attachedPhotoCount: 0,
      isSubmitting: false,
      newlyCreatedTicket: () => null,
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

  Future<void> submitRequest() async {
    if (state.description.trim().isEmpty || state.isSubmitting) return;

    state = state.copyWith(isSubmitting: true);

    await Future<void>.delayed(const Duration(milliseconds: 1200));

    final category = state.selectedCategory ?? RepairCategory.plumbing;
    final ticketNumber = 1040 + (state.tickets.length - 1);
    final ticketId = 'MT-$ticketNumber';

    final text = state.description.trim();
    final title = text.length > 50 ? '${text.substring(0, 47)}...' : text;

    final newTicket = RepairTicket(
      id: ticketId,
      category: category,
      title: title,
      subtitle: 'Submitted today · In review',
      status: RepairStatus.inReview,
      hasPhoto: state.attachedPhotoCount > 0,
    );

    state = state.copyWith(
      tickets: [newTicket, ...state.tickets],
      isNewRequestOpen: false,
      isSubmitting: false,
      description: '',
      attachedPhotoCount: 0,
      newlyCreatedTicket: () => newTicket,
    );
  }

  void dismissNewlyCreatedTicketFeedback() {
    state = state.copyWith(newlyCreatedTicket: () => null);
  }
}

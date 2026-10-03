import 'package:flutter/foundation.dart';
import '../../domain/models/repair_ticket.dart';

@immutable
class RepairsUiState {
  const RepairsUiState({
    required this.tickets,
    this.isNewRequestOpen = false,
    this.selectedCategory = RepairCategory.plumbing,
    this.description = '',
    this.attachedPhotoCount = 0,
    this.isSubmitting = false,
    this.newlyCreatedTicket,
  });

  const RepairsUiState.initial()
    : tickets = const [
        RepairTicket(
          id: 'MT-1039',
          category: RepairCategory.electrical,
          title: 'Socket in bedroom sparks',
          subtitle: 'Fixed by Otieno Fundi Services, 24 Sep',
          status: RepairStatus.resolved,
        ),
      ],
      isNewRequestOpen = false,
      selectedCategory = RepairCategory.plumbing,
      description = '',
      attachedPhotoCount = 0,
      isSubmitting = false,
      newlyCreatedTicket = null;

  final List<RepairTicket> tickets;
  final bool isNewRequestOpen;
  final RepairCategory? selectedCategory;
  final String description;
  final int attachedPhotoCount;
  final bool isSubmitting;
  final RepairTicket? newlyCreatedTicket;

  bool get canSubmit =>
      selectedCategory != null &&
      description.trim().isNotEmpty &&
      !isSubmitting;

  RepairsUiState copyWith({
    List<RepairTicket>? tickets,
    bool? isNewRequestOpen,
    ValueGetter<RepairCategory?>? selectedCategory,
    String? description,
    int? attachedPhotoCount,
    bool? isSubmitting,
    ValueGetter<RepairTicket?>? newlyCreatedTicket,
  }) {
    return RepairsUiState(
      tickets: tickets ?? this.tickets,
      isNewRequestOpen: isNewRequestOpen ?? this.isNewRequestOpen,
      selectedCategory: selectedCategory != null
          ? selectedCategory()
          : this.selectedCategory,
      description: description ?? this.description,
      attachedPhotoCount: attachedPhotoCount ?? this.attachedPhotoCount,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      newlyCreatedTicket: newlyCreatedTicket != null
          ? newlyCreatedTicket()
          : this.newlyCreatedTicket,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RepairsUiState &&
        listEquals(other.tickets, tickets) &&
        other.isNewRequestOpen == isNewRequestOpen &&
        other.selectedCategory == selectedCategory &&
        other.description == description &&
        other.attachedPhotoCount == attachedPhotoCount &&
        other.isSubmitting == isSubmitting &&
        other.newlyCreatedTicket == newlyCreatedTicket;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(tickets),
    isNewRequestOpen,
    selectedCategory,
    description,
    attachedPhotoCount,
    isSubmitting,
    newlyCreatedTicket,
  );
}

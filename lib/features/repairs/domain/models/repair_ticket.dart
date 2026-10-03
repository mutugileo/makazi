import 'package:flutter/foundation.dart';

enum RepairCategory {
  plumbing('Plumbing'),
  electrical('Electrical'),
  carpentry('Carpentry'),
  appliance('Appliance'),
  security('Security');

  const RepairCategory(this.label);
  final String label;
}

enum RepairStatus {
  resolved('Resolved'),
  inReview('In review'),
  inProgress('In progress');

  const RepairStatus(this.label);
  final String label;
}

@immutable
class RepairTicket {
  const RepairTicket({
    required this.id,
    required this.category,
    required this.title,
    required this.subtitle,
    required this.status,
    this.hasPhoto = false,
  });

  final String id;
  final RepairCategory category;
  final String title;
  final String subtitle;
  final RepairStatus status;
  final bool hasPhoto;

  RepairTicket copyWith({
    String? id,
    RepairCategory? category,
    String? title,
    String? subtitle,
    RepairStatus? status,
    bool? hasPhoto,
  }) {
    return RepairTicket(
      id: id ?? this.id,
      category: category ?? this.category,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      status: status ?? this.status,
      hasPhoto: hasPhoto ?? this.hasPhoto,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RepairTicket &&
        other.id == id &&
        other.category == category &&
        other.title == title &&
        other.subtitle == subtitle &&
        other.status == status &&
        other.hasPhoto == hasPhoto;
  }

  @override
  int get hashCode =>
      Object.hash(id, category, title, subtitle, status, hasPhoto);
}

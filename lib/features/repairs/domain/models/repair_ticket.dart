import 'package:flutter/foundation.dart';

// Category, status and priority lists are shared with the admin
// (REPAIR_* in PropAdmin/src/lib/billing.ts). `wire` is the stored value.

enum RepairCategory {
  plumbing('plumbing', 'Plumbing'),
  electrical('electrical', 'Electrical'),
  carpentry('carpentry', 'Carpentry'),
  appliance('appliance', 'Appliance'),
  security('security', 'Security & access');

  const RepairCategory(this.wire, this.label);
  final String wire;
  final String label;

  static RepairCategory fromWire(String value) =>
      values.firstWhere((c) => c.wire == value);
}

// Same three columns as the admin's maintenance board.
enum RepairStatus {
  open('open', 'Open'),
  inProgress('in_progress', 'In progress'),
  resolved('resolved', 'Resolved');

  const RepairStatus(this.wire, this.label);
  final String wire;
  final String label;

  static RepairStatus fromWire(String value) =>
      values.firstWhere((s) => s.wire == value);
}

/// Set by staff when triaging. Tenants don't choose it; new requests start
/// at medium.
enum RepairPriority {
  low('low', 'Low'),
  medium('medium', 'Medium'),
  high('high', 'High');

  const RepairPriority(this.wire, this.label);
  final String wire;
  final String label;

  static RepairPriority fromWire(String value) =>
      values.firstWhere((p) => p.wire == value);
}

@immutable
class RepairTicket {
  const RepairTicket({
    required this.id,
    required this.category,
    required this.title,
    required this.subtitle,
    required this.status,
    this.priority = RepairPriority.medium,
    this.hasPhoto = false,
  });

  final String id;
  final RepairCategory category;
  final String title;
  final String subtitle;
  final RepairStatus status;
  final RepairPriority priority;
  final bool hasPhoto;

  RepairTicket copyWith({
    String? id,
    RepairCategory? category,
    String? title,
    String? subtitle,
    RepairStatus? status,
    RepairPriority? priority,
    bool? hasPhoto,
  }) {
    return RepairTicket(
      id: id ?? this.id,
      category: category ?? this.category,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      status: status ?? this.status,
      priority: priority ?? this.priority,
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
        other.priority == priority &&
        other.hasPhoto == hasPhoto;
  }

  @override
  int get hashCode =>
      Object.hash(id, category, title, subtitle, status, priority, hasPhoto);
}

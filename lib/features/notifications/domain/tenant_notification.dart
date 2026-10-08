import 'package:flutter/foundation.dart';

/// Something staff sent to this tenant's app, e.g. a payment reminder.
@immutable
class TenantNotification {
  const TenantNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.createdAt,
    this.readAt,
  });

  final String id;

  /// 'payment_reminder' for now.
  final String kind;
  final String title;
  final String body;

  /// ISO date-time with Nairobi offset.
  final String createdAt;
  final String? readAt;

  bool get isUnread => readAt == null;
  bool get isPaymentReminder => kind == 'payment_reminder';

  @override
  bool operator ==(Object other) =>
      other is TenantNotification &&
      other.id == id &&
      other.readAt == readAt &&
      other.title == title &&
      other.body == body;

  @override
  int get hashCode => Object.hash(id, readAt, title, body);
}

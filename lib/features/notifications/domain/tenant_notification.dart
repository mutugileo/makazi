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
  bool get isPinReset =>
      kind == 'pin_reset' ||
      title.toLowerCase().contains('pin') ||
      body.toLowerCase().contains('pin');
  bool get isPaymentReminder => kind == 'payment_reminder' && !isPinReset;

  DateTime? get createdDateTime => DateTime.tryParse(createdAt);

  DateTime? get pinExpiresAt {
    if (!isPinReset) return null;
    final created = createdDateTime;
    return created?.add(const Duration(hours: 72));
  }

  bool get isPinExpired {
    final exp = pinExpiresAt;
    if (exp == null) return false;
    return DateTime.now().isAfter(exp);
  }

  String? get pinValidityLabel {
    if (!isPinReset) return null;
    final exp = pinExpiresAt;
    if (exp == null) return 'Valid for 72 hours';
    final remaining = exp.difference(DateTime.now());
    if (remaining.isNegative) return 'Expired';
    if (remaining.inHours < 1) {
      return 'Expires in ${remaining.inMinutes}m';
    }
    if (remaining.inHours < 24) {
      return 'Expires in ${remaining.inHours}h';
    }
    final days = remaining.inDays;
    final hours = remaining.inHours % 24;
    return hours > 0 ? 'Expires in ${days}d ${hours}h' : 'Expires in ${days}d';
  }

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

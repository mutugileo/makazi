import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/billing/billing_engine.dart';
import '../../../../core/billing/billing_models.dart';
import '../../../../core/data/data_mode.dart';
import '../../../../core/data/supabase_billing_providers.dart';
import '../../../billing/presentation/state/tenant_account_providers.dart';
import '../../domain/models/chat_message.dart';

/// 'Today, 09:12', 'Yesterday', otherwise '5 Oct', as in the admin.
String chatTimestamp(String sentAt, String today) {
  final date = sentAt.substring(0, 10);
  if (date == today) return 'Today, ${sentAt.substring(11, 16)}';
  if (BillingDates.daysBetween(date, today) == 1) return 'Yesterday';
  return BillingDates.formatDayMonth(date);
}

ChatMessage chatMessageFromRecord(MessageRecord record, String today) {
  return ChatMessage(
    id: record.id,
    text: record.body,
    isUserMessage: record.sender == 'tenant',
    timestamp: chatTimestamp(record.sentAt, today),
  );
}

class ManagerTypingNotifier extends Notifier<bool> {
  Timer? _timer;

  @override
  bool build() {
    ref.onDispose(() => _timer?.cancel());
    return false;
  }

  void showTyping([Duration duration = const Duration(seconds: 4)]) {
    _timer?.cancel();
    state = true;
    _timer = Timer(duration, () {
      if (ref.mounted) {
        state = false;
      }
    });
  }

  void hideTyping() {
    _timer?.cancel();
    state = false;
  }
}

final managerTypingProvider = NotifierProvider<ManagerTypingNotifier, bool>(
  ManagerTypingNotifier.new,
);

class MessagesNotifier extends Notifier<List<ChatMessage>> {
  /// Messages written on this phone that the conversation from the database
  /// doesn't include yet: sending, failed, or (demo) kept locally.
  final List<ChatMessage> _outbox = [];

  @override
  List<ChatMessage> build() {
    final seed = ref.watch(tenantAccountProvider).seed;
    final records = [...seed.messages]
      ..sort((a, b) => a.sentAt.compareTo(b.sentAt));
    final stored = {for (final m in records) m.id};
    _outbox.removeWhere((m) => stored.contains(m.id));
    return [
      for (final m in records) chatMessageFromRecord(m, seed.asOf),
      ..._outbox,
    ];
  }

  void _publish() {
    final seed = ref.read(tenantAccountProvider).seed;
    final records = [...seed.messages]
      ..sort((a, b) => a.sentAt.compareTo(b.sentAt));
    state = [
      for (final m in records) chatMessageFromRecord(m, seed.asOf),
      ..._outbox,
    ];
  }

  /// Shows the message straight away; in the live app it reads "Sending…"
  /// until the database has it, and "Not sent" (tap to retry) if it failed.
  Future<void> dispatchUserMessage(String content) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return;
    final live = ref.read(liveDataProvider);
    final message = ChatMessage(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      text: trimmed,
      isUserMessage: true,
      timestamp: 'Just now',
      delivery: live ? MessageDelivery.sending : MessageDelivery.sent,
    );
    _outbox.add(message);
    _publish();
    if (live) await _deliver(message.id);
  }

  Future<void> retry(String localId) async {
    final i = _outbox.indexWhere((m) => m.id == localId);
    if (i < 0 || _outbox[i].delivery != MessageDelivery.failed) return;
    _outbox[i] = _outbox[i].copyWith(delivery: MessageDelivery.sending);
    _publish();
    await _deliver(localId);
  }

  Future<void> _deliver(String localId) async {
    final account = ref.read(tenantAccountProvider);
    final text = _outbox.firstWhere((m) => m.id == localId).text;
    try {
      final record = await ref
          .read(supabaseBillingRepositoryProvider)
          .sendMessage(
            companyId: account.company.id,
            tenancyId: account.tenancy.id,
            body: text,
          );
      if (!ref.mounted) return;
      final i = _outbox.indexWhere((m) => m.id == localId);
      if (i >= 0) {
        // Keeps its place until the refreshed conversation includes it.
        _outbox[i] = _outbox[i].copyWith(
          id: record.id,
          timestamp: chatTimestamp(record.sentAt, account.seed.asOf),
          delivery: MessageDelivery.sent,
        );
      }
      _publish();
      await ref.read(tenantAccountProvider.notifier).refreshFromDatabase();
    } catch (_) {
      if (!ref.mounted) return;
      final i = _outbox.indexWhere((m) => m.id == localId);
      if (i >= 0) {
        _outbox[i] = _outbox[i].copyWith(delivery: MessageDelivery.failed);
      }
      _publish();
    }
  }
}

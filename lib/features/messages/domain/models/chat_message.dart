import 'package:flutter/foundation.dart';

/// Where a message the tenant wrote is on its way to the manager.
enum MessageDelivery { sent, sending, failed }

@immutable
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUserMessage,
    required this.timestamp,
    this.delivery = MessageDelivery.sent,
  });

  final String id;
  final String text;
  final bool isUserMessage;
  final String timestamp;
  final MessageDelivery delivery;

  ChatMessage copyWith({
    String? id,
    String? timestamp,
    MessageDelivery? delivery,
  }) => ChatMessage(
    id: id ?? this.id,
    text: text,
    isUserMessage: isUserMessage,
    timestamp: timestamp ?? this.timestamp,
    delivery: delivery ?? this.delivery,
  );
}

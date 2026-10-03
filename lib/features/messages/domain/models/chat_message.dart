import 'package:flutter/foundation.dart';

@immutable
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUserMessage,
    required this.timestamp,
  });

  final String id;
  final String text;
  final bool isUserMessage;
  final String timestamp;
}

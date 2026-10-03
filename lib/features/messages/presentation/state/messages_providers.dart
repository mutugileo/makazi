import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/chat_message.dart';
import 'messages_notifier.dart';

final messagesProvider = NotifierProvider<MessagesNotifier, List<ChatMessage>>(
  MessagesNotifier.new,
);

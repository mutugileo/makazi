import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/chat_message.dart';

class MessagesNotifier extends Notifier<List<ChatMessage>> {
  @override
  List<ChatMessage> build() {
    return const [
      ChatMessage(
        id: 'msg-1',
        text:
            'I sent the renewal back with a question about the 5% increase. Can we discuss?',
        isUserMessage: true,
        timestamp: 'Yesterday',
      ),
      ChatMessage(
        id: 'msg-2',
        text:
            'Hi David, the increase matches the market review for Riverside Court. Happy to keep the deposit as is so nothing extra is due.',
        isUserMessage: false,
        timestamp: '09:12',
      ),
    ];
  }

  void dispatchUserMessage(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final newMessage = ChatMessage(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
      text: trimmed,
      isUserMessage: true,
      timestamp: 'Just now',
    );
    state = [...state, newMessage];
  }
}

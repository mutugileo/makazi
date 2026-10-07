import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prop_mgt_app/features/messages/presentation/state/messages_providers.dart';

void main() {
  group('MessagesNotifier', () {
    test('initial state contains initial conversation messages', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final messages = container.read(messagesProvider);

      expect(messages.length, 2);
      expect(messages.first.isUserMessage, isTrue);
      expect(messages.first.timestamp, 'Yesterday');
      expect(messages.last.isUserMessage, isFalse);
      expect(messages.last.timestamp, 'Today, 09:12');
    });

    test('dispatchUserMessage appends trimmed message to list', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(messagesProvider.notifier)
          .dispatchUserMessage('Sounds good, thank you.');

      final messages = container.read(messagesProvider);
      expect(messages.length, 3);
      expect(messages.last.text, 'Sounds good, thank you.');
      expect(messages.last.isUserMessage, isTrue);
    });

    test('dispatchUserMessage ignores empty or whitespace content', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(messagesProvider.notifier).dispatchUserMessage('   ');

      final messages = container.read(messagesProvider);
      expect(messages.length, 2);
    });
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prop_mgt_app/features/repairs/domain/models/repair_ticket.dart';
import 'package:prop_mgt_app/features/repairs/presentation/state/repairs_providers.dart';

void main() {
  group('RepairsNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test(
      'initial state contains initial ticket and isNewRequestOpen is false',
      () {
        final state = container.read(repairsProvider);
        expect(state.tickets.length, 1);
        expect(state.tickets.first.id, 'MT-1039');
        expect(state.isNewRequestOpen, isFalse);
        expect(state.selectedCategory, RepairCategory.plumbing);
        expect(state.description, isEmpty);
        expect(state.attachedPhotoCount, 0);
        expect(state.isSubmitting, isFalse);
      },
    );

    test('openNewRequest and closeNewRequest toggle isNewRequestOpen', () {
      final notifier = container.read(repairsProvider.notifier);

      notifier.openNewRequest();
      expect(container.read(repairsProvider).isNewRequestOpen, isTrue);

      notifier.closeNewRequest();
      expect(container.read(repairsProvider).isNewRequestOpen, isFalse);
    });

    test('selectCategory updates selected category', () {
      final notifier = container.read(repairsProvider.notifier);
      notifier.selectCategory(RepairCategory.electrical);
      expect(
        container.read(repairsProvider).selectedCategory,
        RepairCategory.electrical,
      );
    });

    test('updateDescription and togglePhotoAttachment update state', () {
      final notifier = container.read(repairsProvider.notifier);

      notifier.updateDescription('Kitchen sink is leaking water');
      expect(
        container.read(repairsProvider).description,
        'Kitchen sink is leaking water',
      );

      notifier.togglePhotoAttachment();
      expect(container.read(repairsProvider).attachedPhotoCount, 1);

      notifier.togglePhotoAttachment();
      expect(container.read(repairsProvider).attachedPhotoCount, 0);
    });

    test('submitRequest prepends new ticket and closes request form', () async {
      final notifier = container.read(repairsProvider.notifier);
      notifier.openNewRequest();
      notifier.selectCategory(RepairCategory.carpentry);
      notifier.updateDescription('Door hinge is broken and squeaking loudly');
      notifier.togglePhotoAttachment();

      final future = notifier.submitRequest();
      expect(container.read(repairsProvider).isSubmitting, isTrue);

      await future;

      final updatedState = container.read(repairsProvider);
      expect(updatedState.isSubmitting, isFalse);
      expect(updatedState.isNewRequestOpen, isFalse);
      expect(updatedState.tickets.length, 2);
      expect(updatedState.tickets.first.id, 'MT-1048');
      expect(updatedState.tickets.first.category, RepairCategory.carpentry);
      expect(updatedState.tickets.first.status, RepairStatus.open);
      expect(updatedState.tickets.first.hasPhoto, isTrue);
      expect(updatedState.newlyCreatedTicket, isNotNull);
    });
  });
}

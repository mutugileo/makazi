import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prop_mgt_app/features/root/domain/models/root_navigation_destination.dart';
import 'package:prop_mgt_app/features/root/presentation/state/root_navigation_providers.dart';

void main() {
  group('RootNavigationNotifier', () {
    test(
      'initial state defaults to dashboard destination and compact layout',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final state = container.read(rootNavigationProvider);

        expect(state.selectedDestination, RootNavigationDestination.dashboard);
        expect(state.isCompactLayout, isTrue);
      },
    );

    test(
      'selectNavigationDestination updates state when new destination selected',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        container
            .read(rootNavigationProvider.notifier)
            .selectNavigationDestination(RootNavigationDestination.properties);

        final updatedState = container.read(rootNavigationProvider);
        expect(
          updatedState.selectedDestination,
          RootNavigationDestination.properties,
        );
      },
    );

    test(
      'selectNavigationDestination does not emit identical duplicate state',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final initialState = container.read(rootNavigationProvider);

        container
            .read(rootNavigationProvider.notifier)
            .selectNavigationDestination(RootNavigationDestination.dashboard);

        final subsequentState = container.read(rootNavigationProvider);
        expect(identical(initialState, subsequentState), isTrue);
      },
    );

    test('updateScreenLayoutMode updates layout flag', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(rootNavigationProvider.notifier)
          .updateScreenLayoutMode(isCompact: false);

      final updatedState = container.read(rootNavigationProvider);
      expect(updatedState.isCompactLayout, isFalse);
    });
  });
}

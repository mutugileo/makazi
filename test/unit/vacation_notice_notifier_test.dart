import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prop_mgt_app/features/vacation_notice/presentation/state/vacation_notice_providers.dart';

void main() {
  group('VacationNoticeNotifier', () {
    test(
      'initial state has default 30-day notice and 2-day prior inspection',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final state = container.read(vacationNoticeProvider);
        expect(state.hasActiveNotice, isFalse);
        expect(state.vacatingDate, isNotNull);
        expect(state.inspectionDate, isNotNull);
        expect(state.inspectionDate!.isBefore(state.vacatingDate!), isTrue);
        expect(state.selectedReason, 'Relocation / Job Transfer');
        expect(state.inspectionTimeSlot, 'Morning (9:00 AM – 12:00 PM)');
      },
    );

    test(
      'updating vacating date moves inspection date if it exceeds vacating date',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(vacationNoticeProvider.notifier);
        final newVacating = DateTime.now().add(const Duration(days: 14));
        notifier.updateVacatingDate(newVacating);

        final state = container.read(vacationNoticeProvider);
        expect(state.vacatingDate, newVacating);
        expect(state.inspectionDate!.isAfter(newVacating), isFalse);
      },
    );

    test('selecting reason, inspection slot and notes updates state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(vacationNoticeProvider.notifier);
      notifier.selectReason('Moving to Own Home');
      notifier.selectInspectionTimeSlot('Afternoon (2:00 PM – 5:00 PM)');
      notifier.updateReasonDetails('Bought a house in Kitengela');
      notifier.updateDepositRefundPhone('+254712345678');

      final state = container.read(vacationNoticeProvider);
      expect(state.selectedReason, 'Moving to Own Home');
      expect(state.inspectionTimeSlot, 'Afternoon (2:00 PM – 5:00 PM)');
      expect(state.reasonDetails, 'Bought a house in Kitengela');
      expect(state.depositRefundPhone, '+254712345678');
    });

    test(
      'validation: inspection date after vacating date rejects submission',
      () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(vacationNoticeProvider.notifier);
        final vacating = DateTime.now().add(const Duration(days: 10));
        final inspection = DateTime.now().add(const Duration(days: 15));

        notifier.updateVacatingDate(vacating);
        notifier.updateInspectionDate(inspection);

        final success = await notifier.submitNotice();
        expect(success, isFalse);
        expect(
          container.read(vacationNoticeProvider).submitError,
          contains('Inspection date must be on or before'),
        );
        expect(container.read(vacationNoticeProvider).hasActiveNotice, isFalse);
      },
    );

    test('submitNotice creates active notice and marks isSuccess', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(vacationNoticeProvider.notifier);
      final vacating = DateTime.now().add(const Duration(days: 35));
      final inspection = DateTime.now().add(const Duration(days: 33));

      notifier.updateVacatingDate(vacating);
      notifier.updateInspectionDate(inspection);
      notifier.selectReason('Downsizing');

      final success = await notifier.submitNotice();
      expect(success, isTrue);

      final state = container.read(vacationNoticeProvider);
      expect(state.hasActiveNotice, isTrue);
      expect(state.isSuccess, isTrue);
      expect(state.activeNotice!.reason, 'Downsizing');
      expect(state.activeNotice!.status.label, 'Submitted');
    });

    test('withdrawNotice cancels active notice', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(vacationNoticeProvider.notifier);
      await notifier.submitNotice();
      expect(container.read(vacationNoticeProvider).hasActiveNotice, isTrue);

      notifier.withdrawNotice();
      expect(container.read(vacationNoticeProvider).hasActiveNotice, isFalse);
    });
  });
}

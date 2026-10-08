import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prop_mgt_app/core/widgets/empty_state.dart';

void main() {
  testWidgets('an empty-state card spans its parent, like one with rows', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  key: ValueKey('card'),
                  decoration: BoxDecoration(color: Colors.white),
                  child: Column(
                    children: [
                      EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'No payments yet',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byKey(const ValueKey('card'))).width, 360);
  });
}

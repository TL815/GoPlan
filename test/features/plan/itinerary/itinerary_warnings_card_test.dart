import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goplan/domain/itinerary/itinerary_warning.dart';
import 'package:goplan/features/plan/itinerary/itinerary_warnings_card.dart';

void main() {
  testWidgets('shows severities, labels, day index and dedupes', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ItineraryWarningsCard(
            warnings: [
              ItineraryWarning(
                id: 'w1',
                type: 'transport',
                message: '换乘较紧',
                severity: 'high',
                dayIndex: 1,
                itemId: 'secret_item',
              ),
              ItineraryWarning(
                id: 'w1',
                type: 'transport',
                message: '换乘较紧',
                severity: 'high',
                dayIndex: 1,
              ),
              ItineraryWarning(
                id: '',
                type: 'budget',
                message: '预算偏高',
                severity: 'medium',
              ),
              ItineraryWarning(
                id: '',
                type: 'unknown',
                message: '普通提示',
                severity: 'mystery',
              ),
              ItineraryWarning(id: 'empty', type: 'weather', message: ''),
            ],
          ),
        ),
      ),
    );

    expect(find.text('换乘较紧'), findsOneWidget);
    expect(find.text('预算偏高'), findsOneWidget);
    expect(find.text('普通提示'), findsOneWidget);
    expect(find.textContaining('高风险'), findsOneWidget);
    expect(find.textContaining('中风险'), findsOneWidget);
    expect(find.textContaining('第 1 天'), findsOneWidget);
    expect(find.textContaining('secret_item'), findsNothing);
    expect(find.textContaining('w1'), findsNothing);
  });
}

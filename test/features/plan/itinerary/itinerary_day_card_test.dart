import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goplan/domain/itinerary/itinerary_day.dart';
import 'package:goplan/domain/itinerary/itinerary_item.dart';
import 'package:goplan/features/plan/itinerary/itinerary_day_card.dart';

void main() {
  Future<void> pump(WidgetTester tester, ItineraryDay day) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ItineraryDayCard(day: day, position: 0)),
      ),
    );
  }

  testWidgets('shows day index date title summary cost warnings and items', (
    tester,
  ) async {
    await pump(
      tester,
      ItineraryDay(
        dayIndex: 1,
        date: DateTime(2026, 8, 3),
        title: '抵达杭州',
        summary: '轻松开始',
        estimatedCost: 300,
        warnings: const ['注意防晒'],
        items: [ItineraryItem(id: 'i', title: '西湖')],
      ),
    );

    expect(find.text('第 1 天'), findsWidgets);
    expect(find.text('2026年8月3日'), findsOneWidget);
    expect(find.text('抵达杭州'), findsOneWidget);
    expect(find.text('轻松开始'), findsOneWidget);
    expect(find.text('300'), findsOneWidget);
    expect(find.text('注意防晒'), findsOneWidget);
    expect(find.text('西湖'), findsOneWidget);
  });

  testWidgets('falls back safely for illegal day index and empty items', (
    tester,
  ) async {
    await pump(tester, ItineraryDay(dayIndex: -1, title: '', items: const []));

    expect(find.text('第 1 天'), findsWidgets);
    expect(find.text('当天安排暂未生成'), findsOneWidget);
  });
}

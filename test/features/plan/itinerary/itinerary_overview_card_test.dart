import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goplan/features/plan/itinerary/itinerary_overview_card.dart';

import 'itinerary_test_data.dart';

void main() {
  Future<void> pump(WidgetTester tester, {required Widget child}) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
  }

  testWidgets('shows summary fields, limits days, hides ids and coordinates', (
    tester,
  ) async {
    await pump(
      tester,
      child: ItineraryOverviewCard(
        itinerary: sampleItinerary(days: 5),
        onOpenDetails: () {},
      ),
    );

    expect(find.text('杭州周末'), findsOneWidget);
    expect(find.text('杭州'), findsOneWidget);
    expect(find.text('5天'), findsOneWidget);
    expect(find.text('草案'), findsOneWidget);
    expect(find.text('¥1200'), findsOneWidget);
    expect(find.text('1 条提示'), findsOneWidget);
    expect(find.textContaining('第 1 天'), findsOneWidget);
    expect(find.textContaining('第 3 天'), findsOneWidget);
    expect(find.textContaining('第 4 天'), findsNothing);
    expect(find.text('还有 2 天'), findsOneWidget);
    expect(find.text('查看完整行程'), findsOneWidget);
    expect(find.textContaining('secret'), findsNothing);
    expect(find.textContaining('30.249'), findsNothing);
  });

  testWidgets('opens details and shows empty state', (tester) async {
    var tapped = false;
    await pump(
      tester,
      child: ItineraryOverviewCard(
        itinerary: emptyItinerary(),
        onOpenDetails: () => tapped = true,
      ),
    );

    expect(find.text('旅行计划'), findsOneWidget);
    expect(find.text('行程内容还在生成中'), findsOneWidget);
    await tester.tap(find.text('查看完整行程'));
    expect(tapped, isTrue);
  });

  testWidgets('hides disabled details button', (tester) async {
    await pump(
      tester,
      child: ItineraryOverviewCard(itinerary: sampleItinerary(days: 1)),
    );

    expect(find.text('查看完整行程'), findsNothing);
  });
}

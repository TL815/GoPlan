import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goplan/domain/itinerary/itinerary_warning.dart';
import 'package:goplan/features/plan/itinerary/itinerary_detail_page.dart';

import 'itinerary_test_data.dart';

void main() {
  testWidgets(
    'builds full itinerary with all days budget and deduped warnings',
    (tester) async {
      final itinerary = sampleItinerary(days: 4);
      await tester.pumpWidget(
        MaterialApp(
          home: ItineraryDetailPage(
            itinerary: itinerary,
            additionalWarnings: const [
              ItineraryWarning(
                id: 'warning_secret',
                type: 'weather',
                message: '下午可能有雨',
              ),
              ItineraryWarning(id: '', type: 'budget', message: '预算偏高'),
            ],
          ),
        ),
      );

      expect(find.text('杭州周末'), findsWidgets);
      expect(find.text('4天'), findsOneWidget);
      expect(find.text('草案'), findsOneWidget);
      expect(find.text('西湖第 1 天'), findsOneWidget);
      expect(find.text('下午可能有雨'), findsOneWidget);
      expect(find.text('预算偏高'), findsOneWidget);
      expect(find.textContaining('secret'), findsNothing);
      await tester.scrollUntilVisible(
        find.text('西湖第 4 天'),
        500,
        scrollable: find.byType(Scrollable),
      );
      expect(find.text('西湖第 4 天'), findsOneWidget);

      final originalWarningsLength = itinerary.warnings.length;
      expect(itinerary.warnings, hasLength(originalWarningsLength));
    },
  );

  testWidgets('shows safe empty state without a controller', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: ItineraryDetailPage(itinerary: emptyItinerary())),
    );

    expect(find.text('旅行计划'), findsWidgets);
    expect(find.text('行程内容还在生成中'), findsOneWidget);
  });
}

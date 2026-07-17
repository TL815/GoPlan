import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goplan/domain/itinerary/itinerary_item.dart';
import 'package:goplan/domain/itinerary/place.dart';
import 'package:goplan/features/plan/itinerary/itinerary_item_tile.dart';

void main() {
  Future<void> pump(WidgetTester tester, ItineraryItem item) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ItineraryItemTile(item: item, isLast: true)),
      ),
    );
  }

  testWidgets('shows timeline fields and hides internal place fields', (
    tester,
  ) async {
    await pump(
      tester,
      ItineraryItem(
        id: 'item_secret',
        startTime: '09:00',
        endTime: '11:30',
        title: '西湖漫步',
        description: '沿湖慢行',
        place: Place(
          id: 'place_secret',
          name: '西湖',
          latitude: 30.2,
          longitude: 120.1,
          category: '景点',
          address: '南山路',
          source: 'amap',
        ),
        transportMode: '步行',
        transportMinutes: 15,
        durationMinutes: 90,
        estimatedCost: 80,
        currency: 'CNY',
        tips: ['带伞'],
      ),
    );

    expect(find.text('09:00–11:30'), findsOneWidget);
    expect(find.text('西湖漫步'), findsOneWidget);
    expect(find.text('西湖'), findsOneWidget);
    expect(find.text('景点'), findsOneWidget);
    expect(find.text('南山路'), findsOneWidget);
    expect(find.text('步行'), findsOneWidget);
    expect(find.text('交通 15分钟'), findsOneWidget);
    expect(find.text('停留 1小时30分钟'), findsOneWidget);
    expect(find.text('¥80'), findsOneWidget);
    expect(find.text('• 带伞'), findsOneWidget);
    expect(find.textContaining('secret'), findsNothing);
    expect(find.textContaining('30.2'), findsNothing);
    expect(find.textContaining('amap'), findsNothing);
  });

  testWidgets('uses place name fallback and city fallback safely', (
    tester,
  ) async {
    await pump(
      tester,
      ItineraryItem(
        id: 'i',
        title: '',
        place: Place(id: 'p', name: '灵隐寺', city: '杭州'),
      ),
    );

    expect(find.text('时间待定'), findsOneWidget);
    expect(find.text('灵隐寺'), findsOneWidget);
    expect(find.text('杭州'), findsOneWidget);
  });

  testWidgets('handles activity without place', (tester) async {
    await pump(tester, ItineraryItem(id: 'i', title: '自由活动'));

    expect(find.text('自由活动'), findsOneWidget);
    expect(find.text('时间待定'), findsOneWidget);
  });
}

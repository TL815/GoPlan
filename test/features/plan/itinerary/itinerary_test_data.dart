import 'package:goplan/domain/itinerary/budget_summary.dart';
import 'package:goplan/domain/itinerary/itinerary.dart';
import 'package:goplan/domain/itinerary/itinerary_day.dart';
import 'package:goplan/domain/itinerary/itinerary_item.dart';
import 'package:goplan/domain/itinerary/itinerary_warning.dart';
import 'package:goplan/domain/itinerary/place.dart';

Itinerary sampleItinerary({int days = 4, bool isDraft = true}) {
  return Itinerary(
    id: 'itinerary_secret',
    tripId: 'trip_secret',
    title: '杭州周末',
    destination: '杭州',
    version: 3,
    isDraft: isDraft,
    budgetSummary: const BudgetSummary(
      total: 1200,
      perPerson: 600,
      transport: 200,
      accommodation: 500,
      food: 240,
      tickets: 100,
      other: 160,
      currency: 'CNY',
    ),
    warnings: const [
      ItineraryWarning(
        id: 'warning_secret',
        type: 'weather',
        message: '下午可能有雨',
        severity: 'warning',
        dayIndex: 2,
        itemId: 'item_secret',
      ),
    ],
    days: [
      for (var i = 1; i <= days; i++)
        ItineraryDay(
          dayIndex: i,
          date: DateTime(2026, 8, i),
          title: '西湖第 $i 天',
          summary: '轻松游览和咖啡休息',
          estimatedCost: 300,
          warnings: i == 1 ? const ['注意防晒'] : const [],
          items: [
            ItineraryItem(
              id: 'item_secret_$i',
              startTime: '09:00',
              endTime: '11:30',
              title: i == 1 ? '西湖漫步' : '活动 $i',
              description: '沿湖慢行，预留拍照时间。',
              place: Place(
                id: 'place_secret_$i',
                name: i == 1 ? '西湖' : '地点 $i',
                latitude: 30.249,
                longitude: 120.141,
                category: '景点',
                address: '西湖区南山路',
                city: '杭州',
                source: 'amap',
              ),
              transportMode: '步行',
              transportMinutes: 15,
              durationMinutes: 150,
              estimatedCost: 80,
              currency: 'CNY',
              tips: const ['早点出发', '带伞'],
            ),
          ],
        ),
    ],
  );
}

Itinerary emptyItinerary() {
  return Itinerary(title: '', destination: '', days: const []);
}

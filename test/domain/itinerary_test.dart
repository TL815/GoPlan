import 'package:flutter_test/flutter_test.dart';
import 'package:goplan/domain/itinerary/budget_summary.dart';
import 'package:goplan/domain/itinerary/itinerary.dart';
import 'package:goplan/domain/itinerary/itinerary_day.dart';
import 'package:goplan/domain/itinerary/itinerary_item.dart';
import 'package:goplan/domain/itinerary/place.dart';

void main() {
  test('Place parses latitude and longitude strings', () {
    final place = Place.fromJson({
      'id': 'p_1',
      'name': '青海湖',
      'latitude': '36.9869',
      'longitude': '99.9064',
      'source': 'amap',
    });

    expect(place.latitude, 36.9869);
    expect(place.longitude, 99.9064);
    expect(place.source, 'amap');
  });

  test('Itinerary draft allows null day date', () {
    final itinerary = Itinerary.fromJson({
      'title': '草案',
      'is_draft': true,
      'days': [
        {'day_index': 1, 'date': null, 'title': '第1天', 'items': []},
      ],
    });

    expect(itinerary.isDraft, isTrue);
    expect(itinerary.version, 1);
    expect(itinerary.days.single.date, isNull);
  });

  test('BudgetSummary parses numeric strings', () {
    final budget = BudgetSummary.fromJson({
      'total': '1200.5',
      'transport': '300',
      'per_person': '600.25',
    });

    expect(budget.total, 1200.5);
    expect(budget.transport, 300);
    expect(budget.perPerson, 600.25);
    expect(budget.currency, 'CNY');
  });

  test('days and items cannot be modified externally', () {
    final sourceItems = [
      ItineraryItem(id: 'i_1', title: '抵达', tips: ['带伞']),
    ];
    final day = ItineraryDay(dayIndex: 1, title: '第1天', items: sourceItems);
    final itinerary = Itinerary(title: '行程', days: [day]);

    sourceItems.add(ItineraryItem(id: 'i_2', title: '晚餐'));

    expect(day.items, hasLength(1));
    expect(itinerary.days, hasLength(1));
    expect(() => day.items.add(sourceItems.last), throwsUnsupportedError);
    expect(() => itinerary.days.add(day), throwsUnsupportedError);
    expect(() => day.items.first.tips.add('帽子'), throwsUnsupportedError);
  });

  test('copyWith preserves immutable lists', () {
    final item = ItineraryItem(id: 'i_1', title: '抵达');
    final day = ItineraryDay(dayIndex: 1, title: '第1天', items: [item]);
    final updatedDay = day.copyWith(title: '抵达日');
    final itinerary = Itinerary(title: '行程', days: [updatedDay]);
    final updatedItinerary = itinerary.copyWith(title: '新行程');

    expect(updatedDay.title, '抵达日');
    expect(updatedItinerary.title, '新行程');
    expect(() => updatedItinerary.days.add(updatedDay), throwsUnsupportedError);
  });
}

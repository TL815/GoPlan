import 'package:flutter_test/flutter_test.dart';
import 'package:goplan/domain/itinerary/budget_summary.dart';
import 'package:goplan/features/plan/itinerary/itinerary_formatters.dart';

void main() {
  test('formats complete and compact dates', () {
    final date = DateTime(2026, 8, 3);

    expect(ItineraryFormatters.formatDate(date), '2026年8月3日');
    expect(ItineraryFormatters.formatDate(date, includeYear: false), '8月3日');
  });

  test('formats time ranges and fallback', () {
    expect(
      ItineraryFormatters.formatTimeRange('09:00', '11:30'),
      '09:00–11:30',
    );
    expect(ItineraryFormatters.formatTimeRange('09:00', null), '09:00');
    expect(ItineraryFormatters.formatTimeRange(null, null), '时间待定');
  });

  test('formats durations', () {
    expect(ItineraryFormatters.formatDuration(45), '45分钟');
    expect(ItineraryFormatters.formatDuration(90), '1小时30分钟');
    expect(ItineraryFormatters.formatDuration(120), '2小时');
  });

  test('formats money without useless decimals and handles currencies', () {
    expect(ItineraryFormatters.formatMoney(120.0, currency: 'CNY'), '¥120');
    expect(ItineraryFormatters.formatMoney(120.5, currency: 'USD'), r'$120.5');
    expect(ItineraryFormatters.formatMoney(120, currency: 'EUR'), '€120');
    expect(ItineraryFormatters.formatMoney(120, currency: 'ABC'), 'ABC 120');
  });

  test('uses budget currency and plain number fallback', () {
    const budget = BudgetSummary(currency: 'JPY');

    expect(ItineraryFormatters.formatMoney(500, budget: budget), '¥500');
    expect(ItineraryFormatters.formatMoney(500), '500');
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:goplan/application/assistant/ui_action/date_range_selection.dart';

void main() {
  test('stores start and end and supports equality', () {
    final start = DateTime(2026, 8, 3, 10);
    final end = DateTime(2026, 8, 9, 18);

    expect(
      DateRangeSelection(start: start, end: end),
      DateRangeSelection(start: start, end: end),
    );
  });

  test('copyWith changes selected fields', () {
    final selection = DateRangeSelection(
      start: DateTime(2026, 8, 3),
      end: DateTime(2026, 8, 9),
    );

    final copied = selection.copyWith(end: DateTime(2026, 8, 10));

    expect(copied.start, selection.start);
    expect(copied.end, DateTime(2026, 8, 10));
  });

  test('durationDays uses natural date parts including same day', () {
    expect(
      DateRangeSelection(
        start: DateTime(2026, 8, 3, 23),
        end: DateTime(2026, 8, 3, 1),
      ).durationDays,
      1,
    );
    expect(
      DateRangeSelection(
        start: DateTime(2026, 8, 3),
        end: DateTime(2026, 8, 9),
      ).durationDays,
      7,
    );
  });

  test('does not swap reversed dates', () {
    final selection = DateRangeSelection(
      start: DateTime(2026, 8, 9),
      end: DateTime(2026, 8, 3),
    );

    expect(selection.start, DateTime(2026, 8, 9));
    expect(selection.end, DateTime(2026, 8, 3));
    expect(selection.durationDays, -5);
  });
}

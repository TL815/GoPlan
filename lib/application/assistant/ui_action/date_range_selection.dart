/// Pure Dart date range value returned by UI interaction adapters.
class DateRangeSelection {
  const DateRangeSelection({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  int get durationDays {
    final startDate = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);
    return endDate.difference(startDate).inDays + 1;
  }

  DateRangeSelection copyWith({DateTime? start, DateTime? end}) {
    return DateRangeSelection(start: start ?? this.start, end: end ?? this.end);
  }

  @override
  bool operator ==(Object other) {
    return other is DateRangeSelection &&
        other.start == start &&
        other.end == end;
  }

  @override
  int get hashCode => Object.hash(start, end);
}

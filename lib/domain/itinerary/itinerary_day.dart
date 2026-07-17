import 'itinerary_item.dart';

class ItineraryDay {
  ItineraryDay({
    required this.dayIndex,
    this.date,
    required this.title,
    this.summary,
    List<ItineraryItem> items = const [],
    this.estimatedCost,
    List<String> warnings = const [],
  }) : items = List.unmodifiable(items),
       warnings = List.unmodifiable(warnings);

  factory ItineraryDay.fromJson(Map<String, Object?> json) {
    return ItineraryDay(
      dayIndex: _parseInt(json['day_index']) ?? _parseInt(json['day']) ?? 0,
      date: _parseDate(json['date']),
      title: _stringValue(json['title']),
      summary: _nullableString(json['summary']),
      items: _parseItems(json['items']),
      estimatedCost: _parseNum(json['estimated_cost']),
      warnings: _stringList(json['warnings']),
    );
  }

  final int dayIndex;
  final DateTime? date;
  final String title;
  final String? summary;
  final List<ItineraryItem> items;
  final num? estimatedCost;
  final List<String> warnings;

  ItineraryDay copyWith({
    int? dayIndex,
    DateTime? date,
    String? title,
    String? summary,
    List<ItineraryItem>? items,
    num? estimatedCost,
    List<String>? warnings,
  }) {
    return ItineraryDay(
      dayIndex: dayIndex ?? this.dayIndex,
      date: date ?? this.date,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      items: items ?? this.items,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      warnings: warnings ?? this.warnings,
    );
  }

  Map<String, Object?> toJson() => {
    'day_index': dayIndex,
    if (date != null) 'date': _formatDate(date!),
    'title': title,
    if (summary != null) 'summary': summary,
    'items': items.map((item) => item.toJson()).toList(),
    if (estimatedCost != null) 'estimated_cost': estimatedCost,
    'warnings': List<String>.from(warnings),
  };

  static List<ItineraryItem> _parseItems(Object? value) {
    if (value is! Iterable) return const [];
    return value
        .whereType<Map>()
        .map(
          (item) => ItineraryItem.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList();
  }

  static DateTime? _parseDate(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  static int? _parseInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static num? _parseNum(Object? value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }

  static List<String> _stringList(Object? value) {
    if (value is! Iterable) return const [];
    return value.map((item) => item.toString()).toList();
  }

  static String _stringValue(Object? value) {
    if (value == null) return '';
    return value.toString();
  }

  static String? _nullableString(Object? value) {
    if (value == null) return null;
    return value.toString();
  }

  static String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}

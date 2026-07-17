import 'budget_summary.dart';
import 'itinerary_day.dart';
import 'itinerary_warning.dart';

class Itinerary {
  Itinerary({
    this.id,
    this.tripId,
    required this.title,
    this.destination,
    this.version = 1,
    this.isDraft = false,
    List<ItineraryDay> days = const [],
    this.budgetSummary,
    List<ItineraryWarning> warnings = const [],
  }) : days = List.unmodifiable(days),
       warnings = List.unmodifiable(warnings);

  factory Itinerary.fromJson(Map<String, Object?> json) {
    final daysValue = json['days'];
    if (daysValue != null && daysValue is! Iterable) {
      throw FormatException('Invalid itinerary.days: expected a list.');
    }

    return Itinerary(
      id: _nullableString(json['id']),
      tripId: _nullableString(json['trip_id']),
      title: _stringValue(json['title']),
      destination: _nullableString(json['destination']),
      version: _parseInt(json['version']) ?? 1,
      isDraft: json['is_draft'] == true,
      days: _parseDays(daysValue),
      budgetSummary: _parseBudgetSummary(json['budget_summary']),
      warnings: _parseWarnings(json['warnings']),
    );
  }

  final String? id;
  final String? tripId;
  final String title;
  final String? destination;
  final int? version;
  final bool isDraft;
  final List<ItineraryDay> days;
  final BudgetSummary? budgetSummary;
  final List<ItineraryWarning> warnings;

  Itinerary copyWith({
    String? id,
    String? tripId,
    String? title,
    String? destination,
    int? version,
    bool? isDraft,
    List<ItineraryDay>? days,
    BudgetSummary? budgetSummary,
    List<ItineraryWarning>? warnings,
  }) {
    return Itinerary(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      title: title ?? this.title,
      destination: destination ?? this.destination,
      version: version ?? this.version,
      isDraft: isDraft ?? this.isDraft,
      days: days ?? this.days,
      budgetSummary: budgetSummary ?? this.budgetSummary,
      warnings: warnings ?? this.warnings,
    );
  }

  Map<String, Object?> toJson() => {
    if (id != null) 'id': id,
    if (tripId != null) 'trip_id': tripId,
    'title': title,
    if (destination != null) 'destination': destination,
    'version': version ?? 1,
    'is_draft': isDraft,
    'days': days.map((day) => day.toJson()).toList(),
    if (budgetSummary != null) 'budget_summary': budgetSummary!.toJson(),
    'warnings': warnings.map((warning) => warning.toJson()).toList(),
  };

  static List<ItineraryDay> _parseDays(Object? value) {
    if (value == null) return const [];
    return (value as Iterable)
        .whereType<Map>()
        .map(
          (day) => ItineraryDay.fromJson(
            day.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList();
  }

  static BudgetSummary? _parseBudgetSummary(Object? value) {
    if (value is! Map) return null;
    return BudgetSummary.fromJson(
      value.map((key, value) => MapEntry(key.toString(), value)),
    );
  }

  static List<ItineraryWarning> _parseWarnings(Object? value) {
    if (value is! Iterable) return const [];
    return value
        .whereType<Map>()
        .map(
          (warning) => ItineraryWarning.fromJson(
            warning.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList();
  }

  static int? _parseInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static String _stringValue(Object? value) {
    if (value == null) return '';
    return value.toString();
  }

  static String? _nullableString(Object? value) {
    if (value == null) return null;
    return value.toString();
  }
}

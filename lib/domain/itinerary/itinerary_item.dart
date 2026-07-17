import 'place.dart';

class ItineraryItem {
  ItineraryItem({
    required this.id,
    this.startTime,
    this.endTime,
    required this.title,
    this.description,
    this.place,
    this.transportMode,
    this.transportMinutes,
    this.durationMinutes,
    this.estimatedCost,
    this.currency,
    List<String> tips = const [],
  }) : tips = List.unmodifiable(tips);

  factory ItineraryItem.fromJson(Map<String, Object?> json) {
    return ItineraryItem(
      id: _stringValue(json['id']),
      startTime: _nullableString(json['start_time']),
      endTime: _nullableString(json['end_time']),
      title: _stringValue(json['title']),
      description: _nullableString(json['description']),
      place: _parsePlace(json['place']),
      transportMode: _nullableString(json['transport_mode']),
      transportMinutes: _parseInt(json['transport_minutes']),
      durationMinutes: _parseInt(json['duration_minutes']),
      estimatedCost: _parseNum(json['estimated_cost']),
      currency: _nullableString(json['currency']),
      tips: _stringList(json['tips']),
    );
  }

  final String id;
  final String? startTime;
  final String? endTime;
  final String title;
  final String? description;
  final Place? place;
  final String? transportMode;
  final int? transportMinutes;
  final int? durationMinutes;
  final num? estimatedCost;
  final String? currency;
  final List<String> tips;

  ItineraryItem copyWith({
    String? id,
    String? startTime,
    String? endTime,
    String? title,
    String? description,
    Place? place,
    String? transportMode,
    int? transportMinutes,
    int? durationMinutes,
    num? estimatedCost,
    String? currency,
    List<String>? tips,
  }) {
    return ItineraryItem(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      title: title ?? this.title,
      description: description ?? this.description,
      place: place ?? this.place,
      transportMode: transportMode ?? this.transportMode,
      transportMinutes: transportMinutes ?? this.transportMinutes,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      currency: currency ?? this.currency,
      tips: tips ?? this.tips,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    if (startTime != null) 'start_time': startTime,
    if (endTime != null) 'end_time': endTime,
    'title': title,
    if (description != null) 'description': description,
    if (place != null) 'place': place!.toJson(),
    if (transportMode != null) 'transport_mode': transportMode,
    if (transportMinutes != null) 'transport_minutes': transportMinutes,
    if (durationMinutes != null) 'duration_minutes': durationMinutes,
    if (estimatedCost != null) 'estimated_cost': estimatedCost,
    if (currency != null) 'currency': currency,
    'tips': List<String>.from(tips),
  };

  static Place? _parsePlace(Object? value) {
    if (value is! Map) return null;
    return Place.fromJson(
      value.map((key, value) => MapEntry(key.toString(), value)),
    );
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
}

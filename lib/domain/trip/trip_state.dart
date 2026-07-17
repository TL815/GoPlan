class TripState {
  TripState({
    this.origin,
    this.destination,
    this.startDate,
    this.endDate,
    this.durationDays,
    this.travelerCount,
    this.budget,
    this.currency,
    List<String> preferences = const [],
    this.pace,
    this.datesFlexible = false,
  }) : preferences = List.unmodifiable(preferences);

  factory TripState.fromJson(Map<String, Object?> json) {
    return TripState(
      origin: _nullableString(json['origin']),
      destination: _nullableString(json['destination']),
      startDate: _parseDate(json['start_date']),
      endDate: _parseDate(json['end_date']),
      durationDays: _parseInt(json['duration_days']),
      travelerCount: _parseInt(json['traveler_count']),
      budget: _parseNum(json['budget']),
      currency: _nullableString(json['currency']),
      preferences: _stringList(json['preferences']),
      pace: _nullableString(json['pace']),
      datesFlexible: json['dates_flexible'] == true,
    );
  }

  final String? origin;
  final String? destination;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? durationDays;
  final int? travelerCount;
  final num? budget;
  final String? currency;
  final List<String> preferences;
  final String? pace;
  final bool datesFlexible;

  TripState copyWith({
    String? origin,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    int? durationDays,
    int? travelerCount,
    num? budget,
    String? currency,
    List<String>? preferences,
    String? pace,
    bool? datesFlexible,
  }) {
    return TripState(
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      durationDays: durationDays ?? this.durationDays,
      travelerCount: travelerCount ?? this.travelerCount,
      budget: budget ?? this.budget,
      currency: currency ?? this.currency,
      preferences: preferences ?? this.preferences,
      pace: pace ?? this.pace,
      datesFlexible: datesFlexible ?? this.datesFlexible,
    );
  }

  Map<String, Object?> toJson() => {
    if (origin != null) 'origin': origin,
    if (destination != null) 'destination': destination,
    if (startDate != null) 'start_date': _formatDate(startDate!),
    if (endDate != null) 'end_date': _formatDate(endDate!),
    if (durationDays != null) 'duration_days': durationDays,
    if (travelerCount != null) 'traveler_count': travelerCount,
    if (budget != null) 'budget': budget,
    if (currency != null) 'currency': currency,
    'preferences': List<String>.from(preferences),
    if (pace != null) 'pace': pace,
    'dates_flexible': datesFlexible,
  };

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

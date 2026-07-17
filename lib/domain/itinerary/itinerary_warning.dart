class ItineraryWarning {
  const ItineraryWarning({
    required this.id,
    required this.type,
    required this.message,
    this.severity,
    this.dayIndex,
    this.itemId,
  });

  factory ItineraryWarning.fromJson(Map<String, Object?> json) {
    return ItineraryWarning(
      id: _stringValue(json['id']),
      type: _stringValue(json['type']),
      message: _stringValue(json['message']),
      severity: _nullableString(json['severity']),
      dayIndex: _parseInt(json['day_index']),
      itemId: _nullableString(json['item_id']),
    );
  }

  final String id;
  final String type;
  final String message;
  final String? severity;
  final int? dayIndex;
  final String? itemId;

  Map<String, Object?> toJson() => {
    'id': id,
    'type': type,
    'message': message,
    if (severity != null) 'severity': severity,
    if (dayIndex != null) 'day_index': dayIndex,
    if (itemId != null) 'item_id': itemId,
  };

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

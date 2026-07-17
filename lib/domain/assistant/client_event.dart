import 'client_event_type.dart';

class ClientEvent {
  ClientEvent({
    required this.type,
    this.field,
    Map<String, Object?> payload = const {},
    DateTime? occurredAt,
  }) : payload = Map.unmodifiable(payload),
       occurredAt = occurredAt ?? DateTime.now();

  factory ClientEvent.fromJson(Map<String, Object?> json) {
    return ClientEvent(
      type: clientEventTypeFromJson(json['type']),
      field: _nullableString(json['field']),
      payload: _stringKeyMap(json['payload']),
      occurredAt: _parseDateTime(json['occurred_at']) ?? DateTime.now(),
    );
  }

  factory ClientEvent.chatMessage(String message) {
    return ClientEvent(
      type: ClientEventType.chatMessage,
      field: 'message',
      payload: {'message': message},
    );
  }

  factory ClientEvent.dateSelected(DateTime date) {
    return ClientEvent(
      type: ClientEventType.dateSelected,
      field: 'date',
      payload: {'date': _formatDate(date)},
    );
  }

  factory ClientEvent.dateRangeSelected(DateTime start, DateTime end) {
    return ClientEvent(
      type: ClientEventType.dateRangeSelected,
      field: 'date_range',
      payload: {'start_date': _formatDate(start), 'end_date': _formatDate(end)},
    );
  }

  factory ClientEvent.optionSelected({
    required String field,
    required Object? value,
  }) {
    return ClientEvent(
      type: ClientEventType.optionSelected,
      field: field,
      payload: {'value': value},
    );
  }

  factory ClientEvent.numberSubmitted({
    required String field,
    required num value,
  }) {
    return ClientEvent(
      type: ClientEventType.numberSubmitted,
      field: field,
      payload: {'value': value},
    );
  }

  final ClientEventType type;
  final String? field;
  final Map<String, Object?> payload;
  final DateTime occurredAt;

  Map<String, Object?> toJson() => {
    'type': clientEventTypeToJson(type),
    if (field != null) 'field': field,
    'payload': Map<String, Object?>.from(payload),
    'occurred_at': occurredAt.toIso8601String(),
  };

  static Map<String, Object?> _stringKeyMap(Object? value) {
    if (value is! Map) return const {};
    return value.map((key, value) => MapEntry(key.toString(), value));
  }

  static DateTime? _parseDateTime(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
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

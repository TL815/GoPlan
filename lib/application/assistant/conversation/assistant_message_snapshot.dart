import '../../../domain/assistant/client_event.dart';
import '../travel_assistant_message.dart';
import '../travel_assistant_message_role.dart';

class AssistantMessageSnapshot {
  const AssistantMessageSnapshot({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
    this.event,
  });

  factory AssistantMessageSnapshot.fromMessage(TravelAssistantMessage message) {
    return AssistantMessageSnapshot(
      id: message.id,
      role: message.role,
      text: message.text,
      createdAt: message.createdAt,
      event: message.event,
    );
  }

  factory AssistantMessageSnapshot.fromJson(Map<String, Object?> json) {
    return AssistantMessageSnapshot(
      id: _requiredString(json['id'], 'id'),
      role: _roleFromJson(json['role']),
      text: _requiredString(json['text'], 'text'),
      createdAt: _requiredDateTime(json['created_at'], 'created_at'),
      event: _eventFromJson(json['event']),
    );
  }

  final String id;
  final TravelAssistantMessageRole role;
  final String text;
  final DateTime createdAt;
  final ClientEvent? event;

  TravelAssistantMessage toMessage() {
    return TravelAssistantMessage(
      id: id,
      role: role,
      text: text,
      createdAt: createdAt,
      event: event,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'role': _roleToJson(role),
    'text': text,
    'created_at': createdAt.toIso8601String(),
    if (event != null) 'event': event!.toJson(),
  };

  static String _roleToJson(TravelAssistantMessageRole role) {
    return switch (role) {
      TravelAssistantMessageRole.user => 'user',
      TravelAssistantMessageRole.assistant => 'assistant',
    };
  }

  static TravelAssistantMessageRole _roleFromJson(Object? value) {
    return switch (value) {
      'user' => TravelAssistantMessageRole.user,
      'assistant' => TravelAssistantMessageRole.assistant,
      _ => throw FormatException('Invalid assistant message role: $value.'),
    };
  }

  static ClientEvent? _eventFromJson(Object? value) {
    if (value == null) return null;
    if (value is! Map) {
      throw const FormatException('Invalid message event: expected object.');
    }
    return ClientEvent.fromJson(
      value.map((key, value) => MapEntry(key.toString(), value)),
    );
  }

  static String _requiredString(Object? value, String field) {
    if (value is String) return value;
    throw FormatException('Invalid assistant message $field: expected string.');
  }

  static DateTime _requiredDateTime(Object? value, String field) {
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
    throw FormatException(
      'Invalid assistant message $field: expected ISO 8601 string.',
    );
  }
}

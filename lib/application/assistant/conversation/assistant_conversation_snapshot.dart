import '../../../domain/assistant/assistant_status.dart';
import '../../../domain/itinerary/itinerary.dart';
import '../../../domain/itinerary/itinerary_warning.dart';
import '../../../domain/trip/trip_state.dart';
import '../travel_assistant_message_role.dart';
import 'assistant_message_snapshot.dart';

const Object _unset = Object();

class AssistantConversationSnapshot {
  AssistantConversationSnapshot({
    required String id,
    required String userId,
    required String tripId,
    String? conversationId,
    String? title,
    required this.createdAt,
    required this.updatedAt,
    List<AssistantMessageSnapshot> messages = const [],
    this.tripState,
    this.itinerary,
    List<ItineraryWarning> warnings = const [],
    this.assistantStatus,
  }) : id = _requiredTrimmed(id, 'id'),
       userId = _requiredTrimmed(userId, 'userId'),
       tripId = _requiredTrimmed(tripId, 'tripId'),
       conversationId = _normalizeNullable(conversationId),
       messages = List.unmodifiable(messages),
       warnings = List.unmodifiable(warnings),
       title = _titleOrFallback(
         title: title,
         itinerary: itinerary,
         tripState: tripState,
         messages: messages,
       );

  factory AssistantConversationSnapshot.fromJson(Map<String, Object?> json) {
    return AssistantConversationSnapshot(
      id: _requiredString(json['id'], 'id'),
      userId: _requiredString(json['user_id'], 'user_id'),
      tripId: _requiredString(json['trip_id'], 'trip_id'),
      conversationId: _nullableString(json['conversation_id']),
      title: _nullableString(json['title']),
      createdAt: _requiredDateTime(json['created_at'], 'created_at'),
      updatedAt: _requiredDateTime(json['updated_at'], 'updated_at'),
      messages: _parseMessages(json['messages']),
      tripState: _parseTripState(json['trip_state']),
      itinerary: _parseItinerary(json['itinerary']),
      warnings: _parseWarnings(json['warnings']),
      assistantStatus: _parseAssistantStatus(json['assistant_status']),
    );
  }

  final String id;
  final String userId;
  final String tripId;
  final String? conversationId;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<AssistantMessageSnapshot> messages;
  final TripState? tripState;
  final Itinerary? itinerary;
  final List<ItineraryWarning> warnings;
  final AssistantStatus? assistantStatus;

  AssistantConversationSnapshot copyWith({
    String? id,
    String? userId,
    String? tripId,
    Object? conversationId = _unset,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<AssistantMessageSnapshot>? messages,
    Object? tripState = _unset,
    Object? itinerary = _unset,
    List<ItineraryWarning>? warnings,
    Object? assistantStatus = _unset,
  }) {
    return AssistantConversationSnapshot(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      tripId: tripId ?? this.tripId,
      conversationId: identical(conversationId, _unset)
          ? this.conversationId
          : conversationId as String?,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
      tripState: identical(tripState, _unset)
          ? this.tripState
          : tripState as TripState?,
      itinerary: identical(itinerary, _unset)
          ? this.itinerary
          : itinerary as Itinerary?,
      warnings: warnings ?? this.warnings,
      assistantStatus: identical(assistantStatus, _unset)
          ? this.assistantStatus
          : assistantStatus as AssistantStatus?,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'user_id': userId,
    'trip_id': tripId,
    if (conversationId != null) 'conversation_id': conversationId,
    'title': title,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'messages': messages.map((message) => message.toJson()).toList(),
    if (tripState != null) 'trip_state': tripState!.toJson(),
    if (itinerary != null) 'itinerary': itinerary!.toJson(),
    'warnings': warnings.map((warning) => warning.toJson()).toList(),
    if (assistantStatus != null)
      'assistant_status': assistantStatusToJson(assistantStatus!),
  };

  @override
  String toString() {
    return 'AssistantConversationSnapshot('
        'id: $id, userId: $userId, tripId: $tripId, '
        'title: $title, messageCount: ${messages.length}, '
        'updatedAt: $updatedAt, hasConversationId: ${conversationId != null})';
  }

  static String _titleOrFallback({
    required String? title,
    required Itinerary? itinerary,
    required TripState? tripState,
    required List<AssistantMessageSnapshot> messages,
  }) {
    final explicit = title?.trim();
    if (explicit != null && explicit.isNotEmpty) return explicit;

    final itineraryTitle = itinerary?.title.trim();
    if (itineraryTitle != null && itineraryTitle.isNotEmpty) {
      return itineraryTitle;
    }

    final destination =
        itinerary?.destination?.trim() ?? tripState?.destination?.trim();
    if (destination != null && destination.isNotEmpty) return destination;

    for (final message in messages) {
      if (message.role == TravelAssistantMessageRole.user) {
        final text = message.text.trim();
        if (text.isNotEmpty) {
          return text.length <= 24 ? text : text.substring(0, 24);
        }
      }
    }
    return '新的旅行计划';
  }

  static List<AssistantMessageSnapshot> _parseMessages(Object? value) {
    if (value == null) return const [];
    if (value is! Iterable) {
      throw const FormatException('Invalid conversation messages.');
    }
    return value.map((item) {
      if (item is! Map) {
        throw const FormatException('Invalid conversation message item.');
      }
      return AssistantMessageSnapshot.fromJson(
        item.map((key, value) => MapEntry(key.toString(), value)),
      );
    }).toList();
  }

  static TripState? _parseTripState(Object? value) {
    if (value == null) return null;
    if (value is! Map) {
      throw const FormatException('Invalid conversation trip_state.');
    }
    return TripState.fromJson(
      value.map((key, value) => MapEntry(key.toString(), value)),
    );
  }

  static Itinerary? _parseItinerary(Object? value) {
    if (value == null) return null;
    if (value is! Map) {
      throw const FormatException('Invalid conversation itinerary.');
    }
    return Itinerary.fromJson(
      value.map((key, value) => MapEntry(key.toString(), value)),
    );
  }

  static List<ItineraryWarning> _parseWarnings(Object? value) {
    if (value == null) return const [];
    if (value is! Iterable) {
      throw const FormatException('Invalid conversation warnings.');
    }
    return value.map((item) {
      if (item is! Map) {
        throw const FormatException('Invalid conversation warning item.');
      }
      return ItineraryWarning.fromJson(
        item.map((key, value) => MapEntry(key.toString(), value)),
      );
    }).toList();
  }

  static AssistantStatus? _parseAssistantStatus(Object? value) {
    if (value == null) return null;
    return assistantStatusFromJson(value);
  }

  static String _requiredString(Object? value, String field) {
    if (value is String) return value;
    throw FormatException('Invalid conversation $field: expected string.');
  }

  static String _requiredTrimmed(String value, String field) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw FormatException('Invalid conversation $field: must not be empty.');
    }
    return trimmed;
  }

  static String? _nullableString(Object? value) {
    if (value == null) return null;
    return value.toString();
  }

  static String? _normalizeNullable(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  static DateTime _requiredDateTime(Object? value, String field) {
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
    throw FormatException('Invalid conversation $field.');
  }
}

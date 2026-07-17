import '../itinerary/itinerary.dart';
import '../itinerary/itinerary_warning.dart';
import '../trip/trip_state.dart';
import 'assistant_status.dart';
import 'ui_action.dart';

class AssistantResponse {
  AssistantResponse({
    this.schemaVersion = '1.0',
    String? conversationId,
    required this.status,
    this.message = '',
    List<String> missingFields = const [],
    this.tripState,
    this.itinerary,
    List<ItineraryWarning> warnings = const [],
    UiAction? uiAction,
  }) : conversationId = _normalizeConversationId(conversationId),
       missingFields = List.unmodifiable(missingFields),
       warnings = List.unmodifiable(warnings),
       uiAction = uiAction ?? UiAction.none();

  factory AssistantResponse.fromJson(Map<String, Object?> json) {
    return AssistantResponse(
      schemaVersion: _nullableString(json['schema_version']) ?? '1.0',
      conversationId:
          _nullableString(json['conversation_id']) ??
          _nullableString(json['conversationId']),
      status: assistantStatusFromJson(json['status']),
      message: _nullableString(json['message']) ?? '',
      missingFields: _stringList(json['missing_fields']),
      tripState: _parseTripState(json['trip_state']),
      itinerary: _parseItinerary(json['itinerary']),
      warnings: _parseWarnings(json['warnings']),
      uiAction: UiAction.fromJson(json['ui_action']),
    );
  }

  final String schemaVersion;
  final String? conversationId;
  final AssistantStatus status;
  final String message;
  final List<String> missingFields;
  final TripState? tripState;
  final Itinerary? itinerary;
  final List<ItineraryWarning> warnings;
  final UiAction uiAction;

  Map<String, Object?> toJson() => {
    'schema_version': schemaVersion,
    if (conversationId != null) 'conversation_id': conversationId,
    'status': assistantStatusToJson(status),
    'message': message,
    'missing_fields': List<String>.from(missingFields),
    if (tripState != null) 'trip_state': tripState!.toJson(),
    'itinerary': itinerary?.toJson(),
    'warnings': warnings.map((warning) => warning.toJson()).toList(),
    'ui_action': uiAction.toJson(),
  };

  static TripState? _parseTripState(Object? value) {
    if (value is! Map) return null;
    return TripState.fromJson(
      value.map((key, value) => MapEntry(key.toString(), value)),
    );
  }

  static Itinerary? _parseItinerary(Object? value) {
    if (value == null) return null;
    if (value is! Map) {
      throw FormatException('Invalid itinerary: expected an object.');
    }
    return Itinerary.fromJson(
      value.map((key, value) => MapEntry(key.toString(), value)),
    );
  }

  static List<ItineraryWarning> _parseWarnings(Object? value) {
    if (value is! Iterable) return const [];
    final warnings = <ItineraryWarning>[];
    for (final item in value) {
      if (item is Map) {
        warnings.add(
          ItineraryWarning.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        );
      }
    }
    return warnings;
  }

  static List<String> _stringList(Object? value) {
    if (value is! Iterable) return const [];
    return value.map((item) => item.toString()).toList();
  }

  static String? _nullableString(Object? value) {
    if (value == null) return null;
    return value.toString();
  }

  static String? _normalizeConversationId(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}

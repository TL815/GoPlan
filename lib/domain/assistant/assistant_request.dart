import 'client_event.dart';

class AssistantRequest {
  AssistantRequest({
    required this.userId,
    required this.tripId,
    this.conversationId,
    required this.query,
    required this.event,
    Map<String, Object?> tripSnapshot = const {},
    this.timezone = 'Asia/Shanghai',
  }) : tripSnapshot = Map.unmodifiable(tripSnapshot);

  final String userId;
  final String tripId;
  final String? conversationId;
  final String query;
  final ClientEvent event;
  final Map<String, Object?> tripSnapshot;
  final String timezone;

  Map<String, Object?> toJson() => {
    'user_id': userId,
    'trip_id': tripId,
    if (conversationId != null && conversationId!.isNotEmpty)
      'conversation_id': conversationId,
    'query': query,
    'event': event.toJson(),
    'trip_snapshot': Map<String, Object?>.from(tripSnapshot),
    'timezone': timezone,
  };
}

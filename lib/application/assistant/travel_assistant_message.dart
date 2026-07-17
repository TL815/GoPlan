import '../../domain/assistant/assistant_response.dart';
import '../../domain/assistant/client_event.dart';
import 'travel_assistant_message_role.dart';

const Object _unset = Object();

/// Immutable message item used by the assistant conversation state.
class TravelAssistantMessage {
  const TravelAssistantMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
    this.event,
    this.response,
  });

  final String id;
  final TravelAssistantMessageRole role;
  final String text;
  final DateTime createdAt;
  final ClientEvent? event;
  final AssistantResponse? response;

  TravelAssistantMessage copyWith({
    String? id,
    TravelAssistantMessageRole? role,
    String? text,
    DateTime? createdAt,
    Object? event = _unset,
    Object? response = _unset,
  }) {
    return TravelAssistantMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      event: identical(event, _unset) ? this.event : event as ClientEvent?,
      response: identical(response, _unset)
          ? this.response
          : response as AssistantResponse?,
    );
  }
}

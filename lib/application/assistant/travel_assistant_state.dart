import '../../domain/assistant/assistant_response.dart';
import '../../domain/assistant/assistant_status.dart';
import '../../domain/assistant/ui_action.dart';
import '../../domain/itinerary/itinerary.dart';
import '../../domain/itinerary/itinerary_warning.dart';
import '../../domain/trip/trip_state.dart';
import 'travel_assistant_failure.dart';
import 'travel_assistant_message.dart';
import 'travel_assistant_phase.dart';

const Object _unset = Object();

/// Immutable snapshot of the current travel assistant conversation.
class TravelAssistantState {
  TravelAssistantState({
    required this.phase,
    List<TravelAssistantMessage> messages = const [],
    required this.userId,
    required this.tripId,
    this.timezone = 'Asia/Shanghai',
    String? conversationId,
    this.tripState,
    this.itinerary,
    List<ItineraryWarning> warnings = const [],
    UiAction? uiAction,
    this.assistantStatus,
    this.lastResponse,
    this.lastFailure,
  }) : messages = List.unmodifiable(messages),
       conversationId = _normalizeConversationId(conversationId),
       warnings = List.unmodifiable(warnings),
       uiAction = uiAction ?? UiAction.none();

  factory TravelAssistantState.initial({
    required String userId,
    required String tripId,
    String timezone = 'Asia/Shanghai',
    String? conversationId,
    List<TravelAssistantMessage> messages = const [],
    TripState? tripState,
    Itinerary? itinerary,
    List<ItineraryWarning> warnings = const [],
    AssistantStatus? assistantStatus,
  }) {
    final normalizedTimezone = timezone.trim().isEmpty
        ? 'Asia/Shanghai'
        : timezone.trim();
    return TravelAssistantState(
      phase: TravelAssistantPhase.idle,
      userId: userId.trim(),
      tripId: tripId.trim(),
      timezone: normalizedTimezone,
      conversationId: conversationId,
      messages: messages,
      tripState: tripState,
      itinerary: itinerary,
      warnings: warnings,
      assistantStatus: assistantStatus,
    );
  }

  final TravelAssistantPhase phase;
  final List<TravelAssistantMessage> messages;
  final String userId;
  final String tripId;
  final String timezone;
  final String? conversationId;
  final TripState? tripState;
  final Itinerary? itinerary;
  final List<ItineraryWarning> warnings;
  final UiAction uiAction;
  final AssistantStatus? assistantStatus;
  final AssistantResponse? lastResponse;
  final TravelAssistantFailure? lastFailure;

  bool get isSending => phase == TravelAssistantPhase.sending;
  bool get hasFailure => lastFailure != null;
  bool get hasConversation => conversationId != null;
  bool get hasItinerary => itinerary != null;
  bool get needsInput => assistantStatus == AssistantStatus.needInput;

  TravelAssistantState copyWith({
    TravelAssistantPhase? phase,
    List<TravelAssistantMessage>? messages,
    String? userId,
    String? tripId,
    String? timezone,
    Object? conversationId = _unset,
    Object? tripState = _unset,
    Object? itinerary = _unset,
    List<ItineraryWarning>? warnings,
    UiAction? uiAction,
    Object? assistantStatus = _unset,
    Object? lastResponse = _unset,
    Object? lastFailure = _unset,
  }) {
    return TravelAssistantState(
      phase: phase ?? this.phase,
      messages: messages ?? this.messages,
      userId: userId ?? this.userId,
      tripId: tripId ?? this.tripId,
      timezone: timezone ?? this.timezone,
      conversationId: identical(conversationId, _unset)
          ? this.conversationId
          : conversationId as String?,
      tripState: identical(tripState, _unset)
          ? this.tripState
          : tripState as TripState?,
      itinerary: identical(itinerary, _unset)
          ? this.itinerary
          : itinerary as Itinerary?,
      warnings: warnings ?? this.warnings,
      uiAction: uiAction ?? this.uiAction,
      assistantStatus: identical(assistantStatus, _unset)
          ? this.assistantStatus
          : assistantStatus as AssistantStatus?,
      lastResponse: identical(lastResponse, _unset)
          ? this.lastResponse
          : lastResponse as AssistantResponse?,
      lastFailure: identical(lastFailure, _unset)
          ? this.lastFailure
          : lastFailure as TravelAssistantFailure?,
    );
  }

  static String? _normalizeConversationId(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}

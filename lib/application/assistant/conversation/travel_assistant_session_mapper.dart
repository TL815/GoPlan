import '../../../domain/assistant/assistant_status.dart';
import '../../../domain/itinerary/itinerary.dart';
import '../../../domain/itinerary/itinerary_warning.dart';
import '../../../domain/trip/trip_state.dart';
import '../travel_assistant_message.dart';
import '../travel_assistant_state.dart';
import 'assistant_conversation_snapshot.dart';
import 'assistant_message_snapshot.dart';

class TravelAssistantSessionMapper {
  const TravelAssistantSessionMapper();

  AssistantConversationSnapshot fromState({
    required TravelAssistantState state,
    required String localConversationId,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? title,
  }) {
    return AssistantConversationSnapshot(
      id: localConversationId,
      userId: state.userId,
      tripId: state.tripId,
      conversationId: state.conversationId,
      title: title,
      createdAt: createdAt,
      updatedAt: updatedAt,
      messages: state.messages
          .map(AssistantMessageSnapshot.fromMessage)
          .toList(),
      tripState: state.tripState,
      itinerary: state.itinerary,
      warnings: state.warnings,
      assistantStatus: state.assistantStatus,
    );
  }

  TravelAssistantRestoreData restore(AssistantConversationSnapshot snapshot) {
    return TravelAssistantRestoreData(
      userId: snapshot.userId,
      tripId: snapshot.tripId,
      conversationId: snapshot.conversationId,
      messages: restoreMessages(snapshot),
      tripState: snapshot.tripState,
      itinerary: snapshot.itinerary,
      warnings: snapshot.warnings,
      assistantStatus: snapshot.assistantStatus,
    );
  }

  List<TravelAssistantMessage> restoreMessages(
    AssistantConversationSnapshot snapshot,
  ) {
    return snapshot.messages.map((message) => message.toMessage()).toList();
  }
}

class TravelAssistantRestoreData {
  TravelAssistantRestoreData({
    required this.userId,
    required this.tripId,
    required this.conversationId,
    List<TravelAssistantMessage> messages = const [],
    this.tripState,
    this.itinerary,
    List<ItineraryWarning> warnings = const [],
    this.assistantStatus,
  }) : messages = List.unmodifiable(messages),
       warnings = List.unmodifiable(warnings);

  final String userId;
  final String tripId;
  final String? conversationId;
  final List<TravelAssistantMessage> messages;
  final TripState? tripState;
  final Itinerary? itinerary;
  final List<ItineraryWarning> warnings;
  final AssistantStatus? assistantStatus;
}

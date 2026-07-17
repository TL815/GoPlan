import 'assistant_conversation_snapshot.dart';

class AssistantConversationSummary {
  const AssistantConversationSummary({
    required this.id,
    required this.userId,
    required this.tripId,
    required this.title,
    required this.destination,
    required this.updatedAt,
    required this.messageCount,
    required this.hasItinerary,
  });

  factory AssistantConversationSummary.fromSnapshot(
    AssistantConversationSnapshot snapshot,
  ) {
    return AssistantConversationSummary(
      id: snapshot.id,
      userId: snapshot.userId,
      tripId: snapshot.tripId,
      title: snapshot.title,
      destination:
          snapshot.itinerary?.destination ?? snapshot.tripState?.destination,
      updatedAt: snapshot.updatedAt,
      messageCount: snapshot.messages.length,
      hasItinerary: snapshot.itinerary != null,
    );
  }

  final String id;
  final String userId;
  final String tripId;
  final String title;
  final String? destination;
  final DateTime updatedAt;
  final int messageCount;
  final bool hasItinerary;
}

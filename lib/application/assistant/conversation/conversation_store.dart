import 'assistant_conversation_snapshot.dart';
import 'assistant_conversation_summary.dart';

abstract interface class ConversationStore {
  Future<void> save(AssistantConversationSnapshot conversation);

  Future<AssistantConversationSnapshot?> getById(String id);

  Future<AssistantConversationSnapshot?> getLatestForTrip({
    required String userId,
    required String tripId,
  });

  Future<List<AssistantConversationSummary>> listForUser(String userId);

  Future<void> delete(String id);

  Future<void> clearForUser(String userId);
}

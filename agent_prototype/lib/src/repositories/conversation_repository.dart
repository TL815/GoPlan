import '../models/agent_message.dart';

abstract interface class ConversationRepository {
  Future<String> createSession();

  Future<void> appendMessages({
    required String sessionId,
    required List<AgentMessage> messages,
  });

  Future<List<AgentMessage>> getMessages(String sessionId);
}

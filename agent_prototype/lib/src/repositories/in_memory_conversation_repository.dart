import '../models/agent_message.dart';
import 'conversation_repository.dart';

class InMemoryConversationRepository implements ConversationRepository {
  final Map<String, List<AgentMessage>> _sessions = {};

  @override
  Future<String> createSession() async {
    final sessionId = DateTime.now().microsecondsSinceEpoch.toString();
    _sessions[sessionId] = [];
    return sessionId;
  }

  @override
  Future<void> appendMessages({
    required String sessionId,
    required List<AgentMessage> messages,
  }) async {
    _sessions.putIfAbsent(sessionId, () => []).addAll(messages);
  }

  @override
  Future<List<AgentMessage>> getMessages(String sessionId) async {
    return List.unmodifiable(_sessions[sessionId] ?? const []);
  }
}

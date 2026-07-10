import '../models/agent_message.dart';
import '../repositories/conversation_repository.dart';

class ConversationService {
  const ConversationService({required ConversationRepository repository})
    : _repository = repository;

  final ConversationRepository _repository;

  Future<List<AgentMessage>> loadHistory(String sessionId) {
    return _repository.getMessages(sessionId);
  }
}

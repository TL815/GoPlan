import 'adapters/mock_llm_adapter.dart';
import 'agent_config.dart';
import 'models/agent_request.dart';
import 'models/agent_response.dart';
import 'parsers/plan_draft_parser.dart';
import 'repositories/in_memory_conversation_repository.dart';
import 'services/travel_agent_service.dart';

class AgentClient {
  AgentClient({required TravelAgentService service}) : _service = service;

  factory AgentClient.prototype({AgentConfig config = const AgentConfig()}) {
    return AgentClient(
      service: TravelAgentService(
        config: config,
        llmAdapter: const MockLlmAdapter(),
        planDraftParser: const PlanDraftParser(),
        conversationRepository: InMemoryConversationRepository(),
      ),
    );
  }

  final TravelAgentService _service;

  Future<AgentResponse> sendMessage(AgentRequest request) {
    return _service.handle(request);
  }
}

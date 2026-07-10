import '../adapters/llm_adapter.dart';
import '../agent_config.dart';
import '../models/agent_message.dart';
import '../models/agent_request.dart';
import '../models/agent_response.dart';
import '../parsers/agent_response_parser.dart';
import '../parsers/plan_draft_parser.dart';
import '../prompts/plan_schema_prompt.dart';
import '../prompts/travel_agent_prompt.dart';
import '../repositories/conversation_repository.dart';

class TravelAgentService {
  TravelAgentService({
    required this.config,
    required this.llmAdapter,
    required this.planDraftParser,
    required this.conversationRepository,
    AgentResponseParser responseParser = const AgentResponseParser(),
  }) : _responseParser = responseParser;

  final AgentConfig config;
  final LlmAdapter llmAdapter;
  final PlanDraftParser planDraftParser;
  final ConversationRepository conversationRepository;
  final AgentResponseParser _responseParser;

  Future<AgentResponse> handle(AgentRequest request) async {
    final sessionId =
        request.sessionId ?? await conversationRepository.createSession();
    final userMessage = AgentMessage(
      role: AgentMessageRole.user,
      content: request.userInput,
      createdAt: DateTime.now(),
    );

    final raw = await llmAdapter.complete(
      AgentPromptRequest(
        systemPrompt: travelAgentSystemPrompt,
        schemaPrompt: planSchemaPrompt,
        request: request,
      ),
    );
    final json = _responseParser.parseJsonObject(raw);
    final replyText = json['replyText']?.toString().trim() ?? '';
    final planDraft = json.containsKey('planDraft')
        ? planDraftParser.parse(json['planDraft'])
        : null;
    final assistantMessage = AgentMessage(
      role: AgentMessageRole.assistant,
      content: replyText,
      createdAt: DateTime.now(),
    );

    await conversationRepository.appendMessages(
      sessionId: sessionId,
      messages: [userMessage, assistantMessage],
    );

    return AgentResponse(
      sessionId: sessionId,
      replyText: replyText,
      planDraft: planDraft,
      messages: [userMessage, assistantMessage],
    );
  }
}

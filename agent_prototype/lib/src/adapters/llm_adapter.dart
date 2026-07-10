import '../models/agent_request.dart';

abstract interface class LlmAdapter {
  Future<String> complete(AgentPromptRequest request);
}

class AgentPromptRequest {
  const AgentPromptRequest({
    required this.systemPrompt,
    required this.schemaPrompt,
    required this.request,
  });

  final String systemPrompt;
  final String schemaPrompt;
  final AgentRequest request;
}

import 'agent_context.dart';
import 'agent_message.dart';

class AgentRequest {
  const AgentRequest({
    required this.userInput,
    required this.context,
    this.sessionId,
    this.history = const [],
  });

  final String userInput;
  final String? sessionId;
  final List<AgentMessage> history;
  final AgentContext context;
}

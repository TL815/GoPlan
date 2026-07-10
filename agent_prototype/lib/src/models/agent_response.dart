import 'agent_message.dart';
import 'plan_draft.dart';
import 'tool_result.dart';

class AgentResponse {
  const AgentResponse({
    required this.replyText,
    required this.messages,
    this.sessionId,
    this.planDraft,
    this.toolResults = const [],
  });

  final String? sessionId;
  final String replyText;
  final PlanDraft? planDraft;
  final List<AgentMessage> messages;
  final List<ToolResult> toolResults;
}

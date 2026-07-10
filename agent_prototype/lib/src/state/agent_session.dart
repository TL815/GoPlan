import '../models/agent_message.dart';
import '../models/plan_draft.dart';

class AgentSession {
  const AgentSession({
    required this.id,
    this.messages = const [],
    this.currentPlan,
  });

  final String id;
  final List<AgentMessage> messages;
  final PlanDraft? currentPlan;
}

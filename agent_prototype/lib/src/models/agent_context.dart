import 'plan_draft.dart';

class AgentContext {
  const AgentContext({this.userPreferences = const {}, this.currentPlan});

  factory AgentContext.empty() => const AgentContext();

  final Map<String, Object?> userPreferences;
  final PlanDraft? currentPlan;
}

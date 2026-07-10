import 'package:goplan_agent_prototype/goplan_agent_prototype.dart';

Future<void> main() async {
  final client = AgentClient.prototype();
  final response = await client.sendMessage(
    AgentRequest(
      userInput: 'Plan a relaxed 3-day trip to Hangzhou with food and scenery.',
      context: AgentContext.empty(),
    ),
  );

  print(response.replyText);
  print(response.planDraft?.title ?? 'No plan draft returned.');
}

import 'package:goplan_agent_prototype/goplan_agent_prototype.dart';
import 'package:test/test.dart';

void main() {
  test('prototype client returns a plan draft from mock adapter', () async {
    final client = AgentClient.prototype();

    final response = await client.sendMessage(
      AgentRequest(
        userInput: 'Plan Hangzhou for 3 days.',
        context: AgentContext.empty(),
      ),
    );

    expect(response.replyText, isNotEmpty);
    expect(response.planDraft, isNotNull);
    expect(response.planDraft!.durationDays, 3);
    expect(response.planDraft!.days, hasLength(3));
  });
}

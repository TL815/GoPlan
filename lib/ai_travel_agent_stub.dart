import 'ai_travel_agent_models.dart';

AiTravelAgent createAiTravelAgent() => const _UnsupportedAiTravelAgent();

class _UnsupportedAiTravelAgent implements AiTravelAgent {
  const _UnsupportedAiTravelAgent();

  @override
  Future<TravelAgentResult> planTrip(
    String prompt, {
    List<AiTravelAgentTurn> history = const [],
  }) async {
    throw const AiTravelAgentException('当前平台暂未配置 AI 旅行规划服务。');
  }
}

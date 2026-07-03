import 'dart:convert';
import 'dart:io';

import 'ai_travel_agent_models.dart';
import 'local_config.dart';

const String _llmApiKey = String.fromEnvironment(
  'DEEPSEEK_API_KEY',
  defaultValue: localDeepSeekApiKey,
);
const String _llmApiBase = String.fromEnvironment(
  'LLM_API_BASE',
  defaultValue: 'https://api.deepseek.com',
);
const String _llmModel = String.fromEnvironment(
  'LLM_MODEL',
  defaultValue: 'deepseek-chat',
);

AiTravelAgent createAiTravelAgent() => const DeepSeekTravelAgent();

class DeepSeekTravelAgent implements AiTravelAgent {
  const DeepSeekTravelAgent();

  @override
  Future<TravelAgentResult> planTrip(
    String prompt, {
    List<AiTravelAgentTurn> history = const [],
  }) async {
    if (_llmApiKey.isEmpty) {
      throw const AiTravelAgentException(
        '缺少 DEEPSEEK_API_KEY，请用 --dart-define=DEEPSEEK_API_KEY=你的Key 重新运行。',
      );
    }

    final endpoint = Uri.parse(_llmApiBase).resolve('/chat/completions');
    final client = HttpClient();
    try {
      final request = await client
          .postUrl(endpoint)
          .timeout(const Duration(seconds: 8));
      request.headers
        ..contentType = ContentType.json
        ..set(HttpHeaders.authorizationHeader, 'Bearer $_llmApiKey');
      request.write(
        jsonEncode({
          'model': _llmModel,
          'temperature': 0.35,
          'response_format': {'type': 'json_object'},
          'messages': [
            {'role': 'system', 'content': _systemPrompt},
            ..._toApiMessages(history),
            {'role': 'user', 'content': prompt},
          ],
        }),
      );

      final response = await request.close().timeout(
        const Duration(seconds: 45),
      );
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AiTravelAgentException('AI 服务返回 ${response.statusCode}：$body');
      }

      final decoded = jsonDecode(body);
      if (decoded is! Map<String, Object?>) {
        throw const AiTravelAgentException('AI 服务返回格式异常。');
      }
      final choices = decoded['choices'];
      if (choices is! List || choices.isEmpty) {
        throw const AiTravelAgentException('AI 没有返回可用行程。');
      }
      final first = choices.first;
      if (first is! Map<String, Object?>) {
        throw const AiTravelAgentException('AI 返回内容格式异常。');
      }
      final message = first['message'];
      if (message is! Map<String, Object?>) {
        throw const AiTravelAgentException('AI 消息格式异常。');
      }
      final content = message['content'];
      if (content is! String || content.trim().isEmpty) {
        throw const AiTravelAgentException('AI 返回内容为空。');
      }

      return _parseTravelPlan(content);
    } on AiTravelAgentException {
      rethrow;
    } on SocketException catch (error) {
      throw AiTravelAgentException('无法连接 AI 服务：${error.message}');
    } on FormatException catch (error) {
      throw AiTravelAgentException('AI 返回 JSON 解析失败：${error.message}');
    } catch (error) {
      throw AiTravelAgentException('AI 旅行规划失败：$error');
    } finally {
      client.close(force: true);
    }
  }
}

List<Map<String, String>> _toApiMessages(List<AiTravelAgentTurn> history) {
  const maxTurns = 8;
  return history
      .where((turn) => turn.content.trim().isNotEmpty)
      .skip(history.length > maxTurns ? history.length - maxTurns : 0)
      .map(
        (turn) => {
          'role': turn.role == AiTravelAgentRole.user ? 'user' : 'assistant',
          'content': turn.content,
        },
      )
      .toList(growable: false);
}

const _systemPrompt = '''
你是 GoPlan 的真实 AI 旅游路线规划 Agent。
你必须根据用户输入生成可执行的中文自由行路线，而不是闲聊。
你必须遵守多轮上下文：如果用户追问“具体每天的行程”“继续”“展开第 2 天”等，必须基于上一轮已生成的目的地、天数和路线继续细化，不要擅自切换目的地。
如果用户没有明确提出新目的地，不要生成与历史目的地无关的新城市路线。
如果用户只是要求细化上一轮，请保持 destination 和 durationDays 与上一轮一致，并把 days 内容写得更具体。
请综合考虑：天数、城市移动顺序、每天景点密度、餐饮、交通方式、休息节奏、首次到访友好度。
如果用户没有给出明确天数，请合理假设 3-5 天，并在 summary 中说明假设。
只返回 JSON，不要 Markdown，不要代码块。
JSON schema:
{
  "destination": "目的地或路线名称",
  "durationDays": 5,
  "summary": "一段 40-80 字中文总结",
  "days": [
    {
      "day": 1,
      "title": "当天标题",
      "route": "地点A → 地点B → 地点C",
      "transport": "主要交通方式和移动建议",
      "places": ["地点A", "地点B"],
      "food": ["推荐餐饮或区域"],
      "notes": "当天节奏、预约、避坑或天气建议"
    }
  ]
}
要求：
1. days 数量必须等于 durationDays。
2. 每天 places 2-5 个，避免过载。
3. route 必须是当天路线顺序。
4. 所有文本使用简体中文。
''';

TravelAgentResult _parseTravelPlan(String content) {
  final normalized = _stripCodeFence(content);
  final json = jsonDecode(normalized);
  if (json is! Map<String, Object?>) {
    throw const FormatException('根节点不是对象');
  }

  final daysJson = json['days'];
  if (daysJson is! List || daysJson.isEmpty) {
    throw const FormatException('days 为空');
  }

  final days = daysJson
      .whereType<Map<String, Object?>>()
      .map(
        (day) => TravelAgentDay(
          day: _asInt(day['day']),
          title: _asString(day['title'], fallback: '当天安排'),
          route: _asString(day['route'], fallback: '待确认路线'),
          transport: _asString(day['transport'], fallback: '步行/公共交通'),
          places: _asStringList(day['places']),
          food: _asStringList(day['food']),
          notes: _asString(day['notes']),
        ),
      )
      .toList(growable: false);

  if (days.isEmpty) throw const FormatException('没有有效 day');

  return TravelAgentResult(
    destination: _asString(json['destination'], fallback: 'AI 旅行计划'),
    durationDays: _asInt(json['durationDays'], fallback: days.length),
    summary: _asString(json['summary'], fallback: '已为你生成一份可执行的旅行路线。'),
    days: days,
  );
}

String _stripCodeFence(String value) {
  final trimmed = value.trim();
  if (!trimmed.startsWith('```')) return trimmed;
  return trimmed
      .replaceFirst(RegExp(r'^```(?:json)?\s*', multiLine: true), '')
      .replaceFirst(RegExp(r'\s*```$', multiLine: true), '')
      .trim();
}

String _asString(Object? value, {String fallback = ''}) {
  if (value == null) return fallback;
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

int _asInt(Object? value, {int fallback = 1}) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

List<String> _asStringList(Object? value) {
  if (value is! List) return const [];
  return value
      .map((item) => item.toString().trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

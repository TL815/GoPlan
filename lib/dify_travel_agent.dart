import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'ai_travel_agent_models.dart';

const String _difyApiKey = String.fromEnvironment('DIFY_API_KEY');
const String _difyApiBase = String.fromEnvironment(
  'DIFY_API_BASE',
  defaultValue: 'https://api.dify.ai/v1',
);
const String _difyUser = String.fromEnvironment(
  'DIFY_USER_ID',
  defaultValue: 'goplan-local-user',
);
const String _difyTripId = String.fromEnvironment(
  'DIFY_TRIP_ID',
  defaultValue: 'goplan-local-trip',
);
const Duration _difyTimeout = Duration(seconds: 180);

class DifyTravelAgent implements AiTravelAgent {
  final http.Client _client = http.Client();
  String? _conversationId;

  @override
  Future<AiTravelAgentReply> planTrip(
    String prompt, {
    List<AiTravelAgentTurn> history = const [],
  }) async {
    if (_difyApiKey.isEmpty) {
      throw const AiTravelAgentException(
        '缺少 DIFY_API_KEY，请用 --dart-define=DIFY_API_KEY=你的Key 重新运行。',
      );
    }

    final endpoint = _difyEndpoint('chat-messages');
    try {
      final response = await _postWithRetry(
        endpoint,
        body: {
          'inputs': {
            'trip_id': _difyTripId,
            'user_id': _difyUser,
            'timezone': 'Asia/Shanghai',
            'client_event': 'chat_message',
            'backend_snapshot': '{}',
          },
          'query': prompt,
          'response_mode': 'blocking',
          'user': _difyUser,
          if (_conversationId != null) 'conversation_id': _conversationId,
        },
      );

      final body = utf8.decode(response.bodyBytes);
      _logDify('status=${response.statusCode} body=${_truncate(body)}');
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AiTravelAgentException('Dify 服务返回 ${response.statusCode}：$body');
      }

      final decoded = jsonDecode(body);
      if (decoded is! Map<String, Object?>) {
        throw const AiTravelAgentException('Dify 服务返回格式异常。');
      }

      final conversationId = decoded['conversation_id']?.toString().trim();
      if (conversationId != null && conversationId.isNotEmpty) {
        _conversationId = conversationId;
      }

      final answer = decoded['answer'];
      if (answer is! String || answer.trim().isEmpty) {
        throw const AiTravelAgentException('Dify 返回内容为空。');
      }

      return _parseDifyAnswer(answer);
    } on AiTravelAgentException {
      rethrow;
    } on FormatException catch (error) {
      throw AiTravelAgentException('Dify 返回 JSON 解析失败：${error.message}');
    } on TimeoutException {
      throw const AiTravelAgentException('Dify 请求超过 180 秒，请稍后重试。');
    } on http.ClientException catch (error) {
      throw AiTravelAgentException('Dify 网络连接失败：${error.message}');
    } catch (error) {
      if (_looksLikeSocketException(error)) {
        throw AiTravelAgentException('Dify 网络连接失败：$error');
      }
      throw AiTravelAgentException('Dify 旅行规划失败：$error');
    }
  }

  Future<http.Response> _postWithRetry(
    Uri endpoint, {
    required Map<String, Object?> body,
  }) async {
    Object? lastError;
    for (var attempt = 0; attempt < 3; attempt++) {
      final stopwatch = Stopwatch()..start();
      try {
        _logDify('POST $endpoint attempt=${attempt + 1}');
        final response = await _client
            .post(
              endpoint,
              headers: {
                'Authorization': 'Bearer $_difyApiKey',
                'Accept': 'application/json',
                'Content-Type': 'application/json; charset=utf-8',
                'Connection': 'close',
                'User-Agent': 'GoPlan/0.1 Flutter',
              },
              body: jsonEncode(body),
            )
            .timeout(
              _difyTimeout,
              onTimeout: () {
                throw TimeoutException('Dify 请求超过 180 秒', _difyTimeout);
              },
            );
        stopwatch.stop();
        _logDify(
          'attempt=${attempt + 1} elapsed=${stopwatch.elapsedMilliseconds}ms',
        );
        return response;
      } on TimeoutException {
        stopwatch.stop();
        rethrow;
      } on http.ClientException catch (error) {
        stopwatch.stop();
        lastError = error;
        _logDify(
          'attempt=${attempt + 1} client_error=${error.message} elapsed=${stopwatch.elapsedMilliseconds}ms',
        );
      } catch (error) {
        stopwatch.stop();
        lastError = error;
        _logDify(
          'attempt=${attempt + 1} error=${error.runtimeType} elapsed=${stopwatch.elapsedMilliseconds}ms',
        );
        if (!_isRetryableNetworkError(error)) rethrow;
      }

      if (attempt < 2) {
        await Future<void>.delayed(Duration(milliseconds: 700 * (attempt + 1)));
      } else {
        if (attempt == 2) break;
      }
    }
    throw AiTravelAgentException('无法连接 Dify 服务：$lastError');
  }
}

bool _isRetryableNetworkError(Object error) {
  return error is http.ClientException || _looksLikeSocketException(error);
}

bool _looksLikeSocketException(Object error) {
  final type = error.runtimeType.toString();
  return type.contains('SocketException') ||
      error.toString().contains('SocketException');
}

void _logDify(String message) {
  debugPrint('[Dify] $message');
}

String _truncate(String value, {int maxLength = 2000}) {
  if (value.length <= maxLength) return value;
  return '${value.substring(0, maxLength)}...';
}

Uri _difyEndpoint(String path) {
  final base = _difyApiBase.endsWith('/') ? _difyApiBase : '$_difyApiBase/';
  return Uri.parse(base).resolve(path);
}

AiTravelAgentReply _parseDifyAnswer(String answer) {
  final normalized = _stripCodeFence(answer);
  final decoded = _tryDecodeObject(normalized);
  if (decoded == null) {
    final text = answer.trim();
    return AiTravelAgentReply(
      replyText: text,
      requestStartDate: _asksForDate(text),
    );
  }

  final replyText = _asString(
    decoded['replyText'],
    fallback: _asString(decoded['answer'], fallback: answer.trim()),
  );
  final planJson = decoded['planDraft'];
  final plan = planJson is Map<String, Object?>
      ? _parsePlanDraft(planJson)
      : null;

  if (plan == null) {
    final questions = _asStringList(decoded['nextQuestions']);
    final text = replyText.isNotEmpty
        ? replyText
        : _fallbackText(questions, answer);
    return AiTravelAgentReply(
      replyText: text,
      requestStartDate: _shouldRequestStartDate(decoded, text),
    );
  }

  return AiTravelAgentReply(
    replyText: replyText.isNotEmpty ? replyText : plan.toChatText(),
    plan: plan,
  );
}

bool _shouldRequestStartDate(Map<String, Object?> decoded, String replyText) {
  final missingSlotText = [
    ..._flattenStrings(decoded['missing_slots']),
    ..._flattenStrings(decoded['missingSlots']),
  ].join(' ').toLowerCase();
  if (_looksLikeStartDateSlot(missingSlotText)) return true;

  final extractedSlots = decoded['extractedSlots'];
  if (extractedSlots is Map<String, Object?>) {
    final startDate =
        extractedSlots['start_date'] ?? extractedSlots['startDate'];
    if (_isEmptySlotValue(startDate)) {
      final promptText = [
        replyText,
        ..._flattenStrings(decoded['nextQuestions']),
      ].join(' ');
      return _asksForDate(promptText);
    }
  }

  final promptText = [
    replyText,
    ..._flattenStrings(decoded['nextQuestions']),
  ].join(' ');
  return _asksForDate(promptText);
}

bool _looksLikeStartDateSlot(String value) {
  return value.contains('start_date') ||
      value.contains('startdate') ||
      value.contains('date') ||
      value.contains('日期') ||
      value.contains('时间') ||
      value.contains('出发');
}

bool _asksForDate(String value) {
  return value.contains('出发日期') ||
      value.contains('出行日期') ||
      value.contains('旅行日期') ||
      value.contains('开始日期') ||
      value.contains('出行时间') ||
      value.contains('开始时间') ||
      value.contains('哪天') ||
      value.contains('什么时候') ||
      value.contains('什么时候出发') ||
      value.contains('出发时间');
}

bool _isEmptySlotValue(Object? value) {
  if (value == null) return true;
  if (value is String) return value.trim().isEmpty;
  if (value is List) return value.isEmpty;
  return false;
}

Map<String, Object?>? _tryDecodeObject(String value) {
  try {
    final decoded = jsonDecode(value);
    return decoded is Map<String, Object?> ? decoded : null;
  } on FormatException {
    return null;
  }
}

TravelAgentResult _parsePlanDraft(Map<String, Object?> json) {
  final daysJson = json['days'];
  if (daysJson is! List || daysJson.isEmpty) {
    throw const FormatException('planDraft.days 为空');
  }

  final days = daysJson
      .whereType<Map<String, Object?>>()
      .map(
        (day) => TravelAgentDay(
          day: _asInt(day['day']),
          title: _asString(day['title'], fallback: '当天安排'),
          route: _asString(
            day['route'],
            fallback: _routeFromPlaces(day['places']),
          ),
          transport: _asString(day['transport'], fallback: '步行/公共交通'),
          places: _asPlaceNames(day['places']),
          food: _asStringList(day['food']),
          notes: _asString(
            day['notes'],
            fallback: _asString(
              day['tips'],
              fallback: _asString(day['riskNotes']),
            ),
          ),
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

String _routeFromPlaces(Object? value) {
  final places = _asPlaceNames(value);
  return places.isEmpty ? '待确认路线' : places.join(' → ');
}

String _fallbackText(List<String> questions, String answer) {
  return questions.isNotEmpty ? questions.first : answer.trim();
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

List<String> _flattenStrings(Object? value) {
  if (value == null) return const [];
  if (value is String) return [value];
  if (value is List) {
    return value
        .expand((item) => _flattenStrings(item))
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
  if (value is Map) {
    return value.values
        .expand((item) => _flattenStrings(item))
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
  return [value.toString()];
}

List<String> _asPlaceNames(Object? value) {
  if (value is! List) return const [];
  return value
      .map((item) {
        if (item is Map<String, Object?>) return _asString(item['name']);
        return item.toString().trim();
      })
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

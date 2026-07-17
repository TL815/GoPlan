import 'dart:convert';

import '../../../application/assistant/travel_assistant_exception.dart';
import '../../../application/assistant/travel_assistant_failure.dart';
import '../../../domain/assistant/assistant_response.dart';
import '../../../domain/assistant/assistant_status.dart';
import '../../../domain/assistant/ui_action.dart';
import '../../../domain/assistant/ui_action_type.dart';
import '../../../domain/itinerary/itinerary.dart';
import '../../../domain/itinerary/itinerary_day.dart';
import '../../../domain/itinerary/itinerary_item.dart';

class DifyResponseMapper {
  const DifyResponseMapper();

  AssistantResponse mapResponse(Map<String, Object?> response) {
    final topLevelConversationId = _conversationIdFrom(response);
    final answer = response['answer'];
    final answerObject = _parseAnswer(answer);
    final innerConversationId = _conversationIdFrom(answerObject);
    final conversationId = topLevelConversationId ?? innerConversationId;

    if (_looksLikeStandardResponse(answerObject)) {
      return AssistantResponse.fromJson({
        ...answerObject,
        'conversation_id': ?conversationId,
      });
    }

    return _mapLegacyAnswer(answerObject, conversationId: conversationId);
  }

  Map<String, Object?> _parseAnswer(Object? answer) {
    if (answer is Map) return _stringKeyMap(answer);
    if (answer is! String || answer.trim().isEmpty) {
      throw _invalidResponse(
        'Dify answer is missing or has unsupported format.',
      );
    }

    final trimmed = answer.trim();
    final directJson = _tryDecodeObject(trimmed);
    if (directJson != null) return directJson;

    for (final block in _jsonCodeBlocks(trimmed)) {
      final decoded = _tryDecodeObject(block);
      if (decoded != null) return decoded;
    }

    final embeddedJson = _extractFirstJsonObject(trimmed);
    if (embeddedJson != null) {
      final decoded = _tryDecodeObject(embeddedJson);
      if (decoded != null) return decoded;
    }

    return {'replyText': trimmed};
  }

  AssistantResponse _mapLegacyAnswer(
    Map<String, Object?> answer, {
    required String? conversationId,
  }) {
    final planDraft = _stringKeyMapOrNull(answer['planDraft']);
    if (planDraft != null) {
      final itinerary = _itineraryFromPlanDraft(planDraft);
      return AssistantResponse(
        conversationId: conversationId,
        status: AssistantStatus.draft,
        message: _legacyReplyText(answer, fallback: itinerary.title),
        itinerary: itinerary,
        uiAction: UiAction(type: UiActionType.showItinerary),
      );
    }

    final replyText = _legacyReplyText(answer);
    if (_shouldRequestStartDate(answer, replyText)) {
      return AssistantResponse(
        conversationId: conversationId,
        status: AssistantStatus.needInput,
        message: replyText,
        missingFields: const ['start_date'],
        uiAction: UiAction(
          type: UiActionType.requestStartDate,
          field: 'start_date',
          allowCustomInput: true,
        ),
      );
    }

    return AssistantResponse(
      conversationId: conversationId,
      status: AssistantStatus.success,
      message: replyText,
      uiAction: UiAction.none(),
    );
  }

  Itinerary _itineraryFromPlanDraft(Map<String, Object?> json) {
    final daysJson = json['days'];
    if (daysJson is! Iterable || daysJson.isEmpty) {
      throw _invalidResponse('Legacy planDraft.days is missing or invalid.');
    }

    final days = <ItineraryDay>[];
    for (final rawDay in daysJson) {
      if (rawDay is! Map) continue;
      final day = _stringKeyMap(rawDay);
      final places = _stringList(day['places']);
      final food = _stringList(day['food']);
      final notes = _stringValue(
        day['notes'] ?? day['tips'] ?? day['riskNotes'],
      );
      final tips = [
        if (food.isNotEmpty) '餐饮：${food.join('、')}',
        if (notes.isNotEmpty) notes,
      ];
      days.add(
        ItineraryDay(
          dayIndex: _intValue(day['day'], fallback: days.length + 1),
          title: _stringValue(day['title'], fallback: '当天安排'),
          summary: _stringValue(day['route']),
          items: [
            ItineraryItem(
              id: 'legacy_day_${days.length + 1}',
              title: _routeTitleFromPlaces(places, day['title']),
              description: _stringValue(day['transport']),
              tips: tips,
            ),
          ],
        ),
      );
    }

    if (days.isEmpty) {
      throw _invalidResponse('Legacy planDraft.days has no valid entries.');
    }

    final destination = _stringValue(json['destination'], fallback: 'AI 旅行计划');
    final durationDays = _intValue(json['durationDays'], fallback: days.length);
    return Itinerary(
      title: '$destination · $durationDays 天路线',
      destination: destination,
      isDraft: true,
      days: days,
    );
  }

  bool _looksLikeStandardResponse(Map<String, Object?> value) {
    return value.containsKey('schema_version') ||
        value.containsKey('schemaVersion') ||
        value.containsKey('ui_action') ||
        value.containsKey('trip_state') ||
        value.containsKey('itinerary') ||
        _statusValue(value['status']) != null;
  }

  bool _shouldRequestStartDate(Map<String, Object?> answer, String replyText) {
    if (answer['requestStartDate'] == true ||
        answer['request_start_date'] == true) {
      return true;
    }

    final missingSlotText = [
      ..._flattenStrings(answer['missing_slots']),
      ..._flattenStrings(answer['missingSlots']),
    ].join(' ').toLowerCase();
    if (_looksLikeDateSlot(missingSlotText)) return true;

    final extractedSlots = _stringKeyMapOrNull(answer['extractedSlots']);
    if (extractedSlots != null) {
      final startDate =
          extractedSlots['start_date'] ?? extractedSlots['startDate'];
      if (_isEmptySlotValue(startDate)) {
        return _asksForDate(
          [replyText, ..._flattenStrings(answer['nextQuestions'])].join(' '),
        );
      }
    }

    return _asksForDate(
      [replyText, ..._flattenStrings(answer['nextQuestions'])].join(' '),
    );
  }

  String _legacyReplyText(Map<String, Object?> answer, {String fallback = ''}) {
    final replyText = _stringValue(
      answer['replyText'] ?? answer['reply_text'] ?? answer['answer'],
    );
    if (replyText.isNotEmpty) return replyText;
    final questions = _flattenStrings(answer['nextQuestions']);
    if (questions.isNotEmpty) return questions.first;
    return fallback;
  }

  TravelAssistantException _invalidResponse(String message) {
    return TravelAssistantException(
      TravelAssistantFailure.invalidResponse(message: message),
    );
  }

  String? _conversationIdFrom(Map<String, Object?> value) {
    final raw = value['conversation_id'] ?? value['conversationId'];
    final text = raw?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  Map<String, Object?>? _tryDecodeObject(String value) {
    try {
      final decoded = jsonDecode(value);
      return decoded is Map ? _stringKeyMap(decoded) : null;
    } on FormatException {
      return null;
    }
  }

  Iterable<String> _jsonCodeBlocks(String value) sync* {
    final regex = RegExp(r'```(?:json)?\s*([\s\S]*?)```', multiLine: true);
    for (final match in regex.allMatches(value)) {
      final content = match.group(1)?.trim();
      if (content != null && content.isNotEmpty) yield content;
    }
  }

  String? _extractFirstJsonObject(String value) {
    final start = value.indexOf('{');
    if (start < 0) return null;
    var depth = 0;
    var inString = false;
    var escaped = false;
    for (var i = start; i < value.length; i++) {
      final char = value[i];
      if (escaped) {
        escaped = false;
        continue;
      }
      if (char == r'\') {
        escaped = true;
        continue;
      }
      if (char == '"') inString = !inString;
      if (inString) continue;
      if (char == '{') depth += 1;
      if (char == '}') {
        depth -= 1;
        if (depth == 0) return value.substring(start, i + 1);
      }
    }
    return null;
  }

  AssistantStatus? _statusValue(Object? value) {
    final status = assistantStatusFromJson(value);
    return status == AssistantStatus.unknown ? null : status;
  }

  Map<String, Object?> _stringKeyMap(Map value) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }

  Map<String, Object?>? _stringKeyMapOrNull(Object? value) {
    if (value is! Map) return null;
    return _stringKeyMap(value);
  }

  List<String> _stringList(Object? value) {
    if (value is! Iterable) return const [];
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  List<String> _flattenStrings(Object? value) {
    if (value == null) return const [];
    if (value is String) return [value];
    if (value is Iterable) {
      return value
          .expand(_flattenStrings)
          .where((item) => item.isNotEmpty)
          .toList();
    }
    if (value is Map) {
      return value.values
          .expand(_flattenStrings)
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return [value.toString()];
  }

  String _stringValue(Object? value, {String fallback = ''}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  int _intValue(Object? value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  String _routeTitleFromPlaces(List<String> places, Object? fallback) {
    if (places.isNotEmpty) return places.join(' → ');
    return _stringValue(fallback, fallback: '当天路线');
  }

  bool _isEmptySlotValue(Object? value) {
    if (value == null) return true;
    if (value is String) return value.trim().isEmpty;
    if (value is Iterable) return value.isEmpty;
    return false;
  }

  bool _looksLikeDateSlot(String value) {
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
}

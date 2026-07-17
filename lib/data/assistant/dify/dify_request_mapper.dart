import 'dart:convert';

import '../../../domain/assistant/assistant_request.dart';
import '../../../domain/assistant/client_event_type.dart';

class DifyRequestMapper {
  const DifyRequestMapper();

  Map<String, Object?> map(AssistantRequest request) {
    final payload = request.event.payload;
    final inputs = <String, Object?>{
      'trip_id': request.tripId,
      'user_id': request.userId,
      'timezone': request.timezone,
      'client_event': clientEventTypeToJson(request.event.type),
      'backend_snapshot': jsonEncode(request.tripSnapshot),
      if (request.event.field != null && request.event.field!.isNotEmpty)
        'client_field': request.event.field,
      'client_event_payload': jsonEncode(payload),
    };

    for (final entry in payload.entries) {
      if (_reservedInputKeys.contains(entry.key)) continue;
      inputs[entry.key] = _difyInputValue(entry.value);
    }

    final conversationId = request.conversationId?.trim();
    return {
      'inputs': inputs,
      'query': _queryFor(request),
      'response_mode': 'blocking',
      'user': request.userId,
      if (conversationId != null && conversationId.isNotEmpty)
        'conversation_id': conversationId,
    };
  }

  static const _reservedInputKeys = {
    'trip_id',
    'user_id',
    'timezone',
    'client_event',
    'backend_snapshot',
    'client_field',
  };

  Object? _difyInputValue(Object? value) {
    if (value == null || value is String || value is num || value is bool) {
      return value;
    }
    if (value is List || value is Map) return jsonEncode(value);
    return value.toString();
  }

  String _queryFor(AssistantRequest request) {
    final trimmed = request.query.trim();
    if (trimmed.isNotEmpty) return trimmed;

    if (request.event.type == ClientEventType.chatMessage) {
      final message = request.event.payload['message']?.toString().trim();
      if (message != null && message.isNotEmpty) return message;
      return '用户发送了一条旅行消息';
    }

    return switch (request.event.type) {
      ClientEventType.dateSelected => '用户已选择出发日期',
      ClientEventType.dateRangeSelected => '用户已选择旅行日期范围',
      ClientEventType.optionSelected => '用户已选择一个选项',
      ClientEventType.numberSubmitted => '用户已提交数值',
      ClientEventType.confirmationSubmitted => '用户已提交确认结果',
      ClientEventType.dateConflictResolved => '用户已确认日期方案',
      ClientEventType.replacePlace => '用户请求替换行程地点',
      ClientEventType.updateDay => '用户请求调整每日行程',
      ClientEventType.retry => '用户请求重试上一次操作',
      ClientEventType.chatMessage => '用户发送了一条旅行消息',
      ClientEventType.unknown => '用户提交了结构化旅行操作',
    };
  }
}

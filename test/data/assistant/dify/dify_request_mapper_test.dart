import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:goplan/data/assistant/dify/dify_request_mapper.dart';
import 'package:goplan/domain/assistant/assistant_request.dart';
import 'package:goplan/domain/assistant/client_event.dart';
import 'package:goplan/domain/assistant/client_event_type.dart';

void main() {
  const mapper = DifyRequestMapper();

  AssistantRequest request({
    String query = '  帮我规划云南旅行  ',
    String? conversationId,
    ClientEvent? event,
    Map<String, Object?> snapshot = const {'destination': '云南'},
  }) {
    return AssistantRequest(
      userId: 'user_1',
      tripId: 'trip_1',
      conversationId: conversationId,
      query: query,
      event: event ?? ClientEvent.chatMessage('你好'),
      tripSnapshot: snapshot,
    );
  }

  test('maps standard chat_message request body', () {
    final body = mapper.map(request());
    final inputs = body['inputs']! as Map<String, Object?>;

    expect(body['query'], '帮我规划云南旅行');
    expect(body['response_mode'], 'blocking');
    expect(body['user'], 'user_1');
    expect(inputs['trip_id'], 'trip_1');
    expect(inputs['user_id'], 'user_1');
    expect(inputs['timezone'], 'Asia/Shanghai');
    expect(inputs['client_event'], 'chat_message');
    expect(jsonDecode(inputs['backend_snapshot']! as String), {
      'destination': '云南',
    });
  });

  test('omits or includes conversation_id at top level', () {
    expect(mapper.map(request()).containsKey('conversation_id'), isFalse);
    expect(
      mapper.map(request(conversationId: 'conv_1'))['conversation_id'],
      'conv_1',
    );
  });

  test('flattens date selected and date range payload into inputs', () {
    final dateBody = mapper.map(
      request(query: '', event: ClientEvent.dateSelected(DateTime(2026, 8, 3))),
    );
    final dateInputs = dateBody['inputs']! as Map<String, Object?>;

    expect(dateBody['query'], '用户已选择出发日期');
    expect(dateInputs['date'], '2026-08-03');
    expect(dateInputs['client_event'], 'date_selected');

    final rangeBody = mapper.map(
      request(
        query: '',
        event: ClientEvent.dateRangeSelected(
          DateTime(2026, 8, 3),
          DateTime(2026, 8, 9),
        ),
      ),
    );
    final rangeInputs = rangeBody['inputs']! as Map<String, Object?>;

    expect(rangeBody['query'], '用户已选择旅行日期范围');
    expect(rangeInputs['start_date'], '2026-08-03');
    expect(rangeInputs['end_date'], '2026-08-09');
    expect(rangeInputs['client_event'], 'date_range_selected');
  });

  test('serializes complex payload values and protects reserved fields', () {
    final payload = <String, Object?>{
      'trip_id': 'malicious',
      'tags': ['photo', 'food'],
      'meta': {'pace': 'slow'},
      'count': 3,
    };
    final event = ClientEvent(
      type: ClientEventType.optionSelected,
      field: 'preference',
      payload: payload,
    );
    final body = mapper.map(request(query: '', event: event));
    final inputs = body['inputs']! as Map<String, Object?>;

    expect(inputs['trip_id'], 'trip_1');
    expect(inputs['client_field'], 'preference');
    expect(jsonDecode(inputs['tags']! as String), ['photo', 'food']);
    expect(jsonDecode(inputs['meta']! as String), {'pace': 'slow'});
    expect(inputs['count'], 3);
    expect(jsonDecode(inputs['client_event_payload']! as String), payload);
    expect(payload['trip_id'], 'malicious');
  });

  test('generates safe query fallbacks and uses chat message payload', () {
    final chatBody = mapper.map(
      request(query: '', event: ClientEvent.chatMessage('我想去杭州')),
    );
    final numberBody = mapper.map(
      request(
        query: '',
        event: ClientEvent.numberSubmitted(field: 'days', value: 3),
      ),
    );
    final retryBody = mapper.map(
      request(
        query: '',
        event: ClientEvent(type: ClientEventType.retry),
      ),
    );

    expect(chatBody['query'], '我想去杭州');
    expect(numberBody['query'], '用户已提交数值');
    expect(retryBody['query'], '用户请求重试上一次操作');
  });

  test('does not mutate original payload or snapshot', () {
    final snapshot = <String, Object?>{'destination': '云南'};
    final payload = <String, Object?>{'value': 'relaxed'};
    final event = ClientEvent(
      type: ClientEventType.optionSelected,
      payload: payload,
    );

    mapper.map(request(query: '', event: event, snapshot: snapshot));

    expect(snapshot, {'destination': '云南'});
    expect(payload, {'value': 'relaxed'});
  });
}

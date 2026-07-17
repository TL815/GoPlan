import 'package:flutter_test/flutter_test.dart';
import 'package:goplan/domain/assistant/assistant_response.dart';
import 'package:goplan/domain/assistant/assistant_status.dart';
import 'package:goplan/domain/assistant/ui_action_type.dart';

void main() {
  test('parses complete AssistantResponse json', () {
    final response = AssistantResponse.fromJson({
      'schema_version': '1.0',
      'conversation_id': 'conv_01JXYZ',
      'status': 'need_input',
      'message': '请选择旅行日期',
      'missing_fields': ['start_date', 'end_date'],
      'trip_state': {'destination': '云南', 'duration_days': '6'},
      'itinerary': {
        'id': 'it_1',
        'trip_id': 'trip_1',
        'title': '云南6日游',
        'destination': '云南',
        'version': '2',
        'is_draft': true,
        'days': [
          {
            'day_index': 1,
            'date': null,
            'title': '第1天',
            'items': [
              {
                'id': 'item_1',
                'title': '抵达昆明',
                'place': {
                  'id': 'poi_1',
                  'name': '昆明',
                  'latitude': '25.0453',
                  'longitude': '102.7056',
                },
              },
            ],
          },
        ],
        'budget_summary': {'total': '3600', 'currency': 'CNY'},
        'warnings': [
          {
            'id': 'w_1',
            'type': 'weather',
            'message': '雨季注意备伞',
            'severity': 'info',
          },
        ],
      },
      'warnings': [
        {'id': 'w_2', 'type': 'budget', 'message': '预算为估算'},
      ],
      'ui_action': {
        'type': 'request_date_range',
        'field': 'travel_dates',
        'allow_custom_input': true,
        'options': [],
      },
    });

    expect(response.conversationId, 'conv_01JXYZ');
    expect(response.status, AssistantStatus.needInput);
    expect(response.message, '请选择旅行日期');
    expect(response.missingFields, ['start_date', 'end_date']);
    expect(response.tripState?.destination, '云南');
    expect(response.tripState?.durationDays, 6);
    expect(response.itinerary?.version, 2);
    expect(response.itinerary?.days.single.date, isNull);
    expect(
      response.itinerary?.days.single.items.single.place?.latitude,
      25.0453,
    );
    expect(response.uiAction.type, UiActionType.requestDateRange);
  });

  test('parses conversationId from camelCase transition field', () {
    final response = AssistantResponse.fromJson({
      'schema_version': '1.0',
      'conversationId': 'conv_transition',
      'status': 'success',
    });

    expect(response.conversationId, 'conv_transition');
  });

  test('toJson uses conversation_id and never camelCase', () {
    final response = AssistantResponse(
      conversationId: 'conv_snake',
      status: AssistantStatus.success,
    );

    final json = response.toJson();

    expect(json['conversation_id'], 'conv_snake');
    expect(json.containsKey('conversationId'), isFalse);
  });

  test('uses none ui action when ui_action is missing', () {
    final response = AssistantResponse.fromJson({
      'status': 'success',
      'message': 'ok',
    });

    expect(response.conversationId, isNull);
    expect(response.uiAction.type, UiActionType.none);
  });

  test('normalizes empty conversationId to null', () {
    final response = AssistantResponse(
      conversationId: '   ',
      status: AssistantStatus.success,
    );

    expect(response.conversationId, isNull);
    expect(response.toJson().containsKey('conversation_id'), isFalse);
  });

  test('omits conversation_id when null', () {
    final response = AssistantResponse(status: AssistantStatus.success);

    expect(response.conversationId, isNull);
    expect(response.toJson().containsKey('conversation_id'), isFalse);
  });

  test('maps unknown AssistantStatus to unknown', () {
    expect(assistantStatusFromJson('paused'), AssistantStatus.unknown);
  });

  test('throws clear FormatException for invalid itinerary days', () {
    expect(
      () => AssistantResponse.fromJson({
        'status': 'draft',
        'itinerary': {'title': 'bad', 'days': 'not-a-list'},
      }),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('itinerary.days'),
        ),
      ),
    );
  });

  test('round trips core AssistantResponse fields', () {
    final first = AssistantResponse.fromJson({
      'schema_version': '1.0',
      'conversation_id': 'conv_round_trip',
      'status': 'draft',
      'message': '草案已生成',
      'missing_fields': ['budget'],
      'ui_action': {'type': 'show_itinerary'},
    });

    final second = AssistantResponse.fromJson(first.toJson());

    expect(second.schemaVersion, first.schemaVersion);
    expect(second.conversationId, first.conversationId);
    expect(second.status, first.status);
    expect(second.message, first.message);
    expect(second.missingFields, first.missingFields);
    expect(second.uiAction.type, first.uiAction.type);
  });

  test('error status can carry conversationId', () {
    final response = AssistantResponse.fromJson({
      'schema_version': '1.0',
      'conversation_id': 'conv_error',
      'status': 'error',
      'message': '服务可解析的业务错误',
    });

    expect(response.status, AssistantStatus.error);
    expect(response.conversationId, 'conv_error');
  });
}

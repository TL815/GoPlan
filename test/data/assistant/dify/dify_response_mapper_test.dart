import 'package:flutter_test/flutter_test.dart';
import 'package:goplan/application/assistant/travel_assistant_exception.dart';
import 'package:goplan/application/assistant/travel_assistant_failure.dart';
import 'package:goplan/data/assistant/dify/dify_response_mapper.dart';
import 'package:goplan/domain/assistant/assistant_status.dart';
import 'package:goplan/domain/assistant/ui_action_type.dart';

void main() {
  const mapper = DifyResponseMapper();

  test('maps standard AssistantResponse JSON answer', () {
    final response = mapper.mapResponse({
      'conversation_id': 'conv_top',
      'answer': {
        'schema_version': '1.0',
        'conversation_id': 'conv_inner',
        'status': 'need_input',
        'message': '请选择旅行日期',
        'missing_fields': ['start_date', 'end_date'],
        'trip_state': {'destination': '云南', 'duration_days': 6},
        'warnings': [],
        'ui_action': {
          'type': 'request_date_range',
          'field': 'travel_dates',
          'allow_custom_input': true,
          'options': [],
        },
      },
    });

    expect(response.conversationId, 'conv_top');
    expect(response.status, AssistantStatus.needInput);
    expect(response.message, '请选择旅行日期');
    expect(response.tripState?.destination, '云南');
    expect(response.uiAction.type, UiActionType.requestDateRange);
  });

  test('uses inner conversationId when top-level id is missing', () {
    final response = mapper.mapResponse({
      'answer':
          '{"schema_version":"1.0","conversation_id":"conv_inner","status":"success","message":"ok"}',
    });

    expect(response.conversationId, 'conv_inner');
    expect(response.status, AssistantStatus.success);
  });

  test('maps markdown json code block', () {
    final response = mapper.mapResponse({
      'conversationId': 'conv_markdown',
      'answer': '''
```json
{
  "schema_version": "1.0",
  "status": "draft",
  "message": "草案已生成",
  "ui_action": {"type": "show_itinerary"}
}
```
''',
    });

    expect(response.conversationId, 'conv_markdown');
    expect(response.status, AssistantStatus.draft);
    expect(response.uiAction.type, UiActionType.showItinerary);
  });

  test('maps mixed markdown text with embedded json object', () {
    final response = mapper.mapResponse({
      'answer':
          '好的，结果如下：{"schema_version":"1.0","status":"success","message":"已完成"} 后续可继续修改。',
    });

    expect(response.status, AssistantStatus.success);
    expect(response.message, '已完成');
  });

  test('maps plain text answer to success message', () {
    final response = mapper.mapResponse({
      'conversation_id': 'conv_text',
      'answer': '你好，我可以帮你规划旅行。',
    });

    expect(response.conversationId, 'conv_text');
    expect(response.status, AssistantStatus.success);
    expect(response.message, '你好，我可以帮你规划旅行。');
    expect(response.uiAction.type, UiActionType.none);
  });

  test('maps legacy missing date answer to requestStartDate action', () {
    final response = mapper.mapResponse({
      'conversation_id': 'conv_need_date',
      'answer': {
        'replyText': '请选择出发日期',
        'missing_slots': ['start_date'],
        'extractedSlots': {'start_date': ''},
      },
    });

    expect(response.conversationId, 'conv_need_date');
    expect(response.status, AssistantStatus.needInput);
    expect(response.missingFields, ['start_date']);
    expect(response.uiAction.type, UiActionType.requestStartDate);
    expect(response.uiAction.field, 'start_date');
  });

  test('maps legacy planDraft to draft itinerary', () {
    final response = mapper.mapResponse({
      'conversation_id': 'conv_plan',
      'answer': {
        'replyText': '云南 2 天路线已生成',
        'planDraft': {
          'destination': '云南',
          'durationDays': 2,
          'summary': '轻松路线',
          'days': [
            {
              'day': 1,
              'title': '抵达昆明',
              'route': '昆明 → 翠湖',
              'transport': '步行/打车',
              'places': ['昆明', '翠湖公园'],
              'food': ['米线'],
              'notes': '注意防晒',
            },
            {
              'day': 2,
              'title': '大理漫游',
              'route': '大理古城',
              'transport': '公交',
              'places': ['大理古城'],
              'food': [],
            },
          ],
        },
      },
    });

    expect(response.status, AssistantStatus.draft);
    expect(response.message, '云南 2 天路线已生成');
    expect(response.itinerary?.destination, '云南');
    expect(response.itinerary?.isDraft, isTrue);
    expect(response.itinerary?.days, hasLength(2));
    expect(response.itinerary?.days.first.items.single.title, '昆明 → 翠湖公园');
    expect(response.uiAction.type, UiActionType.showItinerary);
  });

  test('throws TravelAssistantException for missing answer', () {
    expect(
      () => mapper.mapResponse({'conversation_id': 'conv_bad'}),
      throwsA(
        isA<TravelAssistantException>()
            .having(
              (error) => error.failure.type,
              'type',
              TravelAssistantFailureType.invalidResponse,
            )
            .having(
              (error) => error.failure.message,
              'message',
              contains('answer'),
            ),
      ),
    );
  });

  test('throws invalidResponse without echoing full answer', () {
    const longAnswer = 'not-json-but-sensitive-secret-token';

    expect(
      () => mapper.mapResponse({'answer': 42, 'debug': longAnswer}),
      throwsA(
        isA<TravelAssistantException>().having(
          (error) => error.toString(),
          'toString',
          isNot(contains(longAnswer)),
        ),
      ),
    );
  });
}

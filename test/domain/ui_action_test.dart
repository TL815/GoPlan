import 'package:flutter_test/flutter_test.dart';
import 'package:goplan/domain/assistant/ui_action.dart';
import 'package:goplan/domain/assistant/ui_action_type.dart';

void main() {
  test('unknown ui action type maps to unknown', () {
    final action = UiAction.fromJson({'type': 'open_portal'});

    expect(action.type, UiActionType.unknown);
  });

  test('request_date_range options parse with fallbacks', () {
    final action = UiAction.fromJson({
      'type': 'request_date_range',
      'field': 'travel_dates',
      'allow_custom_input': true,
      'options': [
        {'label': '国庆假期', 'value': 'golden_week'},
        {'id': 'custom', 'value': '自定义'},
        '周末',
      ],
    });

    expect(action.type, UiActionType.requestDateRange);
    expect(action.allowCustomInput, isTrue);
    expect(action.options[0].id, 'golden_week');
    expect(action.options[0].label, '国庆假期');
    expect(action.options[1].label, '自定义');
    expect(action.options[2].id, '周末');
  });

  test('options and payload cannot be modified externally', () {
    final sourcePayload = {'min': 1};
    final sourceOptions = [
      {'id': 'easy', 'label': '轻松'},
    ];
    final action = UiAction.fromJson({
      'type': 'select_option',
      'payload': sourcePayload,
      'options': sourceOptions,
    });

    sourcePayload['min'] = 2;
    sourceOptions.add({'id': 'busy', 'label': '紧凑'});

    expect(action.payload['min'], 1);
    expect(action.options, hasLength(1));
    expect(() => action.payload['max'] = 3, throwsUnsupportedError);
    expect(
      () => action.options.add(action.options.first),
      throwsUnsupportedError,
    );
  });
}

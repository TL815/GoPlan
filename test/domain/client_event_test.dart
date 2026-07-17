import 'package:flutter_test/flutter_test.dart';
import 'package:goplan/domain/assistant/client_event.dart';
import 'package:goplan/domain/assistant/client_event_type.dart';

void main() {
  test('dateSelected outputs YYYY-MM-DD', () {
    final event = ClientEvent.dateSelected(DateTime(2026, 7, 5));

    expect(event.toJson()['type'], 'date_selected');
    expect(event.toJson()['payload'], containsPair('date', '2026-07-05'));
  });

  test('dateRangeSelected outputs start and end date', () {
    final event = ClientEvent.dateRangeSelected(
      DateTime(2026, 7, 5),
      DateTime(2026, 7, 12),
    );
    final payload = event.toJson()['payload']! as Map<String, Object?>;

    expect(payload['start_date'], '2026-07-05');
    expect(payload['end_date'], '2026-07-12');
  });

  test('fromJson parses ISO occurredAt and protects payload', () {
    final sourcePayload = {'value': 'slow'};
    final event = ClientEvent.fromJson({
      'type': 'option_selected',
      'field': 'pace',
      'payload': sourcePayload,
      'occurred_at': '2026-07-15T08:00:00.000',
    });

    sourcePayload['value'] = 'fast';

    expect(event.type, ClientEventType.optionSelected);
    expect(event.field, 'pace');
    expect(event.payload['value'], 'slow');
    expect(event.occurredAt.year, 2026);
    expect(() => event.payload['value'] = 'fast', throwsUnsupportedError);
  });

  test('named constructors preserve field and value', () {
    final option = ClientEvent.optionSelected(field: 'pace', value: 'relaxed');
    final number = ClientEvent.numberSubmitted(
      field: 'traveler_count',
      value: 3,
    );

    expect(option.toJson()['field'], 'pace');
    expect(option.payload['value'], 'relaxed');
    expect(number.toJson()['type'], 'number_submitted');
    expect(number.payload['value'], 3);
  });
}

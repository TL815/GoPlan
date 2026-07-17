import 'package:flutter_test/flutter_test.dart';
import 'package:goplan/application/assistant/travel_assistant_message.dart';
import 'package:goplan/application/assistant/travel_assistant_message_role.dart';
import 'package:goplan/domain/assistant/assistant_response.dart';
import 'package:goplan/domain/assistant/assistant_status.dart';
import 'package:goplan/domain/assistant/client_event.dart';

void main() {
  test('message stores user event and supports copyWith', () {
    final createdAt = DateTime(2026, 7, 15, 9);
    final event = ClientEvent.chatMessage('hello');
    final message = TravelAssistantMessage(
      id: 'message_1',
      role: TravelAssistantMessageRole.user,
      text: 'hello',
      createdAt: createdAt,
      event: event,
    );

    final copied = message.copyWith(text: 'updated', event: null);

    expect(message.role, TravelAssistantMessageRole.user);
    expect(message.response, isNull);
    expect(copied.id, 'message_1');
    expect(copied.text, 'updated');
    expect(copied.event, isNull);
  });

  test('assistant message can carry response', () {
    final response = AssistantResponse(
      status: AssistantStatus.success,
      message: 'done',
    );
    final message = TravelAssistantMessage(
      id: 'message_2',
      role: TravelAssistantMessageRole.assistant,
      text: response.message,
      createdAt: DateTime(2026, 7, 15, 9),
      response: response,
    );

    expect(message.response, same(response));
    expect(message.event, isNull);
  });
}

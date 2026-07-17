import 'package:flutter_test/flutter_test.dart';
import 'package:goplan/application/assistant/conversation/assistant_message_snapshot.dart';
import 'package:goplan/application/assistant/travel_assistant_message.dart';
import 'package:goplan/application/assistant/travel_assistant_message_role.dart';
import 'package:goplan/domain/assistant/client_event.dart';
import 'package:goplan/domain/assistant/client_event_type.dart';

void main() {
  final fixedNow = DateTime(2026, 7, 16, 9);

  test('user message serializes and restores with event', () {
    final snapshot = AssistantMessageSnapshot.fromMessage(
      TravelAssistantMessage(
        id: 'message_7',
        role: TravelAssistantMessageRole.user,
        text: 'hello',
        createdAt: fixedNow,
        event: ClientEvent(
          type: ClientEventType.chatMessage,
          field: 'message',
          payload: const {'message': 'hello'},
          occurredAt: fixedNow,
        ),
      ),
    );

    final restored = AssistantMessageSnapshot.fromJson(snapshot.toJson());

    expect(restored.id, 'message_7');
    expect(restored.role, TravelAssistantMessageRole.user);
    expect(restored.event!.type, ClientEventType.chatMessage);
    expect(restored.toMessage().id, 'message_7');
  });

  test('assistant message serializes without response payload', () {
    final snapshot = AssistantMessageSnapshot.fromMessage(
      TravelAssistantMessage(
        id: 'assistant_custom',
        role: TravelAssistantMessageRole.assistant,
        text: 'done',
        createdAt: fixedNow,
      ),
    );

    final json = snapshot.toJson();

    expect(json['role'], 'assistant');
    expect(json.containsKey('response'), isFalse);
    expect(json.containsKey('conversation_id'), isFalse);
  });

  test('unknown role throws FormatException', () {
    expect(
      () => AssistantMessageSnapshot.fromJson({
        'id': 'message_1',
        'role': 'system',
        'text': 'bad',
        'created_at': fixedNow.toIso8601String(),
      }),
      throwsFormatException,
    );
  });
}

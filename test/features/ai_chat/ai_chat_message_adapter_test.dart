import 'package:flutter_test/flutter_test.dart';
import 'package:goplan/application/assistant/travel_assistant_message.dart';
import 'package:goplan/application/assistant/travel_assistant_message_role.dart';
import 'package:goplan/features/ai_chat/ai_chat_message_adapter.dart';

void main() {
  final fixedNow = DateTime(2026, 7, 16, 9);

  test('maps user message without changing id or text', () {
    final data = AiChatMessageAdapter.fromMessage(
      TravelAssistantMessage(
        id: 'message_1',
        role: TravelAssistantMessageRole.user,
        text: 'hello',
        createdAt: fixedNow,
      ),
    );

    expect(data.id, 'message_1');
    expect(data.text, 'hello');
    expect(data.isUser, isTrue);
  });

  test('maps assistant message without reading raw response json', () {
    final data = AiChatMessageAdapter.fromMessage(
      TravelAssistantMessage(
        id: 'message_2',
        role: TravelAssistantMessageRole.assistant,
        text: 'assistant reply',
        createdAt: fixedNow,
      ),
    );

    expect(data.id, 'message_2');
    expect(data.text, 'assistant reply');
    expect(data.isUser, isFalse);
  });
}

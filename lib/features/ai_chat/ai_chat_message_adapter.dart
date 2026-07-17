import 'package:goplan/application/assistant/travel_assistant_message.dart';
import 'package:goplan/application/assistant/travel_assistant_message_role.dart';

class AiChatMessageViewData {
  const AiChatMessageViewData({
    required this.id,
    required this.text,
    required this.isUser,
  });

  final String id;
  final String text;
  final bool isUser;
}

class AiChatMessageAdapter {
  const AiChatMessageAdapter._();

  static AiChatMessageViewData fromMessage(TravelAssistantMessage message) {
    return AiChatMessageViewData(
      id: message.id,
      text: message.text,
      isUser: message.role == TravelAssistantMessageRole.user,
    );
  }
}

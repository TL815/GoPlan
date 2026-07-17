import 'ai_chat_launch_mode.dart';

class AiChatLaunchRequest {
  const AiChatLaunchRequest.resumeLatestForTrip()
    : mode = AiChatLaunchMode.resumeLatestForTrip,
      localConversationId = null;

  const AiChatLaunchRequest.newConversation()
    : mode = AiChatLaunchMode.newConversation,
      localConversationId = null;

  AiChatLaunchRequest.resumeById(String id)
    : mode = AiChatLaunchMode.resumeById,
      localConversationId = _normalizeId(id);

  final AiChatLaunchMode mode;
  final String? localConversationId;

  static String _normalizeId(String id) {
    final trimmed = id.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(id, 'id', 'must not be empty');
    }
    return trimmed;
  }
}

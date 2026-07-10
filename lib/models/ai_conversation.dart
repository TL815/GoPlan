import '../ai_travel_agent_models.dart';

/// AI 对话记录 — 保存到探索页的每条对话
class AiConversation {
  AiConversation({
    required this.id,
    required this.title,
    required this.userQuery,
    required this.createdAt,
    required List<ConvMessage> messages,
    this.result,
    this.isPinned = false,
  }) : _messages = messages;

  final String id;
  String title;
  final String userQuery;
  final DateTime createdAt;
  TravelAgentResult? result;
  bool isPinned;

  final List<ConvMessage> _messages;
  List<ConvMessage> get messages => List.unmodifiable(_messages);

  /// 追加消息（内部使用）
  void appendMessages(List<ConvMessage> msgs) {
    _messages.addAll(msgs);
  }

  String get subtitle {
    if (result != null) {
      return '${result!.destination} · ${result!.durationDays}天 · ${result!.days.length}个行程';
    }
    return '对话记录';
  }
}

class ConvMessage {
  const ConvMessage({required this.role, required this.content});
  final String role; // 'user' | 'assistant'
  final String content;
}

/// 从 AI 对话结果生成标题
String generateConversationTitle({
  required String userQuery,
  TravelAgentResult? result,
}) {
  if (result != null) {
    return '${result.destination} · ${result.durationDays}天';
  }
  // 从用户查询中截取前15个字符作为标题
  final trimmed = userQuery.trim();
  if (trimmed.length <= 15) return trimmed;
  return '${trimmed.substring(0, 15)}...';
}

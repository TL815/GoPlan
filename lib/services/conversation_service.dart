import 'package:flutter/foundation.dart';
import '../models/ai_conversation.dart';
import '../ai_travel_agent_models.dart';

/// 全局对话管理服务 — 单例，保存所有 AI 对话记录
class ConversationService extends ChangeNotifier {
  ConversationService._();

  static final ConversationService _instance = ConversationService._();
  static ConversationService get instance => _instance;

  final List<AiConversation> _conversations = [];
  List<AiConversation> get conversations => List.unmodifiable(_conversations);

  /// 根据 ID 查找对话
  AiConversation? findById(String id) {
    try {
      return _conversations.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// 保存一次 AI 对话 — 插入到置顶项之后、普通项之前
  AiConversation addConversation({
    required String userQuery,
    required List<ConvMessage> messages,
    TravelAgentResult? result,
  }) {
    final title = generateConversationTitle(
      userQuery: userQuery,
      result: result,
    );
    final conversation = AiConversation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      userQuery: userQuery,
      createdAt: DateTime.now(),
      messages: messages,
      result: result,
    );
    final pinCount = _conversations.where((c) => c.isPinned).length;
    _conversations.insert(pinCount, conversation);
    notifyListeners();
    return conversation;
  }

  /// 追加消息到已有对话
  void appendToConversation(
    String id, {
    required List<ConvMessage> messages,
    TravelAgentResult? result,
  }) {
    final conv = findById(id);
    if (conv == null) return;
    conv.appendMessages(messages);
    if (result != null) {
      conv.result = result;
    }
    notifyListeners();
  }

  /// 删除一条对话
  void removeConversation(String id) {
    _conversations.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  /// 切换置顶状态
  void togglePinConversation(String id) {
    final index = _conversations.indexWhere((c) => c.id == id);
    if (index < 0) return;
    final conv = _conversations[index];
    if (conv.isPinned) {
      // 取消置顶 → 移到所有非置顶项的最前面
      conv.isPinned = false;
      _conversations.removeAt(index);
      final pinCount = _conversations.where((c) => c.isPinned).length;
      _conversations.insert(pinCount, conv);
    } else {
      // 置顶 → 移到所有置顶项的最后面
      conv.isPinned = true;
      _conversations.removeAt(index);
      final pinCount = _conversations.where((c) => c.isPinned).length;
      _conversations.insert(pinCount, conv);
    }
    notifyListeners();
  }

  /// 重命名对话标题
  void renameConversation(String id, String newTitle) {
    final conv = findById(id);
    if (conv == null || newTitle.trim().isEmpty) return;
    conv.title = newTitle.trim();
    notifyListeners();
  }
}

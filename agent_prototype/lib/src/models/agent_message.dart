class AgentMessage {
  AgentMessage({
    required this.role,
    required this.content,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  final AgentMessageRole role;
  final String content;
  final DateTime createdAt;
}

enum AgentMessageRole { user, assistant, tool }

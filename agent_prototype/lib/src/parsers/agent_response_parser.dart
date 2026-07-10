import 'dart:convert';

import '../agent_exception.dart';

class AgentResponseParser {
  const AgentResponseParser();

  Map<String, Object?> parseJsonObject(String content) {
    final normalized = _stripCodeFence(content);
    final decoded = jsonDecode(normalized);
    if (decoded is Map<String, Object?>) return decoded;
    throw const AgentException('LLM response root is not a JSON object.');
  }

  String _stripCodeFence(String value) {
    final trimmed = value.trim();
    if (!trimmed.startsWith('```')) return trimmed;
    return trimmed
        .replaceFirst(RegExp(r'^```(?:json)?\s*', multiLine: true), '')
        .replaceFirst(RegExp(r'\s*```$', multiLine: true), '')
        .trim();
  }
}

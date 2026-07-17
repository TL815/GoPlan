import 'dart:convert';

import '../../../application/assistant/conversation/assistant_conversation_snapshot.dart';
import '../../../application/assistant/conversation/conversation_store_exception.dart';

// ignore_for_file: prefer_initializing_formals

class ConversationJsonDocument {
  ConversationJsonDocument({
    this.schemaVersion = currentSchemaVersion,
    List<AssistantConversationSnapshot> conversations = const [],
  }) : conversations = List.unmodifiable(conversations);

  factory ConversationJsonDocument.empty() {
    return ConversationJsonDocument();
  }

  factory ConversationJsonDocument.decode(String source) {
    Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException catch (error) {
      throw ConversationStoreException(
        type: ConversationStoreFailureType.invalidData,
        message: 'Stored conversation document is not valid JSON.',
        cause: error,
      );
    }

    if (decoded is! Map) {
      throw const ConversationStoreException(
        type: ConversationStoreFailureType.invalidData,
        message: 'Stored conversation document must be an object.',
      );
    }
    return ConversationJsonDocument.fromJson(
      decoded.map((key, value) => MapEntry(key.toString(), value)),
    );
  }

  factory ConversationJsonDocument.fromJson(Map<String, Object?> json) {
    final version = _parseVersion(json['schema_version']);
    if (version > currentSchemaVersion) {
      throw ConversationStoreException(
        type: ConversationStoreFailureType.unsupportedVersion,
        message: 'Stored conversation schema version is not supported.',
      );
    }

    final rawConversations = json['conversations'];
    if (rawConversations == null) {
      return ConversationJsonDocument(schemaVersion: version);
    }
    if (rawConversations is! Iterable) {
      throw const ConversationStoreException(
        type: ConversationStoreFailureType.invalidData,
        message: 'Stored conversation list is invalid.',
      );
    }

    final conversations = <AssistantConversationSnapshot>[];
    for (final item in rawConversations) {
      if (item is! Map) continue;
      try {
        conversations.add(
          AssistantConversationSnapshot.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        );
      } on Object {
        continue;
      }
    }

    return ConversationJsonDocument(
      schemaVersion: version,
      conversations: conversations,
    );
  }

  static const currentSchemaVersion = 1;

  final int schemaVersion;
  final List<AssistantConversationSnapshot> conversations;

  String encode() {
    return jsonEncode(toJson());
  }

  Map<String, Object?> toJson() => {
    'schema_version': currentSchemaVersion,
    'conversations': conversations
        .map((conversation) => conversation.toJson())
        .toList(),
  };

  ConversationJsonDocument copyWith({
    List<AssistantConversationSnapshot>? conversations,
  }) {
    return ConversationJsonDocument(
      schemaVersion: currentSchemaVersion,
      conversations: conversations ?? this.conversations,
    );
  }

  static int _parseVersion(Object? value) {
    if (value == null) return currentSchemaVersion;
    if (value is int) return value;
    if (value is num) return value.toInt();
    throw const ConversationStoreException(
      type: ConversationStoreFailureType.invalidData,
      message: 'Stored conversation schema version is invalid.',
    );
  }
}

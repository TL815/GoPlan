// ignore_for_file: prefer_initializing_formals

import 'package:goplan/application/assistant/conversation/assistant_conversation_snapshot.dart';
import 'package:goplan/application/assistant/conversation/conversation_store.dart';
import 'package:goplan/application/assistant/conversation/conversation_store_exception.dart';
import 'package:goplan/features/ai_chat/ai_chat_runtime_config.dart';

import 'ai_chat_launch_mode.dart';
import 'ai_chat_launch_request.dart';
import 'local_conversation_id_generator.dart';

class AiChatSessionBootstrap {
  AiChatSessionBootstrap({
    required ConversationStore store,
    required LocalConversationIdGenerator idGenerator,
    DateTime Function()? now,
  }) : _store = store,
       _idGenerator = idGenerator,
       _now = now ?? DateTime.now;

  final ConversationStore _store;
  final LocalConversationIdGenerator _idGenerator;
  final DateTime Function() _now;

  Future<AiChatBootstrapResult> load({
    required AiChatRuntimeConfig config,
    required AiChatLaunchRequest request,
  }) async {
    try {
      switch (request.mode) {
        case AiChatLaunchMode.newConversation:
          return _newConversation();
        case AiChatLaunchMode.resumeLatestForTrip:
          final snapshot = await _store.getLatestForTrip(
            userId: config.userId,
            tripId: config.tripId,
          );
          if (snapshot == null) return _newConversation();
          return _fromSnapshot(snapshot);
        case AiChatLaunchMode.resumeById:
          final id = request.localConversationId;
          if (id == null || id.isEmpty) {
            throw const AiChatBootstrapException.notFound();
          }
          final snapshot = await _store.getById(id);
          if (snapshot == null) throw const AiChatBootstrapException.notFound();
          return _fromSnapshot(snapshot);
      }
    } on AiChatBootstrapException {
      rethrow;
    } on ConversationStoreException catch (error) {
      throw AiChatBootstrapException.storeReadFailed(error);
    }
  }

  AiChatBootstrapResult _newConversation() {
    return AiChatBootstrapResult(
      localConversationId: _idGenerator.generate(),
      createdAt: _now(),
      snapshot: null,
      isNewConversation: true,
    );
  }

  AiChatBootstrapResult _fromSnapshot(AssistantConversationSnapshot snapshot) {
    return AiChatBootstrapResult(
      localConversationId: snapshot.id,
      createdAt: snapshot.createdAt,
      snapshot: snapshot,
      isNewConversation: false,
    );
  }
}

class AiChatBootstrapResult {
  const AiChatBootstrapResult({
    required this.localConversationId,
    required this.createdAt,
    required this.snapshot,
    required this.isNewConversation,
  });

  final String localConversationId;
  final DateTime createdAt;
  final AssistantConversationSnapshot? snapshot;
  final bool isNewConversation;
}

class AiChatBootstrapException implements Exception {
  const AiChatBootstrapException({required this.type, this.storeException});

  const AiChatBootstrapException.notFound()
    : type = AiChatBootstrapFailureType.notFound,
      storeException = null;

  const AiChatBootstrapException.storeReadFailed(
    ConversationStoreException error,
  ) : type = AiChatBootstrapFailureType.storeReadFailed,
      storeException = error;

  final AiChatBootstrapFailureType type;
  final ConversationStoreException? storeException;

  @override
  String toString() => 'AiChatBootstrapException(type: $type)';
}

enum AiChatBootstrapFailureType { notFound, storeReadFailed }

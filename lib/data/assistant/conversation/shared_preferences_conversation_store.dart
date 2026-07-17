import '../../../application/assistant/conversation/assistant_conversation_snapshot.dart';
import '../../../application/assistant/conversation/assistant_conversation_summary.dart';
import '../../../application/assistant/conversation/conversation_store.dart';
import '../../../application/assistant/conversation/conversation_store_exception.dart';
import 'conversation_json_document.dart';
import 'shared_preferences_string_store.dart';

// ignore_for_file: prefer_initializing_formals

class SharedPreferencesConversationStore implements ConversationStore {
  SharedPreferencesConversationStore({
    required StringStore stringStore,
    this.storageKey = defaultStorageKey,
  }) : _stringStore = stringStore;

  factory SharedPreferencesConversationStore.production({
    String storageKey = defaultStorageKey,
  }) {
    return SharedPreferencesConversationStore(
      stringStore: SharedPreferencesStringStore(),
      storageKey: storageKey,
    );
  }

  static const defaultStorageKey = 'goplan.assistant_conversations.v1';

  final StringStore _stringStore;
  final String storageKey;
  Future<void> _writeQueue = Future<void>.value();

  @override
  Future<void> save(AssistantConversationSnapshot conversation) {
    return _enqueueWrite(() async {
      final document = await _readDocument();
      final conversations = <AssistantConversationSnapshot>[];
      var replaced = false;

      for (final existing in document.conversations) {
        if (existing.id == conversation.id) {
          conversations.add(
            conversation.copyWith(createdAt: existing.createdAt),
          );
          replaced = true;
        } else {
          conversations.add(existing);
        }
      }
      if (!replaced) {
        conversations.add(conversation);
      }

      await _writeDocument(document.copyWith(conversations: conversations));
    });
  }

  @override
  Future<AssistantConversationSnapshot?> getById(String id) async {
    final document = await _readDocument();
    for (final conversation in document.conversations) {
      if (conversation.id == id) return conversation;
    }
    return null;
  }

  @override
  Future<AssistantConversationSnapshot?> getLatestForTrip({
    required String userId,
    required String tripId,
  }) async {
    final matches = (await _readDocument()).conversations.where(
      (conversation) =>
          conversation.userId == userId && conversation.tripId == tripId,
    );
    return _latest(matches);
  }

  @override
  Future<List<AssistantConversationSummary>> listForUser(String userId) async {
    final summaries =
        (await _readDocument()).conversations
            .where((conversation) => conversation.userId == userId)
            .map(AssistantConversationSummary.fromSnapshot)
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return List.unmodifiable(summaries);
  }

  @override
  Future<void> delete(String id) {
    return _enqueueWrite(() async {
      final document = await _readDocument();
      final conversations = document.conversations
          .where((conversation) => conversation.id != id)
          .toList();
      await _writeDocument(document.copyWith(conversations: conversations));
    });
  }

  @override
  Future<void> clearForUser(String userId) {
    return _enqueueWrite(() async {
      final document = await _readDocument();
      final conversations = document.conversations
          .where((conversation) => conversation.userId != userId)
          .toList();
      await _writeDocument(document.copyWith(conversations: conversations));
    });
  }

  Future<void> _enqueueWrite(Future<void> Function() operation) {
    final next = _writeQueue.then((_) => operation());
    _writeQueue = next.catchError((_) {});
    return next;
  }

  Future<ConversationJsonDocument> _readDocument() async {
    try {
      final value = await _stringStore.getString(storageKey);
      if (value == null || value.trim().isEmpty) {
        return ConversationJsonDocument.empty();
      }
      return ConversationJsonDocument.decode(value);
    } on ConversationStoreException {
      rethrow;
    } on Object catch (error) {
      throw ConversationStoreException(
        type: ConversationStoreFailureType.readFailed,
        message: 'Could not read stored conversations.',
        cause: error,
      );
    }
  }

  Future<void> _writeDocument(ConversationJsonDocument document) async {
    try {
      await _stringStore.setString(storageKey, document.encode());
    } on ConversationStoreException {
      rethrow;
    } on Object catch (error) {
      throw ConversationStoreException(
        type: ConversationStoreFailureType.writeFailed,
        message: 'Could not write stored conversations.',
        cause: error,
      );
    }
  }

  AssistantConversationSnapshot? _latest(
    Iterable<AssistantConversationSnapshot> conversations,
  ) {
    AssistantConversationSnapshot? latest;
    for (final conversation in conversations) {
      if (latest == null || conversation.updatedAt.isAfter(latest.updatedAt)) {
        latest = conversation;
      }
    }
    return latest;
  }
}

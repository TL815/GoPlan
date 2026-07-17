import 'package:flutter_test/flutter_test.dart';
import 'package:goplan/application/assistant/conversation/assistant_conversation_snapshot.dart';
import 'package:goplan/application/assistant/conversation/assistant_conversation_summary.dart';
import 'package:goplan/application/assistant/conversation/assistant_message_snapshot.dart';
import 'package:goplan/application/assistant/conversation/conversation_store.dart';
import 'package:goplan/application/assistant/conversation/conversation_store_exception.dart';
import 'package:goplan/application/assistant/travel_assistant_message_role.dart';
import 'package:goplan/features/ai_chat/ai_chat_runtime_config.dart';
import 'package:goplan/features/ai_chat/conversation/ai_chat_launch_mode.dart';
import 'package:goplan/features/ai_chat/conversation/ai_chat_launch_request.dart';
import 'package:goplan/features/ai_chat/conversation/ai_chat_session_bootstrap.dart';
import 'package:goplan/features/ai_chat/conversation/local_conversation_id_generator.dart';

void main() {
  const config = AiChatRuntimeConfig(
    userId: 'user_1',
    tripId: 'trip_1',
    timezone: 'Asia/Shanghai',
  );
  final now = DateTime(2026, 7, 17, 10);

  test('launch requests trim resume ids and reject empty ids', () {
    expect(
      const AiChatLaunchRequest.resumeLatestForTrip().mode,
      AiChatLaunchMode.resumeLatestForTrip,
    );
    expect(
      AiChatLaunchRequest.resumeById(' local_1 ').localConversationId,
      'local_1',
    );
    expect(() => AiChatLaunchRequest.resumeById(' '), throwsArgumentError);
  });

  test(
    'newConversation does not read store and generates one local id',
    () async {
      final store = _FakeConversationStore();
      final ids = _FixedIdGenerator(['local_new']);
      final bootstrap = AiChatSessionBootstrap(
        store: store,
        idGenerator: ids,
        now: () => now,
      );

      final result = await bootstrap.load(
        config: config,
        request: const AiChatLaunchRequest.newConversation(),
      );

      expect(result.localConversationId, 'local_new');
      expect(result.createdAt, now);
      expect(result.snapshot, isNull);
      expect(result.isNewConversation, isTrue);
      expect(ids.callCount, 1);
      expect(store.getLatestForTripCount, 0);
      expect(store.getByIdCount, 0);
    },
  );

  test('resumeLatestForTrip restores matching latest snapshot', () async {
    final snapshot = _snapshot(id: 'local_existing', updatedAt: now);
    final store = _FakeConversationStore(latest: snapshot);
    final bootstrap = AiChatSessionBootstrap(
      store: store,
      idGenerator: _FixedIdGenerator(['unused']),
    );

    final result = await bootstrap.load(
      config: config,
      request: const AiChatLaunchRequest.resumeLatestForTrip(),
    );

    expect(result.localConversationId, 'local_existing');
    expect(result.createdAt, snapshot.createdAt);
    expect(result.snapshot, same(snapshot));
    expect(result.isNewConversation, isFalse);
    expect(store.latestUserId, 'user_1');
    expect(store.latestTripId, 'trip_1');
  });

  test(
    'resumeLatestForTrip creates new conversation when none exists',
    () async {
      final bootstrap = AiChatSessionBootstrap(
        store: _FakeConversationStore(),
        idGenerator: _FixedIdGenerator(['local_fallback']),
        now: () => now,
      );

      final result = await bootstrap.load(
        config: config,
        request: const AiChatLaunchRequest.resumeLatestForTrip(),
      );

      expect(result.localConversationId, 'local_fallback');
      expect(result.isNewConversation, isTrue);
    },
  );

  test(
    'resumeById restores exact snapshot and does not create fallback',
    () async {
      final snapshot = _snapshot(id: 'local_resume', updatedAt: now);
      final ids = _FixedIdGenerator(['should_not_use']);
      final bootstrap = AiChatSessionBootstrap(
        store: _FakeConversationStore(byId: {'local_resume': snapshot}),
        idGenerator: ids,
      );

      final result = await bootstrap.load(
        config: config,
        request: AiChatLaunchRequest.resumeById('local_resume'),
      );

      expect(result.snapshot, same(snapshot));
      expect(result.localConversationId, 'local_resume');
      expect(ids.callCount, 0);
    },
  );

  test('resumeById missing is an explicit bootstrap failure', () async {
    final bootstrap = AiChatSessionBootstrap(
      store: _FakeConversationStore(),
      idGenerator: _FixedIdGenerator(['unused']),
    );

    expect(
      () => bootstrap.load(
        config: config,
        request: AiChatLaunchRequest.resumeById('missing'),
      ),
      throwsA(
        isA<AiChatBootstrapException>().having(
          (error) => error.type,
          'type',
          AiChatBootstrapFailureType.notFound,
        ),
      ),
    );
  });

  test('store read failures are not treated as empty history', () async {
    final bootstrap = AiChatSessionBootstrap(
      store: _FakeConversationStore(throwOnLatest: true),
      idGenerator: _FixedIdGenerator(['unused']),
    );

    expect(
      () => bootstrap.load(
        config: config,
        request: const AiChatLaunchRequest.resumeLatestForTrip(),
      ),
      throwsA(
        isA<AiChatBootstrapException>().having(
          (error) => error.type,
          'type',
          AiChatBootstrapFailureType.storeReadFailed,
        ),
      ),
    );
  });

  test('secure id generator uses GoPlan local prefix', () {
    final id = SecureLocalConversationIdGenerator(now: () => now).generate();

    expect(id, startsWith('goplan_conv_${now.microsecondsSinceEpoch}_'));
  });
}

AssistantConversationSnapshot _snapshot({
  required String id,
  required DateTime updatedAt,
}) {
  return AssistantConversationSnapshot(
    id: id,
    userId: 'user_1',
    tripId: 'trip_1',
    conversationId: 'provider_1',
    createdAt: DateTime(2026, 7, 1),
    updatedAt: updatedAt,
    messages: [
      AssistantMessageSnapshot(
        id: 'message_1',
        role: TravelAssistantMessageRole.user,
        text: 'hello',
        createdAt: updatedAt,
      ),
    ],
  );
}

class _FixedIdGenerator implements LocalConversationIdGenerator {
  _FixedIdGenerator(this.ids);

  final List<String> ids;
  int callCount = 0;

  @override
  String generate() {
    callCount += 1;
    return ids.removeAt(0);
  }
}

class _FakeConversationStore implements ConversationStore {
  _FakeConversationStore({
    this.latest,
    Map<String, AssistantConversationSnapshot>? byId,
    this.throwOnLatest = false,
  }) : byId = byId ?? {};

  final AssistantConversationSnapshot? latest;
  final Map<String, AssistantConversationSnapshot> byId;
  final bool throwOnLatest;
  int getLatestForTripCount = 0;
  int getByIdCount = 0;
  String? latestUserId;
  String? latestTripId;

  @override
  Future<void> save(AssistantConversationSnapshot conversation) async {}

  @override
  Future<AssistantConversationSnapshot?> getById(String id) async {
    getByIdCount += 1;
    return byId[id];
  }

  @override
  Future<AssistantConversationSnapshot?> getLatestForTrip({
    required String userId,
    required String tripId,
  }) async {
    getLatestForTripCount += 1;
    latestUserId = userId;
    latestTripId = tripId;
    if (throwOnLatest) {
      throw const ConversationStoreException(
        type: ConversationStoreFailureType.readFailed,
        message: 'safe',
      );
    }
    return latest;
  }

  @override
  Future<List<AssistantConversationSummary>> listForUser(String userId) async {
    return const [];
  }

  @override
  Future<void> delete(String id) async {}

  @override
  Future<void> clearForUser(String userId) async {}
}

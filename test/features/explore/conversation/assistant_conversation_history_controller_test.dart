import 'package:flutter_test/flutter_test.dart';
import 'package:goplan/application/assistant/conversation/assistant_conversation_snapshot.dart';
import 'package:goplan/application/assistant/conversation/assistant_conversation_summary.dart';
import 'package:goplan/application/assistant/conversation/conversation_store.dart';
import 'package:goplan/features/explore/conversation/assistant_conversation_history_controller.dart';
import 'package:goplan/features/explore/conversation/assistant_conversation_history_state.dart';

void main() {
  test('loads summaries for user from ConversationStore', () async {
    final store = _HistoryStore([
      AssistantConversationSummary(
        id: 'local_1',
        userId: 'user_1',
        tripId: 'trip_1',
        title: 'Trip',
        destination: 'Hangzhou',
        updatedAt: DateTime(2026, 7, 17),
        messageCount: 2,
        hasItinerary: true,
      ),
    ]);
    final controller = AssistantConversationHistoryController(
      store: store,
      userId: 'user_1',
    );
    addTearDown(controller.dispose);

    await controller.load();

    expect(store.requestedUserIds, ['user_1']);
    expect(controller.state.phase, AssistantConversationHistoryPhase.ready);
    expect(controller.state.summaries.single.id, 'local_1');
  });

  test('read errors become safe failure state', () async {
    final controller = AssistantConversationHistoryController(
      store: _HistoryStore(const [], throwOnList: true),
      userId: 'user_1',
    );
    addTearDown(controller.dispose);

    await controller.load();

    expect(controller.state.phase, AssistantConversationHistoryPhase.failure);
    expect(controller.state.summaries, isEmpty);
  });
}

class _HistoryStore implements ConversationStore {
  _HistoryStore(this.summaries, {this.throwOnList = false});

  final List<AssistantConversationSummary> summaries;
  final bool throwOnList;
  final List<String> requestedUserIds = [];

  @override
  Future<List<AssistantConversationSummary>> listForUser(String userId) async {
    requestedUserIds.add(userId);
    if (throwOnList) throw StateError('boom');
    return summaries;
  }

  @override
  Future<void> save(AssistantConversationSnapshot conversation) async {}

  @override
  Future<AssistantConversationSnapshot?> getById(String id) async => null;

  @override
  Future<AssistantConversationSnapshot?> getLatestForTrip({
    required String userId,
    required String tripId,
  }) async => null;

  @override
  Future<void> delete(String id) async {}

  @override
  Future<void> clearForUser(String userId) async {}
}

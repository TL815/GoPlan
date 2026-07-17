import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:goplan/application/assistant/conversation/assistant_conversation_snapshot.dart';
import 'package:goplan/application/assistant/conversation/assistant_conversation_summary.dart';
import 'package:goplan/application/assistant/conversation/conversation_store.dart';
import 'package:goplan/application/assistant/conversation/conversation_store_exception.dart';
import 'package:goplan/application/assistant/conversation/travel_assistant_session_mapper.dart';
import 'package:goplan/application/assistant/travel_assistant_controller.dart';
import 'package:goplan/application/assistant/travel_assistant_exception.dart';
import 'package:goplan/application/assistant/travel_assistant_failure.dart';
import 'package:goplan/application/assistant/travel_assistant_phase.dart';
import 'package:goplan/domain/assistant/assistant_response.dart';
import 'package:goplan/domain/assistant/assistant_status.dart';
import 'package:goplan/features/ai_chat/conversation/ai_chat_persistence_coordinator.dart';

import '../../../helpers/fake_travel_assistant_gateway.dart';

void main() {
  final createdAt = DateTime(2026, 7, 1);
  final updatedAt = DateTime(2026, 7, 17);

  test('blank initial conversation is not saved on flush', () async {
    final store = _RecordingConversationStore();
    final controller = _controller();
    addTearDown(controller.dispose);
    final coordinator = _coordinator(
      controller: controller,
      store: store,
      createdAt: createdAt,
      now: () => updatedAt,
    )..start();
    addTearDown(coordinator.dispose);

    await coordinator.flush();

    expect(store.saved, isEmpty);
  });

  test('user and assistant messages are saved with stable local id', () async {
    final store = _RecordingConversationStore();
    final controller = _controller(
      gateway: FakeTravelAssistantGateway(
        response: AssistantResponse(
          conversationId: 'provider_1',
          status: AssistantStatus.success,
          message: 'assistant reply',
        ),
      ),
    );
    final coordinator = _coordinator(
      controller: controller,
      store: store,
      createdAt: createdAt,
      now: () => updatedAt,
      debounceDuration: Duration.zero,
    )..start();
    addTearDown(coordinator.dispose);

    await controller.sendMessage('hello');
    await coordinator.flush();

    expect(store.saved, hasLength(1));
    final snapshot = store.saved.single;
    expect(snapshot.id, 'local_1');
    expect(snapshot.conversationId, 'provider_1');
    expect(snapshot.createdAt, createdAt);
    expect(snapshot.updatedAt, updatedAt);
    expect(snapshot.messages.map((m) => m.text), ['hello', 'assistant reply']);
  });

  test('debounce and flush keep the final state only', () async {
    final store = _RecordingConversationStore();
    final controller = _controller(
      gateway: FakeTravelAssistantGateway(
        responseQueue: [
          AssistantResponse(status: AssistantStatus.success, message: 'one'),
          AssistantResponse(status: AssistantStatus.success, message: 'two'),
        ],
      ),
    );
    final coordinator = _coordinator(
      controller: controller,
      store: store,
      createdAt: createdAt,
      now: () => updatedAt,
      debounceDuration: const Duration(hours: 1),
    )..start();
    addTearDown(coordinator.dispose);

    await controller.sendMessage('first');
    await controller.sendMessage('second');
    await coordinator.flush();

    expect(store.saved, hasLength(1));
    expect(store.saved.single.messages.map((m) => m.text), [
      'first',
      'one',
      'second',
      'two',
    ]);
  });

  test(
    'store failure reports onError without changing controller phase',
    () async {
      var errorCount = 0;
      final store = _RecordingConversationStore(throwOnSave: true);
      final controller = _controller(
        gateway: FakeTravelAssistantGateway(
          response: AssistantResponse(status: AssistantStatus.success),
        ),
      );
      final coordinator = _coordinator(
        controller: controller,
        store: store,
        createdAt: createdAt,
        now: () => updatedAt,
        debounceDuration: Duration.zero,
        onError: (_) => errorCount += 1,
      )..start();
      addTearDown(coordinator.dispose);

      await controller.sendMessage('hello');
      await coordinator.flush();

      expect(errorCount, 2);
      expect(controller.state.phase, TravelAssistantPhase.ready);
    },
  );

  test('assistant failure with user message can still be saved', () async {
    final store = _RecordingConversationStore();
    final controller = _controller(
      gateway: FakeTravelAssistantGateway(
        exception: TravelAssistantException(
          TravelAssistantFailure.network(message: 'safe', retryable: true),
        ),
      ),
    );
    final coordinator = _coordinator(
      controller: controller,
      store: store,
      createdAt: createdAt,
      now: () => updatedAt,
      debounceDuration: Duration.zero,
    )..start();
    addTearDown(coordinator.dispose);

    await controller.sendMessage('save me');
    await coordinator.flush();

    expect(controller.state.phase, TravelAssistantPhase.failure);
    expect(store.saved.single.messages.map((m) => m.text), ['save me']);
  });

  test('dispose is idempotent and waits for active save', () async {
    final saveGate = Completer<void>();
    final store = _RecordingConversationStore(saveGate: saveGate.future);
    final controller = _controller(
      gateway: FakeTravelAssistantGateway(
        response: AssistantResponse(status: AssistantStatus.success),
      ),
    );
    final coordinator = _coordinator(
      controller: controller,
      store: store,
      createdAt: createdAt,
      now: () => updatedAt,
      debounceDuration: Duration.zero,
    )..start();

    await controller.sendMessage('hello');
    final disposeFuture = coordinator.dispose();
    expect(store.saveInFlight, 1);
    saveGate.complete();
    await disposeFuture;
    await coordinator.dispose();

    expect(store.saved, hasLength(1));
  });
}

TravelAssistantController _controller({FakeTravelAssistantGateway? gateway}) {
  return TravelAssistantController(
    gateway:
        gateway ??
        FakeTravelAssistantGateway(
          response: AssistantResponse(status: AssistantStatus.success),
        ),
    userId: 'user_1',
    tripId: 'trip_1',
    now: () => DateTime(2026, 7, 17, 9),
  );
}

AiChatPersistenceCoordinator _coordinator({
  required TravelAssistantController controller,
  required _RecordingConversationStore store,
  required DateTime createdAt,
  required DateTime Function() now,
  Duration debounceDuration = const Duration(milliseconds: 300),
  void Function(ConversationStoreException error)? onError,
}) {
  return AiChatPersistenceCoordinator(
    controller: controller,
    store: store,
    mapper: const TravelAssistantSessionMapper(),
    localConversationId: 'local_1',
    createdAt: createdAt,
    now: now,
    debounceDuration: debounceDuration,
    onError: onError,
  );
}

class _RecordingConversationStore implements ConversationStore {
  _RecordingConversationStore({this.throwOnSave = false, this.saveGate});

  final bool throwOnSave;
  final Future<void>? saveGate;
  final List<AssistantConversationSnapshot> saved = [];
  int saveInFlight = 0;

  @override
  Future<void> save(AssistantConversationSnapshot conversation) async {
    saveInFlight += 1;
    try {
      final gate = saveGate;
      if (gate != null) await gate;
      if (throwOnSave) {
        throw const ConversationStoreException(
          type: ConversationStoreFailureType.writeFailed,
          message: 'safe',
        );
      }
      saved
        ..removeWhere((item) => item.id == conversation.id)
        ..add(conversation);
    } finally {
      saveInFlight -= 1;
    }
  }

  @override
  Future<AssistantConversationSnapshot?> getById(String id) async => null;

  @override
  Future<AssistantConversationSnapshot?> getLatestForTrip({
    required String userId,
    required String tripId,
  }) async => null;

  @override
  Future<List<AssistantConversationSummary>> listForUser(String userId) async {
    return const [];
  }

  @override
  Future<void> delete(String id) async {}

  @override
  Future<void> clearForUser(String userId) async {}
}

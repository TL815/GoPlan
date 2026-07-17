import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:goplan/application/assistant/travel_assistant_controller.dart';
import 'package:goplan/application/assistant/travel_assistant_exception.dart';
import 'package:goplan/application/assistant/travel_assistant_failure.dart';
import 'package:goplan/application/assistant/travel_assistant_message.dart';
import 'package:goplan/application/assistant/travel_assistant_message_role.dart';
import 'package:goplan/application/assistant/travel_assistant_phase.dart';
import 'package:goplan/domain/assistant/assistant_response.dart';
import 'package:goplan/domain/assistant/assistant_status.dart';
import 'package:goplan/domain/assistant/client_event.dart';
import 'package:goplan/domain/assistant/client_event_type.dart';
import 'package:goplan/domain/assistant/ui_action.dart';
import 'package:goplan/domain/assistant/ui_action_type.dart';
import 'package:goplan/domain/itinerary/itinerary.dart';
import 'package:goplan/domain/itinerary/itinerary_warning.dart';
import 'package:goplan/domain/trip/trip_state.dart';

import '../../helpers/fake_travel_assistant_gateway.dart';

void main() {
  final fixedNow = DateTime(2026, 7, 15, 9, 30);

  TravelAssistantController controllerFor(
    FakeTravelAssistantGateway gateway, {
    String userId = ' user_1 ',
    String tripId = ' trip_1 ',
    String timezone = 'Asia/Shanghai',
    String? conversationId,
    TripState? tripState,
    Itinerary? itinerary,
  }) {
    final controller = TravelAssistantController(
      gateway: gateway,
      userId: userId,
      tripId: tripId,
      timezone: timezone,
      initialConversationId: conversationId,
      initialTripState: tripState,
      initialItinerary: itinerary,
      now: () => fixedNow,
    );
    addTearDown(controller.dispose);
    return controller;
  }

  AssistantResponse response({
    String? conversationId = 'conv_next',
    AssistantStatus status = AssistantStatus.success,
    String message = 'ready',
    TripState? tripState,
    Itinerary? itinerary,
    List<ItineraryWarning> warnings = const [],
    UiAction? uiAction,
  }) {
    return AssistantResponse(
      conversationId: conversationId,
      status: status,
      message: message,
      tripState: tripState,
      itinerary: itinerary,
      warnings: warnings,
      uiAction: uiAction,
    );
  }

  TravelAssistantException exception({
    bool retryable = true,
    String message = 'timeout',
  }) {
    return TravelAssistantException(
      TravelAssistantFailure.timeout(message: message, retryable: retryable),
    );
  }

  test('constructor validates ids and normalizes initial state', () {
    final gateway = FakeTravelAssistantGateway(response: response());

    expect(
      () => controllerFor(gateway, userId: ' '),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => controllerFor(gateway, tripId: ' '),
      throwsA(isA<ArgumentError>()),
    );

    final controller = controllerFor(
      gateway,
      timezone: ' ',
      conversationId: ' conv_1 ',
    );

    expect(controller.state.phase, TravelAssistantPhase.idle);
    expect(controller.state.messages, isEmpty);
    expect(controller.state.userId, 'user_1');
    expect(controller.state.tripId, 'trip_1');
    expect(controller.state.timezone, 'Asia/Shanghai');
    expect(controller.state.conversationId, 'conv_1');
  });

  test('empty sendMessage returns null without calling gateway', () async {
    final gateway = FakeTravelAssistantGateway(response: response());
    final controller = controllerFor(gateway);

    final result = await controller.sendMessage('   ');

    expect(result, isNull);
    expect(gateway.callCount, 0);
    expect(controller.state.messages, isEmpty);
  });

  test('sendMessage emits sending then ready and builds request', () async {
    final tripState = TripState(destination: 'Yunnan', durationDays: 6);
    final nextTripState = TripState(destination: 'Dali');
    final itinerary = Itinerary(title: 'Dali trip', destination: 'Dali');
    final warning = ItineraryWarning(
      id: 'warning_1',
      type: 'route',
      message: 'long drive',
    );
    final uiAction = UiAction(
      type: UiActionType.requestDateRange,
      field: 'travel_dates',
    );
    final gateway = FakeTravelAssistantGateway(
      response: response(
        conversationId: 'conv_next',
        status: AssistantStatus.needInput,
        message: 'choose dates',
        tripState: nextTripState,
        itinerary: itinerary,
        warnings: [warning],
        uiAction: uiAction,
      ),
    );
    final controller = controllerFor(
      gateway,
      conversationId: 'conv_current',
      tripState: tripState,
    );
    final states = <TravelAssistantPhase>[];
    final subscription = controller.states.listen(
      (state) => states.add(state.phase),
    );

    final result = await controller.sendMessage('  go to yunnan  ');
    await Future<void>.delayed(Duration.zero);

    expect(result?.message, 'choose dates');
    expect(states, [TravelAssistantPhase.sending, TravelAssistantPhase.ready]);
    expect(gateway.callCount, 1);
    expect(gateway.lastRequest?.userId, 'user_1');
    expect(gateway.lastRequest?.tripId, 'trip_1');
    expect(gateway.lastRequest?.conversationId, 'conv_current');
    expect(gateway.lastRequest?.query, 'go to yunnan');
    expect(gateway.lastRequest?.event.type, ClientEventType.chatMessage);
    expect(gateway.lastRequest?.event.payload['message'], 'go to yunnan');
    expect(gateway.lastRequest?.tripSnapshot['destination'], 'Yunnan');
    expect(controller.state.phase, TravelAssistantPhase.ready);
    expect(controller.state.conversationId, 'conv_next');
    expect(controller.state.tripState, same(nextTripState));
    expect(controller.state.itinerary, same(itinerary));
    expect(controller.state.warnings, [warning]);
    expect(controller.state.uiAction, same(uiAction));
    expect(controller.state.assistantStatus, AssistantStatus.needInput);
    expect(controller.state.lastResponse, same(result));
    expect(controller.state.lastFailure, isNull);
    expect(controller.state.messages, hasLength(2));
    expect(
      controller.state.messages.first.role,
      TravelAssistantMessageRole.user,
    );
    expect(controller.state.messages.first.text, 'go to yunnan');
    expect(controller.state.messages.first.id, 'message_1');
    expect(
      controller.state.messages.last.role,
      TravelAssistantMessageRole.assistant,
    );
    expect(controller.state.messages.last.response, same(result));

    await subscription.cancel();
  });

  test(
    'response null fields preserve conversation, trip, and itinerary',
    () async {
      final initialTrip = TripState(destination: 'Yunnan');
      final initialItinerary = Itinerary(title: 'Existing trip');
      final gateway = FakeTravelAssistantGateway(
        response: response(
          conversationId: null,
          status: AssistantStatus.error,
          message: '',
        ),
      );
      final controller = controllerFor(
        gateway,
        conversationId: 'conv_current',
        tripState: initialTrip,
        itinerary: initialItinerary,
      );

      await controller.sendMessage('continue');

      expect(controller.state.phase, TravelAssistantPhase.ready);
      expect(controller.state.assistantStatus, AssistantStatus.error);
      expect(controller.state.conversationId, 'conv_current');
      expect(controller.state.tripState, same(initialTrip));
      expect(controller.state.itinerary, same(initialItinerary));
      expect(controller.state.warnings, isEmpty);
      expect(controller.state.messages.last.text, 'AI 已返回结果。');
    },
  );

  test(
    'submitEvent sends structured event without flattening payload',
    () async {
      final event = ClientEvent(
        type: ClientEventType.dateRangeSelected,
        field: 'date_range',
        payload: {'start_date': '2026-08-03', 'end_date': '2026-08-09'},
        occurredAt: fixedNow,
      );
      final gateway = FakeTravelAssistantGateway(response: response());
      final controller = controllerFor(gateway, conversationId: 'conv_1');

      await controller.submitEvent(event, displayText: ' dates selected ');
      await controller.submitEvent(
        ClientEvent(
          type: ClientEventType.dateSelected,
          field: 'date',
          payload: {'date': '2026-08-03'},
          occurredAt: fixedNow,
        ),
        query: '',
      );

      expect(gateway.requests.first.query, '');
      expect(gateway.requests.first.event, same(event));
      expect(gateway.requests.first.event.payload['start_date'], '2026-08-03');
      expect(controller.state.messages.first.text, 'dates selected');
      expect(controller.state.messages[2].text, '已选择出发日期');
      expect(gateway.requests.last.conversationId, 'conv_next');
    },
  );

  test('failure keeps prior successful state and does not throw', () async {
    final initialTrip = TripState(destination: 'Yunnan');
    final initialItinerary = Itinerary(title: 'Existing trip');
    final priorResponse = response(
      conversationId: 'conv_saved',
      tripState: initialTrip,
      itinerary: initialItinerary,
    );
    var callCount = 0;
    final gateway = FakeTravelAssistantGateway(
      handler: (_) async {
        callCount += 1;
        if (callCount == 1) return priorResponse;
        throw exception();
      },
    );
    final controller = controllerFor(gateway, conversationId: 'conv_start');
    await controller.sendMessage('first');

    final result = await controller.sendMessage('second');

    expect(result, isNull);
    expect(controller.state.phase, TravelAssistantPhase.failure);
    expect(
      controller.state.lastFailure?.type,
      TravelAssistantFailureType.timeout,
    );
    expect(controller.state.conversationId, 'conv_saved');
    expect(controller.state.tripState, same(initialTrip));
    expect(controller.state.itinerary, same(initialItinerary));
    expect(controller.state.lastResponse, same(priorResponse));
    expect(controller.state.messages.map((message) => message.role), [
      TravelAssistantMessageRole.user,
      TravelAssistantMessageRole.assistant,
      TravelAssistantMessageRole.user,
    ]);
  });

  test('unknown gateway exception becomes sanitized unknown failure', () async {
    final gateway = FakeTravelAssistantGateway(
      handler: (_) async => throw StateError('secret Authorization abc'),
    );
    final controller = controllerFor(gateway);

    await controller.sendMessage('hello');

    expect(controller.state.phase, TravelAssistantPhase.failure);
    expect(
      controller.state.lastFailure?.type,
      TravelAssistantFailureType.unknown,
    );
    expect(controller.state.lastFailure?.retryable, isFalse);
    expect(controller.state.lastFailure?.message, '旅行助手请求失败。');
    expect(controller.state.lastFailure.toString(), isNot(contains('secret')));
  });

  test(
    'retryLast only retries retryable failures and reuses current state',
    () async {
      final completerGateway = FakeTravelAssistantGateway(
        exceptionQueue: [exception()],
        responseQueue: [response(message: 'retried')],
      );
      final controller = controllerFor(
        completerGateway,
        conversationId: 'conv_before',
        tripState: TripState(destination: 'Before'),
      );
      await controller.sendMessage('plan');
      final messageCountAfterFailure = controller.state.messages.length;

      final retryResult = await controller.retryLast();

      expect(retryResult?.message, 'retried');
      expect(completerGateway.callCount, 2);
      expect(controller.state.messages.length, messageCountAfterFailure + 1);
      expect(completerGateway.requests.last.query, 'plan');
      expect(
        completerGateway.requests.last.event,
        same(completerGateway.requests.first.event),
      );
      expect(completerGateway.requests.last.conversationId, 'conv_before');
      expect(
        completerGateway.requests.last.tripSnapshot['destination'],
        'Before',
      );

      final nonRetryGateway = FakeTravelAssistantGateway(
        exception: exception(retryable: false),
      );
      final nonRetryController = controllerFor(nonRetryGateway);
      await nonRetryController.sendMessage('plan');
      expect(await nonRetryController.retryLast(), isNull);
      expect(nonRetryGateway.callCount, 1);
    },
  );

  test('concurrency guard prevents duplicate requests and messages', () async {
    final completer = Completer<AssistantResponse>();
    final gateway = FakeTravelAssistantGateway(
      handler: (_) => completer.future,
    );
    final controller = controllerFor(gateway);

    final first = controller.sendMessage('first');
    expect(controller.state.phase, TravelAssistantPhase.sending);
    expect(await controller.sendMessage('second'), isNull);
    expect(
      await controller.submitEvent(ClientEvent.chatMessage('event')),
      isNull,
    );
    expect(await controller.retryLast(), isNull);
    expect(gateway.callCount, 1);
    expect(controller.state.messages, hasLength(1));

    completer.complete(response(message: 'done'));
    await first;
    expect(controller.state.messages, hasLength(2));
  });

  test('clearFailure returns to ready or idle without clearing data', () async {
    final itinerary = Itinerary(title: 'Existing');
    final gateway = FakeTravelAssistantGateway(
      responseQueue: [response(itinerary: itinerary)],
      exceptionQueue: [exception()],
    );
    final controller = controllerFor(gateway);
    await controller.sendMessage('first');
    await controller.sendMessage('second');

    controller.clearFailure();

    expect(controller.state.phase, TravelAssistantPhase.ready);
    expect(controller.state.lastFailure, isNull);
    expect(controller.state.itinerary, same(itinerary));

    final idleGateway = FakeTravelAssistantGateway(exception: exception());
    final idleController = controllerFor(idleGateway);
    await idleController.sendMessage('first');
    idleController.clearFailure();

    expect(idleController.state.phase, TravelAssistantPhase.idle);
    expect(idleController.state.lastFailure, isNull);
  });

  test('dispose is idempotent and blocks later operations', () async {
    final gateway = FakeTravelAssistantGateway(response: response());
    final controller = controllerFor(gateway);

    controller.dispose();
    controller.dispose();

    expect(controller.state.phase, TravelAssistantPhase.disposed);
    expect(() => controller.sendMessage('hello'), throwsStateError);
    expect(
      () => controller.submitEvent(ClientEvent.chatMessage('hello')),
      throwsStateError,
    );
    expect(() => controller.retryLast(), throwsStateError);
    expect(() => controller.clearFailure(), throwsStateError);
  });

  test(
    'late success or failure after dispose does not update closed stream',
    () async {
      final successCompleter = Completer<AssistantResponse>();
      final successGateway = FakeTravelAssistantGateway(
        handler: (_) => successCompleter.future,
      );
      final successController = controllerFor(successGateway);
      final successFuture = successController.sendMessage('hello');
      successController.dispose();
      successCompleter.complete(response(message: 'late'));
      await successFuture;

      expect(successController.state.phase, TravelAssistantPhase.disposed);
      expect(successController.state.messages, hasLength(1));

      final failureCompleter = Completer<AssistantResponse>();
      final failureGateway = FakeTravelAssistantGateway(
        handler: (_) => failureCompleter.future,
      );
      final failureController = controllerFor(failureGateway);
      final failureFuture = failureController.sendMessage('hello');
      failureController.dispose();
      failureCompleter.completeError(exception());
      await failureFuture;

      expect(failureController.state.phase, TravelAssistantPhase.disposed);
      expect(failureController.state.lastFailure, isNull);
    },
  );

  test(
    'restored initial state keeps messages and avoids id collisions',
    () async {
      final gateway = FakeTravelAssistantGateway(
        response: response(message: 'restored reply'),
      );
      final controller = controllerFor(
        gateway,
        conversationId: 'conv_restored',
        tripState: TripState(destination: 'Hangzhou'),
        itinerary: Itinerary(title: 'Restored itinerary'),
      );
      controller.dispose();

      final restored = TravelAssistantController(
        gateway: gateway,
        userId: 'user_1',
        tripId: 'trip_1',
        initialConversationId: 'conv_restored',
        initialMessages: [
          TravelAssistantMessage(
            id: 'message_2',
            role: TravelAssistantMessageRole.user,
            text: 'old',
            createdAt: fixedNow,
          ),
          TravelAssistantMessage(
            id: 'custom_id',
            role: TravelAssistantMessageRole.assistant,
            text: 'old reply',
            createdAt: fixedNow,
          ),
        ],
        initialWarnings: const [
          ItineraryWarning(id: 'w1', type: 'note', message: 'note'),
        ],
        initialAssistantStatus: AssistantStatus.draft,
        now: () => fixedNow,
      );
      addTearDown(restored.dispose);

      expect(restored.state.phase, TravelAssistantPhase.idle);
      expect(restored.state.messages, hasLength(2));
      expect(restored.state.conversationId, 'conv_restored');
      expect(restored.state.warnings.single.id, 'w1');
      expect(restored.state.assistantStatus, AssistantStatus.draft);
      expect(restored.state.lastResponse, isNull);
      expect(restored.state.lastFailure, isNull);
      expect(restored.state.uiAction.type.name, 'none');

      await restored.sendMessage('next');

      expect(restored.state.messages[2].id, 'message_3');
      expect(restored.state.messages[3].id, 'message_4');
    },
  );
}

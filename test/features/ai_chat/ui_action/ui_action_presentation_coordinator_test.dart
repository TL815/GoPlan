import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:goplan/application/assistant/travel_assistant_controller.dart';
import 'package:goplan/application/assistant/ui_action/ui_action_dispatch_status.dart';
import 'package:goplan/application/assistant/ui_action/ui_action_dispatcher.dart';
import 'package:goplan/domain/assistant/assistant_response.dart';
import 'package:goplan/domain/assistant/assistant_status.dart';
import 'package:goplan/domain/assistant/ui_action.dart';
import 'package:goplan/domain/assistant/ui_action_type.dart';
import 'package:goplan/features/ai_chat/ui_action/ui_action_presentation_coordinator.dart';

import '../../../helpers/fake_travel_assistant_gateway.dart';
import '../../../helpers/fake_ui_action_interaction_port.dart';

void main() {
  AssistantResponse response(UiActionType type) {
    return AssistantResponse(
      status: AssistantStatus.success,
      uiAction: UiAction(type: type),
    );
  }

  _Harness harness({FakeUiActionInteractionPort? port}) {
    final controller = TravelAssistantController(
      gateway: FakeTravelAssistantGateway(
        response: AssistantResponse(status: AssistantStatus.success),
      ),
      userId: 'user_1',
      tripId: 'trip_1',
    );
    addTearDown(controller.dispose);
    final dispatcher = UiActionDispatcher(
      controller: controller,
      interactionPort: port ?? FakeUiActionInteractionPort(),
    );
    return _Harness(
      coordinator: UiActionPresentationCoordinator(dispatcher: dispatcher),
      port: port ?? FakeUiActionInteractionPort(),
    );
  }

  test('null response is ignored', () async {
    final h = harness();

    expect(await h.coordinator.handleResponse(null), isNull);
  });

  test(
    'same response instance is handled once and reset allows retry',
    () async {
      final h = harness();
      final first = response(UiActionType.none);

      final firstResult = await h.coordinator.handleResponse(first);
      final secondResult = await h.coordinator.handleResponse(first);
      h.coordinator.reset();
      final thirdResult = await h.coordinator.handleResponse(first);

      expect(firstResult?.status, UiActionDispatchStatus.ignored);
      expect(secondResult, isNull);
      expect(thirdResult?.status, UiActionDispatchStatus.ignored);
    },
  );

  test('new response instance with same content is handled', () async {
    final h = harness();

    final first = await h.coordinator.handleResponse(
      response(UiActionType.none),
    );
    final second = await h.coordinator.handleResponse(
      response(UiActionType.none),
    );

    expect(first?.status, UiActionDispatchStatus.ignored);
    expect(second?.status, UiActionDispatchStatus.ignored);
  });

  test('terminal statuses mark response as processed', () async {
    for (final type in [
      UiActionType.showMap,
      UiActionType.none,
      UiActionType.unknown,
    ]) {
      final h = harness();
      final current = response(type);
      expect(await h.coordinator.handleResponse(current), isNotNull);
      expect(await h.coordinator.handleResponse(current), isNull);
    }
  });

  test('same response in progress is not dispatched twice', () async {
    final completer = Completer<DateTime?>();
    final port = FakeUiActionInteractionPort(
      startDateHandler: (_) => completer.future,
    );
    final h = harness(port: port);
    final current = response(UiActionType.requestStartDate);

    final first = h.coordinator.handleResponse(current);
    final second = await h.coordinator.handleResponse(current);
    completer.complete(null);
    final firstResult = await first;

    expect(second, isNull);
    expect(firstResult?.status, UiActionDispatchStatus.cancelled);
    expect(port.requestStartDateCount, 1);
  });

  test('busy does not permanently mark response as processed', () async {
    final completer = Completer<DateTime?>();
    final port = FakeUiActionInteractionPort(
      startDateHandler: (_) => completer.future,
    );
    final h = harness(port: port);
    final firstResponse = response(UiActionType.requestStartDate);
    final secondResponse = response(UiActionType.requestStartDate);

    final first = h.coordinator.handleResponse(firstResponse);
    final busy = await h.coordinator.handleResponse(secondResponse);
    completer.complete(null);
    await first;
    final retry = await h.coordinator.handleResponse(secondResponse);

    expect(busy?.status, UiActionDispatchStatus.busy);
    expect(retry?.status, UiActionDispatchStatus.cancelled);
  });
}

class _Harness {
  const _Harness({required this.coordinator, required this.port});

  final UiActionPresentationCoordinator coordinator;
  final FakeUiActionInteractionPort port;
}

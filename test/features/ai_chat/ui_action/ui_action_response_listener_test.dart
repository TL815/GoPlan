import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goplan/application/assistant/travel_assistant_controller.dart';
import 'package:goplan/application/assistant/ui_action/ui_action_dispatch_result.dart';
import 'package:goplan/application/assistant/ui_action/ui_action_dispatcher.dart';
import 'package:goplan/application/assistant/ui_action/ui_action_dispatch_status.dart';
import 'package:goplan/domain/assistant/assistant_response.dart';
import 'package:goplan/domain/assistant/assistant_status.dart';
import 'package:goplan/domain/assistant/ui_action.dart';
import 'package:goplan/domain/assistant/ui_action_type.dart';
import 'package:goplan/features/ai_chat/ui_action/ui_action_presentation_coordinator.dart';
import 'package:goplan/features/ai_chat/ui_action/ui_action_response_listener.dart';

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
    );
  }

  testWidgets('renders child and triggers initial response after frame', (
    tester,
  ) async {
    final h = harness();
    final results = <UiActionDispatchResult>[];

    await tester.pumpWidget(
      MaterialApp(
        home: UiActionResponseListener(
          response: response(UiActionType.none),
          coordinator: h.coordinator,
          onResult: results.add,
          child: const Text('child'),
        ),
      ),
    );
    expect(find.text('child'), findsOneWidget);

    expect(results.single.status, UiActionDispatchStatus.ignored);
  });

  testWidgets('same response rebuild does not trigger again', (tester) async {
    final h = harness();
    final results = <UiActionDispatchResult>[];
    final current = response(UiActionType.none);

    Future<void> pump(AssistantResponse? response) async {
      await tester.pumpWidget(
        MaterialApp(
          home: UiActionResponseListener(
            response: response,
            coordinator: h.coordinator,
            onResult: results.add,
            child: const Text('child'),
          ),
        ),
      );
      await tester.pump();
    }

    await pump(current);
    await pump(current);
    await pump(response(UiActionType.none));
    await pump(null);

    expect(results, hasLength(2));
  });

  testWidgets('dispose before async result does not call onResult', (
    tester,
  ) async {
    final completer = Completer<DateTime?>();
    final h = harness(
      port: FakeUiActionInteractionPort(
        startDateHandler: (_) => completer.future,
      ),
    );
    final results = <UiActionDispatchResult>[];

    await tester.pumpWidget(
      MaterialApp(
        home: UiActionResponseListener(
          response: response(UiActionType.requestStartDate),
          coordinator: h.coordinator,
          onResult: results.add,
          child: const Text('child'),
        ),
      ),
    );
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    completer.complete(null);
    await tester.pump();

    expect(results, isEmpty);
  });
}

class _Harness {
  const _Harness({required this.coordinator});

  final UiActionPresentationCoordinator coordinator;
}

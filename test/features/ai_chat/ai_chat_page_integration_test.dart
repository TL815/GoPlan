import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goplan/application/assistant/travel_assistant_controller.dart';
import 'package:goplan/application/assistant/travel_assistant_exception.dart';
import 'package:goplan/application/assistant/travel_assistant_failure.dart';
import 'package:goplan/application/assistant/travel_assistant_phase.dart';
import 'package:goplan/application/assistant/ui_action/date_range_selection.dart';
import 'package:goplan/application/assistant/ui_action/ui_action_dispatcher.dart';
import 'package:goplan/domain/assistant/assistant_response.dart';
import 'package:goplan/domain/assistant/assistant_status.dart';
import 'package:goplan/domain/assistant/client_event_type.dart';
import 'package:goplan/domain/assistant/ui_action.dart';
import 'package:goplan/domain/assistant/ui_action_option.dart';
import 'package:goplan/domain/assistant/ui_action_type.dart';
import 'package:goplan/main.dart';
import 'package:goplan/features/ai_chat/ui_action/ui_action_presentation_coordinator.dart';

import '../../helpers/fake_travel_assistant_gateway.dart';
import '../../helpers/fake_ui_action_interaction_port.dart';

void main() {
  final fixedNow = DateTime(2026, 7, 16, 9);

  AssistantResponse response({
    String? conversationId,
    AssistantStatus status = AssistantStatus.success,
    String message = 'assistant ok',
    UiAction? uiAction,
  }) {
    return AssistantResponse(
      conversationId: conversationId,
      status: status,
      message: message,
      uiAction: uiAction,
    );
  }

  Future<_Harness> pumpHarness(
    WidgetTester tester, {
    FakeTravelAssistantGateway? gateway,
    FakeUiActionInteractionPort? port,
  }) async {
    final h = _Harness(
      gateway: gateway ?? FakeTravelAssistantGateway(response: response()),
      port: port ?? FakeUiActionInteractionPort(),
      now: () => fixedNow,
    );
    addTearDown(h.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: TravelAssistantChatView(
          controller: h.controller,
          coordinator: h.coordinator,
        ),
      ),
    );
    return h;
  }

  Future<void> submitText(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();
  }

  testWidgets('initial view builds without sending a request', (tester) async {
    final h = await pumpHarness(tester);

    expect(h.controller.state.phase, TravelAssistantPhase.idle);
    expect(h.gateway.callCount, 0);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('告诉我你的旅行想法'), findsOneWidget);
  });

  testWidgets('empty text does not call gateway', (tester) async {
    final h = await pumpHarness(tester);

    await submitText(tester, '   ');

    expect(h.gateway.callCount, 0);
    expect(h.controller.state.messages, isEmpty);
  });

  testWidgets('send trims input and renders controller messages', (
    tester,
  ) async {
    final h = await pumpHarness(
      tester,
      gateway: FakeTravelAssistantGateway(
        response: response(conversationId: 'conv_test_1'),
      ),
    );

    await submitText(tester, '  hello assistant  ');
    await tester.pump();

    expect(h.gateway.callCount, 1);
    expect(h.gateway.lastRequest!.query, 'hello assistant');
    expect(find.text('hello assistant'), findsOneWidget);
    expect(find.text('assistant ok'), findsOneWidget);
    expect(find.text('conv_test_1'), findsNothing);
  });

  testWidgets('sending state shows loading and blocks duplicate send', (
    tester,
  ) async {
    final completer = Completer<AssistantResponse>();
    final gateway = FakeTravelAssistantGateway(
      handler: (_) => completer.future,
    );
    final h = await pumpHarness(tester, gateway: gateway);

    await submitText(tester, 'first message');
    await submitText(tester, 'second message');

    expect(find.text('AI 正在思考...'), findsOneWidget);
    expect(h.gateway.callCount, 1);

    completer.complete(response(message: 'done'));
    await tester.pump();
    await tester.pump();

    expect(find.text('AI 正在思考...'), findsNothing);
    expect(find.text('done'), findsOneWidget);
  });

  testWidgets('failure card uses safe copy and retry calls controller retry', (
    tester,
  ) async {
    final gateway = FakeTravelAssistantGateway(
      exceptionQueue: [
        TravelAssistantException(
          TravelAssistantFailure.network(
            message: 'Authorization Bearer secret',
            retryable: true,
          ),
        ),
      ],
      responseQueue: [response(message: 'retry ok')],
    );
    await pumpHarness(tester, gateway: gateway);

    await submitText(tester, 'please plan');
    await tester.pump();

    expect(find.text('网络连接失败，请检查网络后重试。'), findsOneWidget);
    expect(find.textContaining('Authorization'), findsNothing);

    await tester.tap(find.text('重试'));
    await tester.pump();
    await tester.pump();

    expect(gateway.callCount, 2);
    expect(find.text('retry ok'), findsOneWidget);
  });

  testWidgets(
    'ui action date result submits ClientEvent instead of text query',
    (tester) async {
      final gateway = FakeTravelAssistantGateway(
        responseQueue: [
          response(
            conversationId: 'conv_test_1',
            message: 'choose date',
            uiAction: UiAction(type: UiActionType.requestStartDate),
          ),
          response(conversationId: 'conv_test_1', message: 'date accepted'),
        ],
      );
      final port = FakeUiActionInteractionPort(
        startDateResult: DateTime(2026, 8),
      );
      await pumpHarness(tester, gateway: gateway, port: port);

      await submitText(tester, 'plan trip');
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(port.requestStartDateCount, 1);
      expect(gateway.callCount, 2);
      expect(gateway.requests[1].query, isEmpty);
      expect(gateway.requests[1].event.type, ClientEventType.dateSelected);
      expect(gateway.requests[1].event.payload['start_date'], '2026-08-01');
      expect(find.text('出发日期：2026-08-01'), findsOneWidget);
    },
  );

  testWidgets('date range and confirm false submit structured events', (
    tester,
  ) async {
    final gateway = FakeTravelAssistantGateway(
      responseQueue: [
        response(
          message: 'choose dates',
          uiAction: UiAction(type: UiActionType.requestDateRange),
        ),
        response(
          message: 'confirm',
          uiAction: UiAction(type: UiActionType.confirm),
        ),
        response(message: 'confirmed false'),
      ],
    );
    final port = FakeUiActionInteractionPort(
      dateRangeResult: DateRangeSelection(
        start: DateTime(2026, 8),
        end: DateTime(2026, 8, 5),
      ),
      confirmationResult: false,
    );
    await pumpHarness(tester, gateway: gateway, port: port);

    await submitText(tester, 'plan trip');
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(gateway.requests[1].event.type, ClientEventType.dateRangeSelected);
    expect(gateway.requests[1].event.payload['end_date'], '2026-08-05');
    expect(
      gateway.requests[2].event.type,
      ClientEventType.confirmationSubmitted,
    );
    expect(gateway.requests[2].event.payload['confirmed'], isFalse);
  });

  testWidgets('option and number ui actions submit structured values', (
    tester,
  ) async {
    final gateway = FakeTravelAssistantGateway(
      responseQueue: [
        response(
          message: 'choose option',
          uiAction: UiAction(
            type: UiActionType.selectOption,
            options: [UiActionOption(id: 'fast', label: 'Fast', value: 'fast')],
          ),
        ),
        response(
          message: 'input number',
          uiAction: UiAction(type: UiActionType.inputNumber),
        ),
        response(message: 'done'),
      ],
    );
    final port = FakeUiActionInteractionPort(
      selectedOptionResult: UiActionOption(
        id: 'fast',
        label: 'Fast',
        value: 'fast',
      ),
      numberResult: 3,
    );
    await pumpHarness(tester, gateway: gateway, port: port);

    await submitText(tester, 'plan trip');
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(gateway.requests[1].event.type, ClientEventType.optionSelected);
    expect(gateway.requests[1].event.payload['option_id'], 'fast');
    expect(gateway.requests[2].event.type, ClientEventType.numberSubmitted);
    expect(gateway.requests[2].event.payload['value'], 3);
  });

  testWidgets('conversationId is owned by controller across turns', (
    tester,
  ) async {
    final gateway = FakeTravelAssistantGateway(
      responseQueue: [
        response(conversationId: 'conv_test_1', message: 'first'),
        response(conversationId: 'conv_test_1', message: 'second'),
      ],
    );
    final h = await pumpHarness(tester, gateway: gateway);

    await submitText(tester, 'first');
    await tester.pump();
    await submitText(tester, 'second');
    await tester.pump();

    expect(gateway.requests[0].conversationId, isNull);
    expect(h.controller.state.conversationId, 'conv_test_1');
    expect(gateway.requests[1].conversationId, 'conv_test_1');
    expect(find.text('conv_test_1'), findsNothing);
  });

  testWidgets('cancelled ui action does not submit a user message', (
    tester,
  ) async {
    final gateway = FakeTravelAssistantGateway(
      responseQueue: [
        response(
          message: 'choose date',
          uiAction: UiAction(type: UiActionType.requestStartDate),
        ),
      ],
    );
    final port = FakeUiActionInteractionPort();
    final h = await pumpHarness(tester, gateway: gateway, port: port);

    await submitText(tester, 'plan trip');
    await tester.pump();
    await tester.pump();

    expect(port.requestStartDateCount, 1);
    expect(gateway.callCount, 1);
    expect(
      h.controller.state.messages.where((m) => m.text == 'plan trip'),
      hasLength(1),
    );
  });
}

class _Harness {
  _Harness({
    required this.gateway,
    required this.port,
    required DateTime Function() now,
  }) : controller = TravelAssistantController(
         gateway: gateway,
         userId: 'user_1',
         tripId: 'trip_1',
         now: now,
       ) {
    dispatcher = UiActionDispatcher(
      controller: controller,
      interactionPort: port,
      now: now,
    );
    coordinator = UiActionPresentationCoordinator(dispatcher: dispatcher);
  }

  final FakeTravelAssistantGateway gateway;
  final FakeUiActionInteractionPort port;
  final TravelAssistantController controller;
  late final UiActionDispatcher dispatcher;
  late final UiActionPresentationCoordinator coordinator;

  void dispose() {
    controller.dispose();
  }
}

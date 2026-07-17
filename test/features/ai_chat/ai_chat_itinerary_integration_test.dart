import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goplan/application/assistant/travel_assistant_controller.dart';
import 'package:goplan/application/assistant/ui_action/ui_action_dispatcher.dart';
import 'package:goplan/domain/assistant/assistant_response.dart';
import 'package:goplan/domain/assistant/assistant_status.dart';
import 'package:goplan/domain/assistant/ui_action.dart';
import 'package:goplan/domain/assistant/ui_action_type.dart';
import 'package:goplan/main.dart';
import 'package:goplan/features/ai_chat/ui_action/ui_action_presentation_coordinator.dart';

import '../plan/itinerary/itinerary_test_data.dart';
import '../../helpers/fake_travel_assistant_gateway.dart';
import '../../helpers/fake_ui_action_interaction_port.dart';

void main() {
  Future<_Harness> pumpHarness(
    WidgetTester tester, {
    FakeTravelAssistantGateway? gateway,
    FakeUiActionInteractionPort? port,
  }) async {
    final h = _Harness(
      gateway:
          gateway ??
          FakeTravelAssistantGateway(
            response: AssistantResponse(
              status: AssistantStatus.success,
              message: 'ok',
            ),
          ),
      port: port ?? FakeUiActionInteractionPort(),
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

  Future<void> send(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();
    await tester.pump();
  }

  testWidgets('does not show itinerary when state has none', (tester) async {
    await pumpHarness(tester);

    expect(find.text('查看完整行程'), findsNothing);
  });

  testWidgets('shows one current itinerary and opens detail page', (
    tester,
  ) async {
    await pumpHarness(
      tester,
      gateway: FakeTravelAssistantGateway(
        response: AssistantResponse(
          status: AssistantStatus.success,
          message: 'done',
          conversationId: 'conv_secret',
          itinerary: sampleItinerary(days: 2),
        ),
      ),
    );

    await send(tester, 'plan');

    expect(find.text('杭州周末'), findsOneWidget);
    expect(find.text('查看完整行程'), findsOneWidget);
    expect(find.text('conv_secret'), findsNothing);
    await tester.pump();
    expect(find.text('查看完整行程'), findsOneWidget);

    await tester.tap(find.text('查看完整行程'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('西湖第 2 天'),
      500,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('西湖第 2 天'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('杭州周末'), findsOneWidget);
  });

  testWidgets('new itinerary replaces old display and needInput preserves it', (
    tester,
  ) async {
    final first = sampleItinerary(days: 1).copyWith(title: '旧行程');
    final second = sampleItinerary(days: 1).copyWith(title: '新行程');
    final h = await pumpHarness(
      tester,
      gateway: FakeTravelAssistantGateway(
        responseQueue: [
          AssistantResponse(
            status: AssistantStatus.success,
            message: 'first',
            itinerary: first,
          ),
          AssistantResponse(
            status: AssistantStatus.success,
            message: 'second',
            itinerary: second,
          ),
          AssistantResponse(
            status: AssistantStatus.needInput,
            message: 'need input',
          ),
        ],
      ),
    );

    await send(tester, 'first');
    expect(find.text('旧行程'), findsOneWidget);

    await send(tester, 'second');
    expect(find.text('旧行程'), findsNothing);
    expect(find.text('新行程'), findsOneWidget);

    await send(tester, 'third');
    expect(find.text('新行程'), findsOneWidget);
    expect(h.gateway.callCount, 3);
  });

  testWidgets('restored itinerary displays without gateway call', (
    tester,
  ) async {
    final h = _Harness(
      gateway: FakeTravelAssistantGateway(
        response: AssistantResponse(
          status: AssistantStatus.success,
          message: 'unused',
        ),
      ),
      port: FakeUiActionInteractionPort(),
      initialItinerary: sampleItinerary(days: 1),
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

    expect(find.text('杭州周末'), findsOneWidget);
    expect(h.gateway.callCount, 0);
  });

  testWidgets('passive actions do not call gateway and showMap is safe', (
    tester,
  ) async {
    final gateway = FakeTravelAssistantGateway(
      responseQueue: [
        AssistantResponse(
          status: AssistantStatus.success,
          message: 'show itinerary',
          itinerary: sampleItinerary(days: 1),
          uiAction: UiAction(type: UiActionType.showItinerary),
        ),
        AssistantResponse(
          status: AssistantStatus.success,
          message: 'show budget',
          uiAction: UiAction(type: UiActionType.showBudget),
        ),
        AssistantResponse(
          status: AssistantStatus.success,
          message: 'show map',
          uiAction: UiAction(type: UiActionType.showMap),
        ),
      ],
    );
    final h = await pumpHarness(tester, gateway: gateway);

    await send(tester, 'one');
    await send(tester, 'two');
    await send(tester, 'three');
    await tester.pump();

    expect(h.gateway.callCount, 3);
    expect(find.text('地图路线将在后续版本中提供。'), findsOneWidget);
  });
}

class _Harness {
  _Harness({required this.gateway, required this.port, this.initialItinerary})
    : controller = TravelAssistantController(
        gateway: gateway,
        userId: 'user_1',
        tripId: 'trip_1',
        initialItinerary: initialItinerary,
      ) {
    dispatcher = UiActionDispatcher(
      controller: controller,
      interactionPort: port,
      now: () => DateTime(2026, 7, 17),
    );
    coordinator = UiActionPresentationCoordinator(dispatcher: dispatcher);
  }

  final FakeTravelAssistantGateway gateway;
  final FakeUiActionInteractionPort port;
  final dynamic initialItinerary;
  final TravelAssistantController controller;
  late final UiActionDispatcher dispatcher;
  late final UiActionPresentationCoordinator coordinator;

  void dispose() {
    controller.dispose();
  }
}

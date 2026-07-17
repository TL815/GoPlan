import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:goplan/application/assistant/travel_assistant_controller.dart';
import 'package:goplan/application/assistant/travel_assistant_exception.dart';
import 'package:goplan/application/assistant/travel_assistant_failure.dart';
import 'package:goplan/application/assistant/travel_assistant_phase.dart';
import 'package:goplan/application/assistant/ui_action/date_range_selection.dart';
import 'package:goplan/application/assistant/ui_action/ui_action_dispatcher.dart';
import 'package:goplan/application/assistant/ui_action/ui_action_dispatch_status.dart';
import 'package:goplan/domain/assistant/assistant_response.dart';
import 'package:goplan/domain/assistant/assistant_status.dart';
import 'package:goplan/domain/assistant/client_event_type.dart';
import 'package:goplan/domain/assistant/ui_action.dart';
import 'package:goplan/domain/assistant/ui_action_option.dart';
import 'package:goplan/domain/assistant/ui_action_type.dart';

import '../../../helpers/fake_travel_assistant_gateway.dart';
import '../../../helpers/fake_ui_action_interaction_port.dart';

void main() {
  final fixedNow = DateTime(2026, 7, 15, 9, 30);

  AssistantResponse response({String message = 'ok', String? conversationId}) {
    return AssistantResponse(
      status: AssistantStatus.success,
      message: message,
      conversationId: conversationId,
    );
  }

  _Harness harness({
    FakeTravelAssistantGateway? gateway,
    FakeUiActionInteractionPort? port,
  }) {
    final resolvedGateway =
        gateway ?? FakeTravelAssistantGateway(response: response());
    final controller = TravelAssistantController(
      gateway: resolvedGateway,
      userId: 'user_1',
      tripId: 'trip_1',
      now: () => fixedNow,
    );
    addTearDown(controller.dispose);
    final resolvedPort = port ?? FakeUiActionInteractionPort();
    final dispatcher = UiActionDispatcher(
      controller: controller,
      interactionPort: resolvedPort,
      now: () => fixedNow,
    );
    return _Harness(
      controller: controller,
      gateway: resolvedGateway,
      port: resolvedPort,
      dispatcher: dispatcher,
    );
  }

  UiAction action(
    UiActionType type, {
    String? field,
    List<UiActionOption> options = const [],
    Map<String, Object?> payload = const {},
  }) {
    return UiAction(
      type: type,
      field: field,
      options: options,
      payload: payload,
    );
  }

  test('requestStartDate maps to dateSelected event', () async {
    final h = harness(
      port: FakeUiActionInteractionPort(
        startDateResult: DateTime(2026, 8, 3, 20),
      ),
      gateway: FakeTravelAssistantGateway(
        response: response(conversationId: 'conv_1'),
      ),
    );
    final uiAction = action(
      UiActionType.requestStartDate,
      field: ' departure ',
      payload: {'duration_days': 7},
    );

    final result = await h.dispatcher.dispatch(uiAction);

    expect(result.status, UiActionDispatchStatus.submitted);
    expect(result.event?.type, ClientEventType.dateSelected);
    expect(result.event?.field, 'departure');
    expect(result.event?.payload, {'start_date': '2026-08-03'});
    expect(result.event?.occurredAt, fixedNow);
    expect(result.displayText, '出发日期：2026-08-03');
    expect(h.port.requestStartDateCount, 1);
    expect(h.gateway.lastRequest?.event, same(result.event));
    expect(h.controller.state.messages.first.text, result.displayText);
    expect(h.controller.state.conversationId, 'conv_1');
    expect(uiAction.payload['duration_days'], 7);
  });

  test('requestStartDate cancellation does not submit', () async {
    final h = harness(port: FakeUiActionInteractionPort());

    final result = await h.dispatcher.dispatch(
      action(UiActionType.requestStartDate),
    );

    expect(result.status, UiActionDispatchStatus.cancelled);
    expect(h.gateway.callCount, 0);
    expect(h.controller.state.messages, isEmpty);
  });

  test('requestDateRange maps selected dates without swapping', () async {
    final h = harness(
      port: FakeUiActionInteractionPort(
        dateRangeResult: DateRangeSelection(
          start: DateTime(2026, 8, 9),
          end: DateTime(2026, 8, 3),
        ),
      ),
    );

    final result = await h.dispatcher.dispatch(
      action(UiActionType.requestDateRange, field: ''),
    );

    expect(result.status, UiActionDispatchStatus.submitted);
    expect(result.event?.type, ClientEventType.dateRangeSelected);
    expect(result.event?.field, 'travel_dates');
    expect(result.event?.payload, {
      'start_date': '2026-08-09',
      'end_date': '2026-08-03',
    });
    expect(result.displayText, '旅行日期：2026-08-09 至 2026-08-03');
    expect(h.port.requestDateRangeCount, 1);
  });

  test(
    'selectOption maps id value and label without serializing value',
    () async {
      final option = UiActionOption(
        id: 'slow',
        label: 'Slow pace',
        value: {'pace': 'slow'},
        description: 'ignored',
      );
      final h = harness(
        port: FakeUiActionInteractionPort(selectedOptionResult: option),
      );
      final uiAction = action(UiActionType.selectOption, options: [option]);

      final result = await h.dispatcher.dispatch(uiAction);

      expect(result.status, UiActionDispatchStatus.submitted);
      expect(result.event?.type, ClientEventType.optionSelected);
      expect(result.event?.field, 'option');
      expect(result.event?.payload['option_id'], 'slow');
      expect(result.event?.payload['value'], same(option.value));
      expect(result.event?.payload['label'], 'Slow pace');
      expect(result.event?.payload.containsKey('description'), isFalse);
      expect(result.displayText, 'Slow pace');
      expect(h.port.selectOptionCount, 1);
      expect(uiAction.options, [option]);
    },
  );

  test('inputNumber keeps num type and display text variants', () async {
    final travelerHarness = harness(
      port: FakeUiActionInteractionPort(numberResult: 3),
    );
    final budgetHarness = harness(
      port: FakeUiActionInteractionPort(numberResult: 1200.5),
    );
    final otherHarness = harness(
      port: FakeUiActionInteractionPort(numberResult: 9),
    );

    final traveler = await travelerHarness.dispatcher.dispatch(
      action(UiActionType.inputNumber, field: 'traveler_count'),
    );
    final budget = await budgetHarness.dispatcher.dispatch(
      action(UiActionType.inputNumber, field: 'budget'),
    );
    final other = await otherHarness.dispatcher.dispatch(
      action(UiActionType.inputNumber),
    );

    expect(traveler.event?.payload['value'], isA<int>());
    expect(traveler.displayText, '出行人数：3');
    expect(budget.event?.payload['value'], isA<double>());
    expect(budget.displayText, '预算：1200.5');
    expect(other.event?.field, 'number');
    expect(other.displayText, '已提交：9');
  });

  test('confirm submits true and false but cancels null', () async {
    final trueHarness = harness(
      port: FakeUiActionInteractionPort(confirmationResult: true),
    );
    final falseHarness = harness(
      port: FakeUiActionInteractionPort(confirmationResult: false),
    );
    final nullHarness = harness(port: FakeUiActionInteractionPort());

    final confirmed = await trueHarness.dispatcher.dispatch(
      action(UiActionType.confirm),
    );
    final declined = await falseHarness.dispatcher.dispatch(
      action(UiActionType.confirm),
    );
    final cancelled = await nullHarness.dispatcher.dispatch(
      action(UiActionType.confirm),
    );

    expect(confirmed.event?.type, ClientEventType.confirmationSubmitted);
    expect(confirmed.event?.field, 'confirmation');
    expect(confirmed.event?.payload, {'confirmed': true});
    expect(confirmed.displayText, '已确认');
    expect(declined.event?.payload, {'confirmed': false});
    expect(declined.displayText, '已取消确认');
    expect(cancelled.status, UiActionDispatchStatus.cancelled);
    expect(nullHarness.gateway.callCount, 0);
  });

  test(
    'confirmDateConflict maps selected option without interpreting value',
    () async {
      final option = UiActionOption(
        id: 'keep',
        label: 'Keep selected dates',
        value: ['keep', 7],
      );
      final h = harness(
        port: FakeUiActionInteractionPort(dateConflictOptionResult: option),
      );

      final result = await h.dispatcher.dispatch(
        action(UiActionType.confirmDateConflict),
      );

      expect(result.status, UiActionDispatchStatus.submitted);
      expect(result.event?.type, ClientEventType.dateConflictResolved);
      expect(result.event?.field, 'date_conflict');
      expect(result.event?.payload['option_id'], 'keep');
      expect(result.event?.payload['value'], same(option.value));
      expect(result.displayText, 'Keep selected dates');
    },
  );

  test('passive none and unknown do not call port or controller', () async {
    final h = harness();

    expect(
      (await h.dispatcher.dispatch(action(UiActionType.showItinerary))).status,
      UiActionDispatchStatus.passive,
    );
    expect(
      (await h.dispatcher.dispatch(action(UiActionType.showMap))).status,
      UiActionDispatchStatus.passive,
    );
    expect(
      (await h.dispatcher.dispatch(action(UiActionType.showBudget))).status,
      UiActionDispatchStatus.passive,
    );
    expect(
      (await h.dispatcher.dispatch(UiAction.none())).status,
      UiActionDispatchStatus.ignored,
    );
    expect(
      (await h.dispatcher.dispatch(action(UiActionType.unknown))).status,
      UiActionDispatchStatus.unsupported,
    );
    expect(h.port.totalCallCount, 0);
    expect(h.gateway.callCount, 0);
  });

  test('controller failure returns failed result with lastFailure', () async {
    final failure = TravelAssistantFailure.timeout(message: 'timeout');
    final h = harness(
      port: FakeUiActionInteractionPort(startDateResult: DateTime(2026, 8, 3)),
      gateway: FakeTravelAssistantGateway(
        exception: TravelAssistantException(failure),
      ),
    );

    final result = await h.dispatcher.dispatch(
      action(UiActionType.requestStartDate),
    );

    expect(result.status, UiActionDispatchStatus.failed);
    expect(result.event?.type, ClientEventType.dateSelected);
    expect(result.failure, same(failure));
    expect(h.controller.state.phase, TravelAssistantPhase.failure);
  });

  test('controller sending returns busy without opening port', () async {
    final completer = Completer<AssistantResponse>();
    final h = harness(
      port: FakeUiActionInteractionPort(startDateResult: DateTime(2026, 8, 3)),
      gateway: FakeTravelAssistantGateway(handler: (_) => completer.future),
    );
    final inFlight = h.controller.sendMessage('hello');

    final result = await h.dispatcher.dispatch(
      action(UiActionType.requestStartDate),
    );

    expect(result.status, UiActionDispatchStatus.busy);
    expect(h.port.totalCallCount, 0);
    completer.complete(response());
    await inFlight;
  });

  test(
    'interaction lock returns busy while waiting and releases afterward',
    () async {
      final completer = Completer<DateTime?>();
      final h = harness(
        port: FakeUiActionInteractionPort(
          startDateHandler: (_) => completer.future,
          dateRangeResult: DateRangeSelection(
            start: DateTime(2026, 8, 3),
            end: DateTime(2026, 8, 9),
          ),
        ),
      );

      final first = h.dispatcher.dispatch(
        action(UiActionType.requestStartDate),
      );
      final second = await h.dispatcher.dispatch(
        action(UiActionType.requestDateRange),
      );

      expect(second.status, UiActionDispatchStatus.busy);
      expect(h.port.requestDateRangeCount, 0);

      completer.complete(DateTime(2026, 8, 3));
      expect((await first).status, UiActionDispatchStatus.submitted);

      final third = await h.dispatcher.dispatch(
        action(UiActionType.requestDateRange),
      );
      expect(third.status, UiActionDispatchStatus.submitted);
      expect(h.port.requestDateRangeCount, 1);
    },
  );

  test('port exception returns failed result and releases lock', () async {
    final h = harness(
      port: FakeUiActionInteractionPort(
        exception: StateError('secret Authorization token'),
        dateRangeResult: DateRangeSelection(
          start: DateTime(2026, 8, 3),
          end: DateTime(2026, 8, 9),
        ),
      ),
    );

    final failed = await h.dispatcher.dispatch(
      action(UiActionType.requestStartDate),
    );
    h.port.exception = null;
    final submitted = await h.dispatcher.dispatch(
      action(UiActionType.requestDateRange),
    );

    expect(failed.status, UiActionDispatchStatus.failed);
    expect(failed.failure?.type, TravelAssistantFailureType.unknown);
    expect(failed.failure?.message, '当前交互暂时无法完成。');
    expect(failed.failure.toString(), isNot(contains('secret')));
    expect(h.gateway.callCount, 1);
    expect(submitted.status, UiActionDispatchStatus.submitted);
  });

  test('disposed controller causes StateError', () async {
    final h = harness();
    h.controller.dispose();

    await expectLater(
      h.dispatcher.dispatch(action(UiActionType.requestStartDate)),
      throwsStateError,
    );
  });
}

class _Harness {
  const _Harness({
    required this.controller,
    required this.gateway,
    required this.port,
    required this.dispatcher,
  });

  final TravelAssistantController controller;
  final FakeTravelAssistantGateway gateway;
  final FakeUiActionInteractionPort port;
  final UiActionDispatcher dispatcher;
}

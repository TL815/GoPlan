import 'package:flutter_test/flutter_test.dart';
import 'package:goplan/application/assistant/travel_assistant_failure.dart';
import 'package:goplan/application/assistant/ui_action/ui_action_dispatch_result.dart';
import 'package:goplan/application/assistant/ui_action/ui_action_dispatch_status.dart';
import 'package:goplan/domain/assistant/assistant_response.dart';
import 'package:goplan/domain/assistant/assistant_status.dart';
import 'package:goplan/domain/assistant/client_event.dart';
import 'package:goplan/domain/assistant/ui_action.dart';
import 'package:goplan/domain/assistant/ui_action_type.dart';

void main() {
  final action = UiAction(type: UiActionType.requestStartDate);
  final event = ClientEvent.chatMessage('ok');
  final response = AssistantResponse(status: AssistantStatus.success);
  final failure = TravelAssistantFailure(
    type: TravelAssistantFailureType.unknown,
    message: 'failed',
  );

  test('submitted factory and getters are correct', () {
    final result = UiActionDispatchResult.submitted(
      action: action,
      event: event,
      response: response,
      displayText: 'ok',
    );

    expect(result.status, UiActionDispatchStatus.submitted);
    expect(result.didSubmit, isTrue);
    expect(result.event, same(event));
    expect(result.response, same(response));
    expect(result.displayText, 'ok');
  });

  test('non-submitted factories are tolerant and expose status', () {
    expect(
      UiActionDispatchResult.cancelled(action: action).wasCancelled,
      isTrue,
    );
    expect(UiActionDispatchResult.passive(action: action).isPassive, isTrue);
    expect(
      UiActionDispatchResult.unsupported(action: action).status,
      UiActionDispatchStatus.unsupported,
    );
    expect(
      UiActionDispatchResult.busy(action: action).status,
      UiActionDispatchStatus.busy,
    );
  });

  test('failed factory carries event and failure', () {
    final result = UiActionDispatchResult.failed(
      action: action,
      event: event,
      failure: failure,
    );

    expect(result.status, UiActionDispatchStatus.failed);
    expect(result.hasFailure, isTrue);
    expect(result.event, same(event));
    expect(result.failure, same(failure));
  });
}

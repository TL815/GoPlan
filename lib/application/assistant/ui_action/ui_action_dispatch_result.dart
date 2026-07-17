import '../../../domain/assistant/assistant_response.dart';
import '../../../domain/assistant/client_event.dart';
import '../../../domain/assistant/ui_action.dart';
import '../travel_assistant_failure.dart';
import 'ui_action_dispatch_status.dart';

/// Immutable result produced by dispatching one [UiAction].
class UiActionDispatchResult {
  const UiActionDispatchResult({
    required this.status,
    required this.action,
    this.event,
    this.response,
    this.failure,
    this.displayText,
  });

  factory UiActionDispatchResult.submitted({
    required UiAction action,
    required ClientEvent event,
    required AssistantResponse response,
    String? displayText,
  }) {
    return UiActionDispatchResult(
      status: UiActionDispatchStatus.submitted,
      action: action,
      event: event,
      response: response,
      displayText: displayText,
    );
  }

  factory UiActionDispatchResult.cancelled({required UiAction action}) {
    return UiActionDispatchResult(
      status: UiActionDispatchStatus.cancelled,
      action: action,
    );
  }

  factory UiActionDispatchResult.passive({required UiAction action}) {
    return UiActionDispatchResult(
      status: UiActionDispatchStatus.passive,
      action: action,
    );
  }

  factory UiActionDispatchResult.ignored({required UiAction action}) {
    return UiActionDispatchResult(
      status: UiActionDispatchStatus.ignored,
      action: action,
    );
  }

  factory UiActionDispatchResult.unsupported({required UiAction action}) {
    return UiActionDispatchResult(
      status: UiActionDispatchStatus.unsupported,
      action: action,
    );
  }

  factory UiActionDispatchResult.busy({required UiAction action}) {
    return UiActionDispatchResult(
      status: UiActionDispatchStatus.busy,
      action: action,
    );
  }

  factory UiActionDispatchResult.failed({
    required UiAction action,
    required ClientEvent event,
    required TravelAssistantFailure failure,
    String? displayText,
  }) {
    return UiActionDispatchResult(
      status: UiActionDispatchStatus.failed,
      action: action,
      event: event,
      failure: failure,
      displayText: displayText,
    );
  }

  final UiActionDispatchStatus status;
  final UiAction action;
  final ClientEvent? event;
  final AssistantResponse? response;
  final TravelAssistantFailure? failure;
  final String? displayText;

  bool get didSubmit => status == UiActionDispatchStatus.submitted;
  bool get wasCancelled => status == UiActionDispatchStatus.cancelled;
  bool get isPassive => status == UiActionDispatchStatus.passive;
  bool get hasFailure => failure != null;
}

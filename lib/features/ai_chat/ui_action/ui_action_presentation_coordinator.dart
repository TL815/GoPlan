// ignore_for_file: prefer_initializing_formals

import 'package:goplan/application/assistant/ui_action/ui_action_dispatch_result.dart';
import 'package:goplan/application/assistant/ui_action/ui_action_dispatch_status.dart';
import 'package:goplan/application/assistant/ui_action/ui_action_dispatcher.dart';
import 'package:goplan/domain/assistant/assistant_response.dart';

class UiActionPresentationCoordinator {
  UiActionPresentationCoordinator({required UiActionDispatcher dispatcher})
    : _dispatcher = dispatcher;

  final UiActionDispatcher _dispatcher;
  AssistantResponse? _processingResponse;
  AssistantResponse? _processedResponse;

  Future<UiActionDispatchResult?> handleResponse(
    AssistantResponse? response,
  ) async {
    if (response == null) return null;
    if (identical(response, _processingResponse) ||
        identical(response, _processedResponse)) {
      return null;
    }

    _processingResponse = response;
    try {
      final result = await _dispatcher.dispatch(response.uiAction);
      if (result.status != UiActionDispatchStatus.busy) {
        _processedResponse = response;
      }
      return result;
    } finally {
      if (identical(response, _processingResponse)) {
        _processingResponse = null;
      }
    }
  }

  void reset() {
    _processingResponse = null;
    _processedResponse = null;
  }
}

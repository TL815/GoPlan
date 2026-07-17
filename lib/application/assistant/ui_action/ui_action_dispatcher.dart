// ignore_for_file: prefer_initializing_formals

import '../../../domain/assistant/client_event.dart';
import '../../../domain/assistant/client_event_type.dart';
import '../../../domain/assistant/ui_action.dart';
import '../../../domain/assistant/ui_action_option.dart';
import '../../../domain/assistant/ui_action_type.dart';
import '../travel_assistant_controller.dart';
import '../travel_assistant_failure.dart';
import '../travel_assistant_phase.dart';
import 'ui_action_dispatch_result.dart';
import 'ui_action_interaction_port.dart';

/// Dispatches standard assistant UI actions to a pure interaction port.
class UiActionDispatcher {
  UiActionDispatcher({
    required TravelAssistantController controller,
    required UiActionInteractionPort interactionPort,
    DateTime Function()? now,
  }) : _controller = controller,
       _interactionPort = interactionPort,
       _now = now ?? DateTime.now;

  final TravelAssistantController _controller;
  final UiActionInteractionPort _interactionPort;
  final DateTime Function() _now;
  bool _isDispatchingInteraction = false;

  Future<UiActionDispatchResult> dispatch(UiAction action) async {
    _ensureControllerActive();

    if (_isControllerSending || _isDispatchingInteraction) {
      return UiActionDispatchResult.busy(action: action);
    }

    return switch (action.type) {
      UiActionType.requestStartDate => _withInteractionLock(
        action,
        () => _dispatchStartDate(action),
      ),
      UiActionType.requestDateRange => _withInteractionLock(
        action,
        () => _dispatchDateRange(action),
      ),
      UiActionType.selectOption => _withInteractionLock(
        action,
        () => _dispatchOption(action),
      ),
      UiActionType.inputNumber => _withInteractionLock(
        action,
        () => _dispatchNumber(action),
      ),
      UiActionType.confirm => _withInteractionLock(
        action,
        () => _dispatchConfirm(action),
      ),
      UiActionType.confirmDateConflict => _withInteractionLock(
        action,
        () => _dispatchDateConflict(action),
      ),
      UiActionType.showItinerary ||
      UiActionType.showMap ||
      UiActionType.showBudget => Future.value(
        UiActionDispatchResult.passive(action: action),
      ),
      UiActionType.none => Future.value(
        UiActionDispatchResult.ignored(action: action),
      ),
      UiActionType.unknown => Future.value(
        UiActionDispatchResult.unsupported(action: action),
      ),
    };
  }

  Future<UiActionDispatchResult> _dispatchStartDate(UiAction action) async {
    final selected = await _interactionPort.requestStartDate(action);
    if (selected == null) {
      return UiActionDispatchResult.cancelled(action: action);
    }

    final date = _formatDate(selected);
    final event = ClientEvent(
      type: ClientEventType.dateSelected,
      field: _fieldOrFallback(action.field, 'start_date'),
      payload: {'start_date': date},
      occurredAt: _now(),
    );
    return _submit(action: action, event: event, displayText: '出发日期：$date');
  }

  Future<UiActionDispatchResult> _dispatchDateRange(UiAction action) async {
    final selected = await _interactionPort.requestDateRange(action);
    if (selected == null) {
      return UiActionDispatchResult.cancelled(action: action);
    }

    final start = _formatDate(selected.start);
    final end = _formatDate(selected.end);
    final event = ClientEvent(
      type: ClientEventType.dateRangeSelected,
      field: _fieldOrFallback(action.field, 'travel_dates'),
      payload: {'start_date': start, 'end_date': end},
      occurredAt: _now(),
    );
    return _submit(
      action: action,
      event: event,
      displayText: '旅行日期：$start 至 $end',
    );
  }

  Future<UiActionDispatchResult> _dispatchOption(UiAction action) async {
    final selected = await _interactionPort.selectOption(action);
    if (selected == null) {
      return UiActionDispatchResult.cancelled(action: action);
    }

    final event = ClientEvent(
      type: ClientEventType.optionSelected,
      field: _fieldOrFallback(action.field, 'option'),
      payload: _optionPayload(selected),
      occurredAt: _now(),
    );
    return _submit(action: action, event: event, displayText: selected.label);
  }

  Future<UiActionDispatchResult> _dispatchNumber(UiAction action) async {
    final selected = await _interactionPort.inputNumber(action);
    if (selected == null) {
      return UiActionDispatchResult.cancelled(action: action);
    }

    final field = _fieldOrFallback(action.field, 'number');
    final event = ClientEvent(
      type: ClientEventType.numberSubmitted,
      field: field,
      payload: {'value': selected},
      occurredAt: _now(),
    );
    return _submit(
      action: action,
      event: event,
      displayText: _numberDisplayText(field, selected),
    );
  }

  Future<UiActionDispatchResult> _dispatchConfirm(UiAction action) async {
    final selected = await _interactionPort.confirm(action);
    if (selected == null) {
      return UiActionDispatchResult.cancelled(action: action);
    }

    final event = ClientEvent(
      type: ClientEventType.confirmationSubmitted,
      field: _fieldOrFallback(action.field, 'confirmation'),
      payload: {'confirmed': selected},
      occurredAt: _now(),
    );
    return _submit(
      action: action,
      event: event,
      displayText: selected ? '已确认' : '已取消确认',
    );
  }

  Future<UiActionDispatchResult> _dispatchDateConflict(UiAction action) async {
    final selected = await _interactionPort.confirmDateConflict(action);
    if (selected == null) {
      return UiActionDispatchResult.cancelled(action: action);
    }

    final event = ClientEvent(
      type: ClientEventType.dateConflictResolved,
      field: _fieldOrFallback(action.field, 'date_conflict'),
      payload: _optionPayload(selected),
      occurredAt: _now(),
    );
    return _submit(action: action, event: event, displayText: selected.label);
  }

  Future<UiActionDispatchResult> _withInteractionLock(
    UiAction action,
    Future<UiActionDispatchResult> Function() task,
  ) async {
    _isDispatchingInteraction = true;
    try {
      return await task();
    } on Object catch (error) {
      return UiActionDispatchResult.failed(
        action: action,
        event: ClientEvent(
          type: ClientEventType.unknown,
          payload: const {},
          occurredAt: _now(),
        ),
        failure: TravelAssistantFailure(
          type: TravelAssistantFailureType.unknown,
          message: '当前交互暂时无法完成。',
          retryable: false,
          cause: error,
        ),
      );
    } finally {
      _isDispatchingInteraction = false;
    }
  }

  Future<UiActionDispatchResult> _submit({
    required UiAction action,
    required ClientEvent event,
    required String displayText,
  }) async {
    final response = await _controller.submitEvent(
      event,
      query: '',
      displayText: displayText,
    );
    if (response != null) {
      return UiActionDispatchResult.submitted(
        action: action,
        event: event,
        response: response,
        displayText: displayText,
      );
    }

    final state = _controller.state;
    if (state.phase == TravelAssistantPhase.failure &&
        state.lastFailure != null) {
      return UiActionDispatchResult.failed(
        action: action,
        event: event,
        failure: state.lastFailure!,
        displayText: displayText,
      );
    }
    if (state.phase == TravelAssistantPhase.sending) {
      return UiActionDispatchResult.busy(action: action);
    }
    return UiActionDispatchResult.failed(
      action: action,
      event: event,
      failure: TravelAssistantFailure(
        type: TravelAssistantFailureType.unknown,
        message: '结构化旅行操作提交失败。',
        retryable: false,
      ),
      displayText: displayText,
    );
  }

  bool get _isControllerSending =>
      _controller.state.phase == TravelAssistantPhase.sending;

  void _ensureControllerActive() {
    if (_controller.state.phase == TravelAssistantPhase.disposed) {
      throw StateError('TravelAssistantController has been disposed.');
    }
  }

  static Map<String, Object?> _optionPayload(UiActionOption option) {
    return {
      'option_id': option.id,
      'value': option.value,
      'label': option.label,
    };
  }

  static String _numberDisplayText(String field, num value) {
    return switch (field) {
      'traveler_count' => '出行人数：$value',
      'budget' => '预算：$value',
      _ => '已提交：$value',
    };
  }

  static String _fieldOrFallback(String? field, String fallback) {
    final trimmed = field?.trim();
    if (trimmed == null || trimmed.isEmpty) return fallback;
    return trimmed;
  }

  static String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}

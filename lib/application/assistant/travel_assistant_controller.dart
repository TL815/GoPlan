// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import '../../domain/assistant/assistant_request.dart';
import '../../domain/assistant/assistant_response.dart';
import '../../domain/assistant/assistant_status.dart';
import '../../domain/assistant/client_event.dart';
import '../../domain/assistant/client_event_type.dart';
import '../../domain/itinerary/itinerary.dart';
import '../../domain/itinerary/itinerary_warning.dart';
import '../../domain/trip/trip_state.dart';
import 'travel_assistant_exception.dart';
import 'travel_assistant_failure.dart';
import 'travel_assistant_gateway.dart';
import 'travel_assistant_message.dart';
import 'travel_assistant_message_role.dart';
import 'travel_assistant_phase.dart';
import 'travel_assistant_state.dart';

/// Pure Dart coordinator between UI-facing state and assistant gateways.
class TravelAssistantController {
  TravelAssistantController({
    required TravelAssistantGateway gateway,
    required String userId,
    required String tripId,
    String timezone = 'Asia/Shanghai',
    String? initialConversationId,
    List<TravelAssistantMessage> initialMessages = const [],
    TripState? initialTripState,
    Itinerary? initialItinerary,
    List<ItineraryWarning> initialWarnings = const [],
    AssistantStatus? initialAssistantStatus,
    DateTime Function()? now,
  }) : _gateway = gateway,
       _now = now ?? DateTime.now {
    final normalizedUserId = userId.trim();
    final normalizedTripId = tripId.trim();
    if (normalizedUserId.isEmpty) {
      throw ArgumentError.value(userId, 'userId', 'must not be empty');
    }
    if (normalizedTripId.isEmpty) {
      throw ArgumentError.value(tripId, 'tripId', 'must not be empty');
    }

    _state = TravelAssistantState.initial(
      userId: normalizedUserId,
      tripId: normalizedTripId,
      timezone: timezone,
      conversationId: initialConversationId,
      messages: initialMessages,
      tripState: initialTripState,
      itinerary: initialItinerary,
      warnings: initialWarnings,
      assistantStatus: initialAssistantStatus,
    );
    _messageSequence = _initialMessageSequence(initialMessages);
  }

  final TravelAssistantGateway _gateway;
  final DateTime Function() _now;
  final StreamController<TravelAssistantState> _statesController =
      StreamController<TravelAssistantState>.broadcast();

  late TravelAssistantState _state;
  int _messageSequence = 0;
  _LastOperation? _lastOperation;
  bool _disposed = false;

  TravelAssistantState get state => _state;

  Stream<TravelAssistantState> get states => _statesController.stream;

  Future<AssistantResponse?> sendMessage(String text) {
    _ensureActive();
    final trimmed = text.trim();
    if (trimmed.isEmpty || _state.isSending) return Future.value();

    final event = ClientEvent(
      type: ClientEventType.chatMessage,
      field: 'message',
      payload: {'message': trimmed},
      occurredAt: _now(),
    );
    final operation = _LastOperation(
      query: trimmed,
      event: event,
      displayText: trimmed,
    );
    return _sendOperation(operation, addUserMessage: true);
  }

  Future<AssistantResponse?> submitEvent(
    ClientEvent event, {
    String query = '',
    String? displayText,
  }) {
    _ensureActive();
    if (_state.isSending) return Future.value();

    final text = _displayTextForEvent(event, displayText);
    final operation = _LastOperation(
      query: query.trim(),
      event: event,
      displayText: text,
    );
    return _sendOperation(operation, addUserMessage: true);
  }

  Future<AssistantResponse?> retryLast() {
    _ensureActive();
    if (_state.isSending) return Future.value();
    final failure = _state.lastFailure;
    final operation = _lastOperation;
    if (failure == null || !failure.retryable || operation == null) {
      return Future.value();
    }
    return _sendOperation(operation, addUserMessage: false);
  }

  void clearFailure() {
    _ensureActive();
    if (_state.isSending) return;
    if (_state.phase != TravelAssistantPhase.failure &&
        _state.lastFailure == null) {
      return;
    }

    final nextPhase = _state.lastResponse == null
        ? TravelAssistantPhase.idle
        : TravelAssistantPhase.ready;
    _emit(_state.copyWith(phase: nextPhase, lastFailure: null));
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _state = _state.copyWith(phase: TravelAssistantPhase.disposed);
    _statesController.close();
  }

  Future<AssistantResponse?> _sendOperation(
    _LastOperation operation, {
    required bool addUserMessage,
  }) async {
    _lastOperation = operation;
    var messages = _state.messages;
    if (addUserMessage) {
      messages = [
        ...messages,
        _createMessage(
          role: TravelAssistantMessageRole.user,
          text: operation.displayText,
          event: operation.event,
        ),
      ];
    }

    _emit(
      _state.copyWith(
        phase: TravelAssistantPhase.sending,
        messages: messages,
        lastFailure: null,
      ),
    );

    try {
      final response = await _gateway.send(_requestFor(operation));
      if (_disposed) return null;
      _applyResponse(response);
      return response;
    } on TravelAssistantException catch (error) {
      if (_disposed) return null;
      _applyFailure(error.failure);
      return null;
    } on Object catch (error) {
      if (_disposed) return null;
      _applyFailure(
        TravelAssistantFailure(
          type: TravelAssistantFailureType.unknown,
          message: '旅行助手请求失败。',
          retryable: false,
          cause: error,
        ),
      );
      return null;
    }
  }

  AssistantRequest _requestFor(_LastOperation operation) {
    return AssistantRequest(
      userId: _state.userId,
      tripId: _state.tripId,
      conversationId: _state.conversationId,
      query: operation.query,
      event: operation.event,
      tripSnapshot: _state.tripState?.toJson() ?? const {},
      timezone: _state.timezone,
    );
  }

  void _applyResponse(AssistantResponse response) {
    final assistantText = response.message.trim().isEmpty
        ? 'AI 已返回结果。'
        : response.message;
    final messages = [
      ..._state.messages,
      _createMessage(
        role: TravelAssistantMessageRole.assistant,
        text: assistantText,
        response: response,
      ),
    ];

    _emit(
      _state.copyWith(
        phase: TravelAssistantPhase.ready,
        messages: messages,
        conversationId: response.conversationId ?? _state.conversationId,
        tripState: response.tripState ?? _state.tripState,
        itinerary: response.itinerary ?? _state.itinerary,
        warnings: response.warnings,
        uiAction: response.uiAction,
        assistantStatus: response.status,
        lastResponse: response,
        lastFailure: null,
      ),
    );
  }

  void _applyFailure(TravelAssistantFailure failure) {
    _emit(
      _state.copyWith(
        phase: TravelAssistantPhase.failure,
        lastFailure: failure,
      ),
    );
  }

  TravelAssistantMessage _createMessage({
    required TravelAssistantMessageRole role,
    required String text,
    ClientEvent? event,
    AssistantResponse? response,
  }) {
    _messageSequence += 1;
    return TravelAssistantMessage(
      id: 'message_$_messageSequence',
      role: role,
      text: text,
      createdAt: _now(),
      event: event,
      response: response,
    );
  }

  String _displayTextForEvent(ClientEvent event, String? displayText) {
    final trimmed = displayText?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;

    if (event.type == ClientEventType.chatMessage) {
      final message = event.payload['message']?.toString().trim();
      if (message != null && message.isNotEmpty) return message;
      return '发送了一条旅行消息';
    }

    return switch (event.type) {
      ClientEventType.dateSelected => '已选择出发日期',
      ClientEventType.dateRangeSelected => '已选择旅行日期',
      ClientEventType.optionSelected => '已选择一个选项',
      ClientEventType.numberSubmitted => '已提交数值',
      ClientEventType.confirmationSubmitted => '已确认',
      ClientEventType.dateConflictResolved => '已确认日期方案',
      ClientEventType.replacePlace => '请求替换行程地点',
      ClientEventType.updateDay => '请求调整每日行程',
      ClientEventType.retry => '重新尝试上一次操作',
      ClientEventType.unknown => '提交了一项旅行操作',
      ClientEventType.chatMessage => '发送了一条旅行消息',
    };
  }

  void _emit(TravelAssistantState nextState) {
    _state = nextState;
    if (!_disposed && !_statesController.isClosed) {
      _statesController.add(nextState);
    }
  }

  void _ensureActive() {
    if (_disposed || _state.phase == TravelAssistantPhase.disposed) {
      throw StateError('TravelAssistantController has been disposed.');
    }
  }

  static int _initialMessageSequence(List<TravelAssistantMessage> messages) {
    var maxSequence = 0;
    for (final message in messages) {
      final id = message.id;
      if (!id.startsWith('message_')) continue;
      final sequence = int.tryParse(id.substring('message_'.length));
      if (sequence != null && sequence > maxSequence) {
        maxSequence = sequence;
      }
    }
    return maxSequence;
  }
}

class _LastOperation {
  const _LastOperation({
    required this.query,
    required this.event,
    required this.displayText,
  });

  final String query;
  final ClientEvent event;
  final String displayText;
}

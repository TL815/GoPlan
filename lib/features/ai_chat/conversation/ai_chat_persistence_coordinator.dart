// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:goplan/application/assistant/conversation/conversation_store.dart';
import 'package:goplan/application/assistant/conversation/conversation_store_exception.dart';
import 'package:goplan/application/assistant/conversation/travel_assistant_session_mapper.dart';
import 'package:goplan/application/assistant/travel_assistant_controller.dart';
import 'package:goplan/application/assistant/travel_assistant_state.dart';

class AiChatPersistenceCoordinator {
  AiChatPersistenceCoordinator({
    required TravelAssistantController controller,
    required ConversationStore store,
    required TravelAssistantSessionMapper mapper,
    required String localConversationId,
    required DateTime createdAt,
    DateTime Function()? now,
    Duration debounceDuration = const Duration(milliseconds: 300),
    void Function(ConversationStoreException error)? onError,
  }) : _controller = controller,
       _store = store,
       _mapper = mapper,
       _localConversationId = localConversationId,
       _createdAt = createdAt,
       _now = now ?? DateTime.now,
       _debounceDuration = debounceDuration,
       _onError = onError;

  final TravelAssistantController _controller;
  final ConversationStore _store;
  final TravelAssistantSessionMapper _mapper;
  final String _localConversationId;
  final DateTime _createdAt;
  final DateTime Function() _now;
  final Duration _debounceDuration;
  final void Function(ConversationStoreException error)? _onError;

  StreamSubscription<TravelAssistantState>? _subscription;
  Timer? _timer;
  TravelAssistantState? _pendingState;
  Future<void>? _activeSave;
  bool _started = false;
  bool _disposed = false;
  bool _saveAgain = false;

  void start() {
    if (_started) {
      throw StateError('AiChatPersistenceCoordinator already started.');
    }
    _started = true;
    _pendingState = _controller.state;
    _subscription = _controller.states.listen(_schedule);
  }

  Future<void> flush() async {
    _timer?.cancel();
    _timer = null;
    _pendingState = _controller.state;
    await _drainPending();
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await flush();
    await _subscription?.cancel();
    _subscription = null;
    _timer?.cancel();
    _timer = null;
  }

  void _schedule(TravelAssistantState state) {
    if (_disposed) return;
    _pendingState = state;
    _timer?.cancel();
    _timer = Timer(_debounceDuration, () {
      _timer = null;
      unawaited(_drainPending());
    });
  }

  Future<void> _drainPending() async {
    if (_activeSave != null) {
      _saveAgain = true;
      await _activeSave;
      return;
    }

    do {
      _saveAgain = false;
      final state = _pendingState;
      _pendingState = null;
      if (state == null || _isBlank(state)) continue;

      final save = _save(state);
      _activeSave = save;
      try {
        await save;
      } finally {
        _activeSave = null;
      }
    } while (_saveAgain || _pendingState != null);
  }

  Future<void> _save(TravelAssistantState state) async {
    try {
      await _store.save(
        _mapper.fromState(
          state: state,
          localConversationId: _localConversationId,
          createdAt: _createdAt,
          updatedAt: _now(),
        ),
      );
    } on ConversationStoreException catch (error) {
      _onError?.call(error);
    }
  }

  bool _isBlank(TravelAssistantState state) {
    return state.messages.isEmpty &&
        state.conversationId == null &&
        state.tripState == null &&
        state.itinerary == null;
  }
}

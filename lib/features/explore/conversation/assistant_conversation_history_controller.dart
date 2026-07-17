// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:goplan/application/assistant/conversation/conversation_store.dart';

import 'assistant_conversation_history_state.dart';

class AssistantConversationHistoryController extends ChangeNotifier {
  AssistantConversationHistoryController({
    required ConversationStore store,
    required String userId,
  }) : _store = store,
       _userId = userId;

  final ConversationStore _store;
  final String _userId;
  AssistantConversationHistoryState _state =
      const AssistantConversationHistoryState.loading();
  int _loadGeneration = 0;
  bool _disposed = false;

  AssistantConversationHistoryState get state => _state;

  Future<void> load() async {
    final generation = ++_loadGeneration;
    _setState(const AssistantConversationHistoryState.loading());
    try {
      final summaries = await _store.listForUser(_userId);
      if (_disposed || generation != _loadGeneration) return;
      _setState(AssistantConversationHistoryState.ready(summaries));
    } on Object {
      if (_disposed || generation != _loadGeneration) return;
      _setState(const AssistantConversationHistoryState.failure());
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _setState(AssistantConversationHistoryState next) {
    _state = next;
    if (!_disposed) notifyListeners();
  }
}

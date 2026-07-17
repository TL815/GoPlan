import 'package:goplan/application/assistant/conversation/conversation_store.dart';
import 'package:goplan/data/assistant/conversation/shared_preferences_conversation_store.dart';
import 'package:goplan/data/assistant/conversation/shared_preferences_string_store.dart';

ConversationStore createProductionConversationStore() {
  try {
    return SharedPreferencesConversationStore(
      stringStore: SharedPreferencesStringStore(),
    );
  } on StateError {
    return SharedPreferencesConversationStore(
      stringStore: _MemoryStringStore(),
    );
  }
}

class _MemoryStringStore implements StringStore {
  final Map<String, String> _values = {};

  @override
  Future<String?> getString(String key) async => _values[key];

  @override
  Future<void> setString(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _values.remove(key);
  }
}

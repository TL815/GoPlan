import 'package:goplan/data/assistant/conversation/shared_preferences_string_store.dart';

class FakeStringStore implements StringStore {
  FakeStringStore({
    Map<String, String>? initialValues,
    this.readError,
    this.writeError,
  }) : values = Map<String, String>.from(initialValues ?? const {});

  final Map<String, String> values;
  Object? readError;
  Object? writeError;

  @override
  Future<String?> getString(String key) async {
    final error = readError;
    if (error != null) throw error;
    return values[key];
  }

  @override
  Future<void> setString(String key, String value) async {
    final error = writeError;
    if (error != null) throw error;
    values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    final error = writeError;
    if (error != null) throw error;
    values.remove(key);
  }
}

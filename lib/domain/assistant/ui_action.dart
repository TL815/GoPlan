import 'ui_action_option.dart';
import 'ui_action_type.dart';

class UiAction {
  UiAction({
    required this.type,
    this.field,
    this.title,
    this.description,
    this.allowCustomInput = false,
    List<UiActionOption> options = const [],
    Map<String, Object?> payload = const {},
  }) : options = List.unmodifiable(options),
       payload = Map.unmodifiable(payload);

  factory UiAction.none() => UiAction(type: UiActionType.none);

  factory UiAction.fromJson(Object? value) {
    if (value is! Map || value.isEmpty) return UiAction.none();
    final json = _stringKeyMap(value);
    final rawOptions = json['options'];
    final options = <UiActionOption>[];
    if (rawOptions is Iterable) {
      for (final option in rawOptions) {
        try {
          options.add(UiActionOption.fromJson(option));
        } on Object {
          // Skip malformed options without failing the whole action.
        }
      }
    }

    return UiAction(
      type: uiActionTypeFromJson(json['type']),
      field: _nullableString(json['field']),
      title: _nullableString(json['title']),
      description: _nullableString(json['description']),
      allowCustomInput: json['allow_custom_input'] == true,
      options: options,
      payload: _stringKeyMap(json['payload']),
    );
  }

  final UiActionType type;
  final String? field;
  final String? title;
  final String? description;
  final bool allowCustomInput;
  final List<UiActionOption> options;
  final Map<String, Object?> payload;

  Map<String, Object?> toJson() => {
    'type': uiActionTypeToJson(type),
    if (field != null) 'field': field,
    if (title != null) 'title': title,
    if (description != null) 'description': description,
    'allow_custom_input': allowCustomInput,
    'options': options.map((option) => option.toJson()).toList(),
    if (payload.isNotEmpty) 'payload': Map<String, Object?>.from(payload),
  };

  static Map<String, Object?> _stringKeyMap(Object? value) {
    if (value is! Map) return const {};
    return value.map((key, value) => MapEntry(key.toString(), value));
  }

  static String? _nullableString(Object? value) {
    if (value == null) return null;
    return value.toString();
  }
}

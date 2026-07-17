class UiActionOption {
  UiActionOption({
    required this.id,
    required this.label,
    this.value,
    this.description,
  });

  factory UiActionOption.fromJson(Object? value) {
    if (value is! Map) {
      final label = _stringValue(value);
      return UiActionOption(id: _fallbackId(label, label), label: label);
    }

    final id = _nullableString(value['id']);
    final optionValue = value['value'];
    final label = _nullableString(value['label']) ?? _stringValue(optionValue);
    return UiActionOption(
      id: id ?? _fallbackId(optionValue, label),
      label: label,
      value: optionValue,
      description: _nullableString(value['description']),
    );
  }

  final String id;
  final String label;
  final Object? value;
  final String? description;

  Map<String, Object?> toJson() => {
    'id': id,
    'label': label,
    if (value != null) 'value': value,
    if (description != null) 'description': description,
  };

  static String _fallbackId(Object? value, String label) {
    final fromValue = _nullableString(value);
    if (fromValue != null && fromValue.isNotEmpty) return fromValue;
    if (label.isNotEmpty) return label;
    return 'option';
  }

  static String _stringValue(Object? value) {
    final text = _nullableString(value);
    return text == null || text.isEmpty ? 'option' : text;
  }

  static String? _nullableString(Object? value) {
    if (value == null) return null;
    return value.toString();
  }
}

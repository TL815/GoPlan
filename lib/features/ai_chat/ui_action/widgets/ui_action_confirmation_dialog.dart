import 'package:flutter/material.dart';
import 'package:goplan/domain/assistant/ui_action.dart';

class UiActionConfirmationDialog extends StatelessWidget {
  const UiActionConfirmationDialog({super.key, required this.action});

  final UiAction action;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_textOr(action.title, '请确认')),
      content: _hasText(action.description) ? Text(action.description!) : null,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(_payloadText(action, 'cancel_label', '暂不确认')),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(_payloadText(action, 'confirm_label', '确认')),
        ),
      ],
    );
  }

  static String _payloadText(UiAction action, String key, String fallback) {
    final value = action.payload[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return fallback;
  }

  static bool _hasText(String? value) =>
      value != null && value.trim().isNotEmpty;

  static String _textOr(String? value, String fallback) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? fallback : trimmed;
  }
}

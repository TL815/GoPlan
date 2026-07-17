import 'package:flutter/material.dart';
import 'package:goplan/domain/assistant/ui_action.dart';

class UiActionDateConflictSheet extends StatelessWidget {
  const UiActionDateConflictSheet({super.key, required this.action});

  final UiAction action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _textOr(action.title, '确认日期方案'),
                style: theme.textTheme.titleLarge,
              ),
              if (_hasText(action.description)) ...[
                const SizedBox(height: 8),
                Text(action.description!, style: theme.textTheme.bodyMedium),
              ],
              const SizedBox(height: 16),
              if (action.options.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Text('暂无可选日期方案'),
                )
              else
                ...action.options.map(
                  (option) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(option.label),
                    subtitle: _hasText(option.description)
                        ? Text(option.description!)
                        : null,
                    onTap: () => Navigator.of(context).pop(option),
                  ),
                ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('关闭'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static bool _hasText(String? value) =>
      value != null && value.trim().isNotEmpty;

  static String _textOr(String? value, String fallback) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? fallback : trimmed;
  }
}

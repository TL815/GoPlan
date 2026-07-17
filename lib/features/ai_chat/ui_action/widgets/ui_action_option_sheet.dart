import 'package:flutter/material.dart';
import 'package:goplan/domain/assistant/ui_action.dart';
import 'package:goplan/domain/assistant/ui_action_option.dart';

class UiActionOptionSheet extends StatefulWidget {
  const UiActionOptionSheet({super.key, required this.action});

  final UiAction action;

  @override
  State<UiActionOptionSheet> createState() => _UiActionOptionSheetState();
}

class _UiActionOptionSheetState extends State<UiActionOptionSheet> {
  final TextEditingController _customController = TextEditingController();
  bool _showCustomInput = false;

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final action = widget.action;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 18,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 18,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _textOr(action.title, '选择一个选项'),
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
                  child: Text('暂无可选项'),
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
              if (action.allowCustomInput) ...[
                const Divider(height: 28),
                if (!_showCustomInput)
                  OutlinedButton(
                    onPressed: () => setState(() => _showCustomInput = true),
                    child: const Text('其他 / 自定义输入'),
                  )
                else ...[
                  TextField(
                    controller: _customController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: '自定义选项',
                      hintText: '请输入你的选择',
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submitCustom(context),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => _submitCustom(context),
                    child: const Text('提交'),
                  ),
                ],
              ],
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

  void _submitCustom(BuildContext context) {
    final text = _customController.text.trim();
    if (text.isEmpty) return;
    Navigator.of(
      context,
    ).pop(UiActionOption(id: 'custom', label: text, value: text));
  }

  static bool _hasText(String? value) =>
      value != null && value.trim().isNotEmpty;

  static String _textOr(String? value, String fallback) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? fallback : trimmed;
  }
}

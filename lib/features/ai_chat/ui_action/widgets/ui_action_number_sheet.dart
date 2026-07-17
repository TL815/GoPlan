import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:goplan/domain/assistant/ui_action.dart';

class UiActionNumberSheet extends StatefulWidget {
  const UiActionNumberSheet({super.key, required this.action});

  final UiAction action;

  @override
  State<UiActionNumberSheet> createState() => _UiActionNumberSheetState();
}

class _UiActionNumberSheetState extends State<UiActionNumberSheet> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final initial = widget.action.payload['initial_value'];
    _controller = TextEditingController(
      text: initial == null ? '' : initial.toString(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prefix = _stringPayload('prefix');
    final suffix = _stringPayload('suffix');
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
                _textOr(widget.action.title, '输入数字'),
                style: theme.textTheme.titleLarge,
              ),
              if (_hasText(widget.action.description)) ...[
                const SizedBox(height: 8),
                Text(
                  widget.action.description!,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: false,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: InputDecoration(
                  labelText: '数值',
                  prefixText: prefix,
                  suffixText: suffix,
                  errorText: _errorText,
                ),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 14),
              FilledButton(onPressed: _submit, child: const Text('提交')),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    final text = _controller.text.trim();
    final parsed = num.tryParse(text);
    final min = _numPayload('min');
    final max = _numPayload('max');
    if (parsed == null) {
      setState(() => _errorText = '请输入有效数字');
      return;
    }
    if (min != null && parsed < min) {
      setState(() => _errorText = '数值不能小于 $min');
      return;
    }
    if (max != null && parsed > max) {
      setState(() => _errorText = '数值不能大于 $max');
      return;
    }
    Navigator.of(context).pop(_preferInt(text, parsed));
  }

  num _preferInt(String text, num parsed) {
    if (!text.contains('.') && parsed is int) return parsed;
    if (!text.contains('.')) return parsed.toInt();
    return parsed.toDouble();
  }

  num? _numPayload(String key) {
    final value = widget.action.payload[key];
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }

  String? _stringPayload(String key) {
    final value = widget.action.payload[key];
    if (value is String && value.trim().isNotEmpty) return value;
    return null;
  }

  static bool _hasText(String? value) =>
      value != null && value.trim().isNotEmpty;

  static String _textOr(String? value, String fallback) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? fallback : trimmed;
  }
}

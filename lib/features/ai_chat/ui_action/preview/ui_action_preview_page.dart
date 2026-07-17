import 'package:flutter/material.dart';
import 'package:goplan/application/assistant/ui_action/date_range_selection.dart';
import 'package:goplan/domain/assistant/ui_action.dart';
import 'package:goplan/domain/assistant/ui_action_option.dart';
import 'package:goplan/domain/assistant/ui_action_type.dart';

import '../flutter_ui_action_interaction_port.dart';

class UiActionPreviewPage extends StatefulWidget {
  const UiActionPreviewPage({super.key});

  @override
  State<UiActionPreviewPage> createState() => _UiActionPreviewPageState();
}

class _UiActionPreviewPageState extends State<UiActionPreviewPage> {
  late final FlutterUiActionInteractionPort _port;
  String _lastResult = '暂无结果';

  @override
  void initState() {
    super.initState();
    _port = FlutterUiActionInteractionPort(
      contextProvider: () => context,
      isMounted: () => mounted,
      today: () => DateTime(2026, 7, 15),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GoPlan UiAction 组件预览')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(_lastResult, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 18),
            _PreviewButton(label: '单日期', onPressed: _singleDate),
            _PreviewButton(label: '日期范围', onPressed: _dateRange),
            _PreviewButton(label: '单选项', onPressed: _singleOption),
            _PreviewButton(label: '自定义选项', onPressed: _customOption),
            _PreviewButton(label: '数字输入', onPressed: _numberInput),
            _PreviewButton(label: '确认操作', onPressed: _confirm),
            _PreviewButton(label: '日期冲突', onPressed: _dateConflict),
          ],
        ),
      ),
    );
  }

  Future<void> _singleDate() async {
    final result = await _port.requestStartDate(
      UiAction(type: UiActionType.requestStartDate, title: '选择出发日期'),
    );
    _setResult(result?.toIso8601String() ?? '已取消');
  }

  Future<void> _dateRange() async {
    final result = await _port.requestDateRange(
      UiAction(type: UiActionType.requestDateRange, title: '选择旅行日期'),
    );
    _setResult(_rangeText(result));
  }

  Future<void> _singleOption() async {
    final result = await _port.selectOption(
      UiAction(
        type: UiActionType.selectOption,
        title: '选择旅行节奏',
        options: _paceOptions,
      ),
    );
    _setResult(result?.label ?? '已取消');
  }

  Future<void> _customOption() async {
    final result = await _port.selectOption(
      UiAction(
        type: UiActionType.selectOption,
        title: '选择或输入地点',
        allowCustomInput: true,
        options: _paceOptions,
      ),
    );
    _setResult(result == null ? '已取消' : '${result.id}: ${result.label}');
  }

  Future<void> _numberInput() async {
    final result = await _port.inputNumber(
      UiAction(
        type: UiActionType.inputNumber,
        title: '出行人数',
        payload: {'min': 1, 'max': 12, 'suffix': '人'},
      ),
    );
    _setResult(result?.toString() ?? '已取消');
  }

  Future<void> _confirm() async {
    final result = await _port.confirm(
      UiAction(
        type: UiActionType.confirm,
        title: '确认计划',
        description: '使用已选择的日期安排这次旅行吗？',
      ),
    );
    _setResult(result == null ? '已取消' : result.toString());
  }

  Future<void> _dateConflict() async {
    final result = await _port.confirmDateConflict(
      UiAction(
        type: UiActionType.confirmDateConflict,
        title: '确认日期方案',
        options: [
          UiActionOption(id: 'keep', label: '保留已选日期', value: 'keep'),
          UiActionOption(id: 'adjust', label: '调整为 7 天', value: 'adjust'),
        ],
      ),
    );
    _setResult(result?.label ?? '已取消');
  }

  void _setResult(String value) {
    if (!mounted) return;
    setState(() => _lastResult = value);
  }

  static String _rangeText(DateRangeSelection? range) {
    if (range == null) return '已取消';
    return '${range.start.toIso8601String()} - ${range.end.toIso8601String()}';
  }

  static final _paceOptions = [
    UiActionOption(id: 'relaxed', label: '轻松', value: 'relaxed'),
    UiActionOption(id: 'balanced', label: '均衡', value: 'balanced'),
    UiActionOption(id: 'packed', label: '紧凑', value: 'packed'),
  ];
}

class _PreviewButton extends StatelessWidget {
  const _PreviewButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: FilledButton(onPressed: onPressed, child: Text(label)),
    );
  }
}

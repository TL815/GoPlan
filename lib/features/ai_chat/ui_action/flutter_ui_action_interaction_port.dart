// ignore_for_file: prefer_initializing_formals

import 'package:flutter/material.dart';
import 'package:goplan/application/assistant/ui_action/date_range_selection.dart';
import 'package:goplan/application/assistant/ui_action/ui_action_interaction_port.dart';
import 'package:goplan/domain/assistant/ui_action.dart';
import 'package:goplan/domain/assistant/ui_action_option.dart';

import 'widgets/ui_action_confirmation_dialog.dart';
import 'widgets/ui_action_date_conflict_sheet.dart';
import 'widgets/ui_action_number_sheet.dart';
import 'widgets/ui_action_option_sheet.dart';

class FlutterUiActionInteractionPort implements UiActionInteractionPort {
  FlutterUiActionInteractionPort({
    required BuildContext Function() contextProvider,
    required bool Function() isMounted,
    DateTime Function()? today,
  }) : _contextProvider = contextProvider,
       _isMounted = isMounted,
       _today = today ?? DateTime.now;

  final BuildContext Function() _contextProvider;
  final bool Function() _isMounted;
  final DateTime Function() _today;

  @override
  Future<DateTime?> requestStartDate(UiAction action) async {
    final context = _context();
    final today = _dateOnly(_today());
    final firstDate =
        _readDate(action, 'first_date') ??
        DateTime(today.year - 1, today.month, today.day);
    final lastDate =
        _readDate(action, 'last_date') ??
        DateTime(today.year + 5, today.month, today.day);
    final initial = _clampDate(
      _readDate(action, 'initial_date') ??
          _readDate(action, 'start_date') ??
          today,
      firstDate,
      lastDate,
    );
    final result = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: _textOr(action.title, '选择出发日期'),
    );
    return _isMounted() ? result : null;
  }

  @override
  Future<DateRangeSelection?> requestDateRange(UiAction action) async {
    final context = _context();
    final today = _dateOnly(_today());
    final firstDate =
        _readDate(action, 'first_date') ??
        DateTime(today.year - 1, today.month, today.day);
    final lastDate =
        _readDate(action, 'last_date') ??
        DateTime(today.year + 5, today.month, today.day);
    final initialRange = _initialRange(action, firstDate, lastDate);
    final result = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDateRange: initialRange,
      helpText: _textOr(action.title, '选择旅行日期'),
    );
    if (!_isMounted() || result == null) return null;
    return DateRangeSelection(start: result.start, end: result.end);
  }

  @override
  Future<UiActionOption?> selectOption(UiAction action) async {
    final context = _context();
    final result = await showModalBottomSheet<UiActionOption>(
      context: context,
      isScrollControlled: true,
      builder: (_) => UiActionOptionSheet(action: action),
    );
    return _isMounted() ? result : null;
  }

  @override
  Future<num?> inputNumber(UiAction action) async {
    final context = _context();
    final result = await showModalBottomSheet<num>(
      context: context,
      isScrollControlled: true,
      builder: (_) => UiActionNumberSheet(action: action),
    );
    return _isMounted() ? result : null;
  }

  @override
  Future<bool?> confirm(UiAction action) async {
    final context = _context();
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => UiActionConfirmationDialog(action: action),
    );
    return _isMounted() ? result : null;
  }

  @override
  Future<UiActionOption?> confirmDateConflict(UiAction action) async {
    final context = _context();
    final result = await showModalBottomSheet<UiActionOption>(
      context: context,
      isScrollControlled: true,
      builder: (_) => UiActionDateConflictSheet(action: action),
    );
    return _isMounted() ? result : null;
  }

  BuildContext _context() {
    if (!_isMounted()) {
      throw StateError('UiAction host is not mounted.');
    }
    return _contextProvider();
  }

  DateTimeRange? _initialRange(
    UiAction action,
    DateTime firstDate,
    DateTime lastDate,
  ) {
    final start = _readDate(action, 'start_date');
    final end = _readDate(action, 'end_date');
    if (start == null || end == null) return null;
    if (start.isBefore(firstDate) ||
        end.isAfter(lastDate) ||
        end.isBefore(start)) {
      return null;
    }
    return DateTimeRange(start: start, end: end);
  }

  DateTime? _readDate(UiAction action, String key) {
    final value = action.payload[key];
    if (value is DateTime) return _dateOnly(value);
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return _dateOnly(parsed);
    }
    return null;
  }

  static DateTime _clampDate(
    DateTime value,
    DateTime firstDate,
    DateTime lastDate,
  ) {
    if (value.isBefore(firstDate)) return firstDate;
    if (value.isAfter(lastDate)) return lastDate;
    return value;
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static String _textOr(String? value, String fallback) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? fallback : trimmed;
  }
}

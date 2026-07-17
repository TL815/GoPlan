import 'package:goplan/application/assistant/ui_action/date_range_selection.dart';
import 'package:goplan/application/assistant/ui_action/ui_action_interaction_port.dart';
import 'package:goplan/domain/assistant/ui_action.dart';
import 'package:goplan/domain/assistant/ui_action_option.dart';

class FakeUiActionInteractionPort implements UiActionInteractionPort {
  FakeUiActionInteractionPort({
    this.startDateResult,
    this.dateRangeResult,
    this.selectedOptionResult,
    this.numberResult,
    this.confirmationResult,
    this.dateConflictOptionResult,
    this.exception,
    this.startDateHandler,
    this.dateRangeHandler,
    this.optionHandler,
    this.numberHandler,
    this.confirmationHandler,
    this.dateConflictHandler,
  });

  DateTime? startDateResult;
  DateRangeSelection? dateRangeResult;
  UiActionOption? selectedOptionResult;
  num? numberResult;
  bool? confirmationResult;
  UiActionOption? dateConflictOptionResult;
  Object? exception;

  Future<DateTime?> Function(UiAction action)? startDateHandler;
  Future<DateRangeSelection?> Function(UiAction action)? dateRangeHandler;
  Future<UiActionOption?> Function(UiAction action)? optionHandler;
  Future<num?> Function(UiAction action)? numberHandler;
  Future<bool?> Function(UiAction action)? confirmationHandler;
  Future<UiActionOption?> Function(UiAction action)? dateConflictHandler;

  int requestStartDateCount = 0;
  int requestDateRangeCount = 0;
  int selectOptionCount = 0;
  int inputNumberCount = 0;
  int confirmCount = 0;
  int confirmDateConflictCount = 0;

  UiAction? lastAction;

  int get totalCallCount =>
      requestStartDateCount +
      requestDateRangeCount +
      selectOptionCount +
      inputNumberCount +
      confirmCount +
      confirmDateConflictCount;

  @override
  Future<DateTime?> requestStartDate(UiAction action) async {
    requestStartDateCount += 1;
    lastAction = action;
    _throwIfNeeded();
    final handler = startDateHandler;
    if (handler != null) return handler(action);
    return startDateResult;
  }

  @override
  Future<DateRangeSelection?> requestDateRange(UiAction action) async {
    requestDateRangeCount += 1;
    lastAction = action;
    _throwIfNeeded();
    final handler = dateRangeHandler;
    if (handler != null) return handler(action);
    return dateRangeResult;
  }

  @override
  Future<UiActionOption?> selectOption(UiAction action) async {
    selectOptionCount += 1;
    lastAction = action;
    _throwIfNeeded();
    final handler = optionHandler;
    if (handler != null) return handler(action);
    return selectedOptionResult;
  }

  @override
  Future<num?> inputNumber(UiAction action) async {
    inputNumberCount += 1;
    lastAction = action;
    _throwIfNeeded();
    final handler = numberHandler;
    if (handler != null) return handler(action);
    return numberResult;
  }

  @override
  Future<bool?> confirm(UiAction action) async {
    confirmCount += 1;
    lastAction = action;
    _throwIfNeeded();
    final handler = confirmationHandler;
    if (handler != null) return handler(action);
    return confirmationResult;
  }

  @override
  Future<UiActionOption?> confirmDateConflict(UiAction action) async {
    confirmDateConflictCount += 1;
    lastAction = action;
    _throwIfNeeded();
    final handler = dateConflictHandler;
    if (handler != null) return handler(action);
    return dateConflictOptionResult;
  }

  void _throwIfNeeded() {
    final error = exception;
    if (error != null) throw error;
  }
}

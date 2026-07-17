import '../../../domain/assistant/ui_action.dart';
import '../../../domain/assistant/ui_action_option.dart';
import 'date_range_selection.dart';

/// Pure Dart interface implemented by UI adapters that collect user input.
///
/// Implementations may show Flutter components in a presentation layer, but
/// this port deliberately exposes no BuildContext, Widget, Navigator, or
/// controller dependency.
abstract interface class UiActionInteractionPort {
  Future<DateTime?> requestStartDate(UiAction action);

  Future<DateRangeSelection?> requestDateRange(UiAction action);

  Future<UiActionOption?> selectOption(UiAction action);

  Future<num?> inputNumber(UiAction action);

  Future<bool?> confirm(UiAction action);

  Future<UiActionOption?> confirmDateConflict(UiAction action);
}

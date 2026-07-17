import 'package:goplan/domain/itinerary/budget_summary.dart';

class ItineraryFormatters {
  const ItineraryFormatters._();

  static String textOrFallback(String? value, String fallback) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? fallback : trimmed;
  }

  static String formatDate(DateTime? date, {bool includeYear = true}) {
    if (date == null) return '';
    if (includeYear) return '${date.year}年${date.month}月${date.day}日';
    return '${date.month}月${date.day}日';
  }

  static String formatTimeRange(String? startTime, String? endTime) {
    final start = startTime?.trim();
    final end = endTime?.trim();
    if (start != null && start.isNotEmpty && end != null && end.isNotEmpty) {
      return '$start–$end';
    }
    if (start != null && start.isNotEmpty) return start;
    return '时间待定';
  }

  static String formatDuration(int? minutes) {
    if (minutes == null) return '';
    if (minutes < 60) return '$minutes分钟';
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    if (rest == 0) return '$hours小时';
    return '$hours小时$rest分钟';
  }

  static String formatMoney(
    num? amount, {
    String? currency,
    BudgetSummary? budget,
  }) {
    if (amount == null) return '';
    final number = amount % 1 == 0 ? amount.toInt().toString() : '$amount';
    final code = textOrFallback(currency, budget?.currency ?? '').toUpperCase();
    if (code.isEmpty) return number;
    final symbol = switch (code) {
      'CNY' || 'RMB' => '¥',
      'USD' => r'$',
      'EUR' => '€',
      'JPY' => '¥',
      _ => '$code ',
    };
    return '$symbol$number';
  }

  static String formatDayCount(int count) => '$count天';
}

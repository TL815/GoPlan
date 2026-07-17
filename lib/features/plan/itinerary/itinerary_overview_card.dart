import 'package:flutter/material.dart';
import 'package:goplan/domain/itinerary/itinerary.dart';
import 'package:goplan/domain/itinerary/itinerary_warning.dart';

import 'itinerary_empty_state.dart';
import 'itinerary_formatters.dart';
import 'itinerary_warnings_card.dart';
import 'widgets/itinerary_info_chip.dart';

class ItineraryOverviewCard extends StatelessWidget {
  const ItineraryOverviewCard({
    super.key,
    required this.itinerary,
    this.additionalWarnings = const [],
    this.onOpenDetails,
    this.budgetSectionKey,
  });

  final Itinerary itinerary;
  final List<ItineraryWarning> additionalWarnings;
  final VoidCallback? onOpenDetails;
  final Key? budgetSectionKey;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final title = ItineraryFormatters.textOrFallback(itinerary.title, '旅行计划');
    final budget = itinerary.budgetSummary;
    final warnings = ItineraryWarningsCard.dedupe([
      ...itinerary.warnings,
      ...additionalWarnings,
    ]);
    final budgetText = ItineraryFormatters.formatMoney(
      budget?.total,
      budget: budget,
    );
    final previewDays = itinerary.days.take(3).toList();
    final remain = itinerary.days.length - previewDays.length;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (itinerary.destination?.trim().isNotEmpty == true)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            itinerary.destination!.trim(),
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (itinerary.isDraft)
                  const ItineraryInfoChip(
                    icon: Icons.edit_note_rounded,
                    label: '草案',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ItineraryInfoChip(
                  icon: Icons.calendar_month_outlined,
                  label: ItineraryFormatters.formatDayCount(
                    itinerary.days.length,
                  ),
                ),
                if (budgetText.isNotEmpty)
                  ItineraryInfoChip(
                    key: budgetSectionKey,
                    icon: Icons.payments_outlined,
                    label: budgetText,
                  ),
                if (warnings.isNotEmpty)
                  ItineraryInfoChip(
                    icon: Icons.warning_amber_rounded,
                    label: '${warnings.length} 条提示',
                  ),
              ],
            ),
            const SizedBox(height: 14),
            if (itinerary.days.isEmpty)
              const ItineraryEmptyState()
            else ...[
              for (final day in previewDays)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _dayLine(dayIndex: day.dayIndex, title: day.title),
                    style: TextStyle(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              if (remain > 0)
                Text(
                  '还有 $remain 天',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
            if (onOpenDetails != null) ...[
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onOpenDetails,
                  icon: const Icon(Icons.chevron_right_rounded),
                  label: const Text('查看完整行程'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _dayLine({required int dayIndex, required String title}) {
    final dayLabel = dayIndex > 0 ? '第 $dayIndex 天' : '当天';
    final dayTitle = title.trim();
    if (dayTitle.isEmpty || dayTitle == dayLabel) return dayLabel;
    return '$dayLabel · $dayTitle';
  }
}

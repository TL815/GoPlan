import 'package:flutter/material.dart';
import 'package:goplan/domain/itinerary/budget_summary.dart';
import 'package:goplan/domain/itinerary/itinerary_day.dart';

import 'itinerary_empty_state.dart';
import 'itinerary_formatters.dart';
import 'itinerary_item_tile.dart';
import 'widgets/itinerary_info_chip.dart';

class ItineraryDayCard extends StatelessWidget {
  const ItineraryDayCard({
    super.key,
    required this.day,
    required this.position,
    this.budget,
  });

  final ItineraryDay day;
  final int position;
  final BudgetSummary? budget;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final resolvedIndex = day.dayIndex > 0 ? day.dayIndex : position + 1;
    final fallbackTitle = day.dayIndex <= 0 && position < 0
        ? '当天'
        : '第 $resolvedIndex 天';
    final title = ItineraryFormatters.textOrFallback(day.title, fallbackTitle);
    final cost = ItineraryFormatters.formatMoney(
      day.estimatedCost,
      budget: budget,
    );

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                fallbackTitle,
                style: TextStyle(
                  color: colors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (day.date != null) ...[
              const SizedBox(height: 5),
              Text(
                ItineraryFormatters.formatDate(day.date),
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            if (day.summary?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 10),
              Text(
                day.summary!.trim(),
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (cost.isNotEmpty) ...[
              const SizedBox(height: 10),
              ItineraryInfoChip(icon: Icons.payments_outlined, label: cost),
            ],
            if (day.warnings.where((w) => w.trim().isNotEmpty).isNotEmpty) ...[
              const SizedBox(height: 12),
              for (final warning in day.warnings.where(
                (w) => w.trim().isNotEmpty,
              ))
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: colors.tertiary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          warning.trim(),
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 14),
            if (day.items.isEmpty)
              const ItineraryEmptyState(message: '当天安排暂未生成')
            else
              for (var i = 0; i < day.items.length; i++)
                ItineraryItemTile(
                  item: day.items[i],
                  isLast: i == day.items.length - 1,
                  budget: budget,
                ),
          ],
        ),
      ),
    );
  }
}

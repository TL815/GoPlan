import 'package:flutter/material.dart';
import 'package:goplan/domain/itinerary/budget_summary.dart';

import 'itinerary_formatters.dart';
import 'widgets/itinerary_section_title.dart';

class ItineraryBudgetCard extends StatelessWidget {
  const ItineraryBudgetCard({super.key, required this.budget});

  final BudgetSummary? budget;

  static bool hasContent(BudgetSummary? budget) {
    return budget?.total != null ||
        budget?.perPerson != null ||
        budget?.transport != null ||
        budget?.accommodation != null ||
        budget?.food != null ||
        budget?.tickets != null ||
        budget?.other != null;
  }

  @override
  Widget build(BuildContext context) {
    final budget = this.budget;
    if (!hasContent(budget)) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    final items = <_BudgetLine>[
      _BudgetLine('交通', budget!.transport),
      _BudgetLine('住宿', budget.accommodation),
      _BudgetLine('餐饮', budget.food),
      _BudgetLine('门票', budget.tickets),
      _BudgetLine('其他', budget.other),
    ].where((item) => item.value != null).toList();

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ItinerarySectionTitle(
              title: '预算概览',
              icon: Icons.payments_outlined,
            ),
            if (budget.total != null) ...[
              const SizedBox(height: 12),
              Text(
                ItineraryFormatters.formatMoney(budget.total, budget: budget),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: colors.onSurface,
                ),
              ),
            ],
            if (budget.perPerson != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '人均 ${ItineraryFormatters.formatMoney(budget.perPerson, budget: budget)}',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            if (items.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final item in items)
                    _BudgetPill(
                      label: item.label,
                      value: ItineraryFormatters.formatMoney(
                        item.value,
                        budget: budget,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BudgetLine {
  const _BudgetLine(this.label, this.value);
  final String label;
  final num? value;
}

class _BudgetPill extends StatelessWidget {
  const _BudgetPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: .62),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label $value',
        style: TextStyle(
          color: colors.onSurfaceVariant,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

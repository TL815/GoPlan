import 'package:flutter/material.dart';
import 'package:goplan/domain/itinerary/itinerary.dart';
import 'package:goplan/domain/itinerary/itinerary_warning.dart';

import 'itinerary_budget_card.dart';
import 'itinerary_day_card.dart';
import 'itinerary_empty_state.dart';
import 'itinerary_formatters.dart';
import 'itinerary_header.dart';
import 'itinerary_warnings_card.dart';

class ItineraryDetailPage extends StatelessWidget {
  const ItineraryDetailPage({
    super.key,
    required this.itinerary,
    this.additionalWarnings = const [],
  });

  final Itinerary itinerary;
  final List<ItineraryWarning> additionalWarnings;

  @override
  Widget build(BuildContext context) {
    final title = ItineraryFormatters.textOrFallback(itinerary.title, '旅行计划');
    final warnings = ItineraryWarningsCard.dedupe([
      ...itinerary.warnings,
      ...additionalWarnings,
    ]);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
          children: [
            ItineraryHeader(itinerary: itinerary),
            if (warnings.isNotEmpty) ...[
              const SizedBox(height: 16),
              ItineraryWarningsCard(warnings: warnings),
            ],
            const SizedBox(height: 16),
            if (itinerary.days.isEmpty)
              const ItineraryEmptyState()
            else
              for (var i = 0; i < itinerary.days.length; i++) ...[
                ItineraryDayCard(
                  day: itinerary.days[i],
                  position: i,
                  budget: itinerary.budgetSummary,
                ),
                const SizedBox(height: 14),
              ],
            if (ItineraryBudgetCard.hasContent(itinerary.budgetSummary)) ...[
              const SizedBox(height: 2),
              ItineraryBudgetCard(budget: itinerary.budgetSummary),
            ],
          ],
        ),
      ),
    );
  }
}

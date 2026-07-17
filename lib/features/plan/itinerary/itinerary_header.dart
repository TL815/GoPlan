import 'package:flutter/material.dart';
import 'package:goplan/domain/itinerary/itinerary.dart';

import 'itinerary_formatters.dart';
import 'widgets/itinerary_info_chip.dart';

class ItineraryHeader extends StatelessWidget {
  const ItineraryHeader({super.key, required this.itinerary});

  final Itinerary itinerary;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final title = ItineraryFormatters.textOrFallback(itinerary.title, '旅行计划');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 24,
            height: 1.18,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (itinerary.destination?.trim().isNotEmpty == true) ...[
          const SizedBox(height: 8),
          Text(
            itinerary.destination!.trim(),
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ItineraryInfoChip(
              icon: Icons.calendar_month_outlined,
              label: ItineraryFormatters.formatDayCount(itinerary.days.length),
            ),
            if (itinerary.isDraft)
              const ItineraryInfoChip(
                icon: Icons.edit_note_rounded,
                label: '草案',
              ),
          ],
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:goplan/domain/itinerary/budget_summary.dart';
import 'package:goplan/domain/itinerary/itinerary_item.dart';

import 'itinerary_formatters.dart';
import 'widgets/itinerary_info_chip.dart';
import 'widgets/itinerary_timeline_indicator.dart';

class ItineraryItemTile extends StatelessWidget {
  const ItineraryItemTile({
    super.key,
    required this.item,
    required this.isLast,
    this.budget,
  });

  final ItineraryItem item;
  final bool isLast;
  final BudgetSummary? budget;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final place = item.place;
    final title = ItineraryFormatters.textOrFallback(
      item.title,
      ItineraryFormatters.textOrFallback(place?.name, '未命名活动'),
    );
    final placeName = place?.name.trim() ?? '';
    final location = _locationLine();
    final chips = _chips();

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 58,
            child: Text(
              ItineraryFormatters.formatTimeRange(item.startTime, item.endTime),
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
          ),
          ItineraryTimelineIndicator(isLast: isLast),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (placeName.isNotEmpty && placeName != title) ...[
                    const SizedBox(height: 5),
                    Text(
                      placeName,
                      style: TextStyle(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  if (location != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      location,
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (place?.category?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Text(
                      place!.category!.trim(),
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  if (chips.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, runSpacing: 8, children: chips),
                  ],
                  if (item.description?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    Text(
                      item.description!.trim(),
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (item.tips.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    for (final tip in item.tips.where(
                      (tip) => tip.trim().isNotEmpty,
                    ))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          '• ${tip.trim()}',
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _locationLine() {
    final place = item.place;
    final address = place?.address?.trim();
    if (address != null && address.isNotEmpty) return address;
    final city = place?.city?.trim();
    if (city != null && city.isNotEmpty) return city;
    return null;
  }

  List<Widget> _chips() {
    final chips = <Widget>[];
    if (item.transportMode?.trim().isNotEmpty == true) {
      chips.add(
        ItineraryInfoChip(
          icon: Icons.directions_transit_outlined,
          label: item.transportMode!.trim(),
        ),
      );
    }
    final transport = ItineraryFormatters.formatDuration(item.transportMinutes);
    if (transport.isNotEmpty) {
      chips.add(
        ItineraryInfoChip(icon: Icons.route_outlined, label: '交通 $transport'),
      );
    }
    final duration = ItineraryFormatters.formatDuration(item.durationMinutes);
    if (duration.isNotEmpty) {
      chips.add(
        ItineraryInfoChip(icon: Icons.schedule_rounded, label: '停留 $duration'),
      );
    }
    final cost = ItineraryFormatters.formatMoney(
      item.estimatedCost,
      currency: item.currency,
      budget: budget,
    );
    if (cost.isNotEmpty) {
      chips.add(ItineraryInfoChip(icon: Icons.payments_outlined, label: cost));
    }
    return chips;
  }
}

import 'package:flutter/material.dart';

class ItineraryTimelineIndicator extends StatelessWidget {
  const ItineraryTimelineIndicator({super.key, required this.isLast});

  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: 20,
      child: Column(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: colors.primary,
              shape: BoxShape.circle,
            ),
          ),
          if (!isLast)
            Expanded(
              child: Container(
                width: 2,
                margin: const EdgeInsets.only(top: 4),
                color: colors.outlineVariant,
              ),
            ),
        ],
      ),
    );
  }
}

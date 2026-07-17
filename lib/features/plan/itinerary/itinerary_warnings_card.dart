import 'package:flutter/material.dart';
import 'package:goplan/domain/itinerary/itinerary_warning.dart';

import 'widgets/itinerary_section_title.dart';

class ItineraryWarningsCard extends StatelessWidget {
  const ItineraryWarningsCard({super.key, required this.warnings});

  final List<ItineraryWarning> warnings;

  static List<ItineraryWarning> dedupe(List<ItineraryWarning> warnings) {
    final seen = <String>{};
    final result = <ItineraryWarning>[];
    for (final warning in warnings) {
      if (warning.message.trim().isEmpty) continue;
      final key = warning.id.trim().isNotEmpty
          ? 'id:${warning.id}'
          : '${warning.type}|${warning.message}|${warning.dayIndex}|${warning.itemId}';
      if (seen.add(key)) result.add(warning);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final visible = dedupe(warnings);
    if (visible.isEmpty) return const SizedBox.shrink();
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ItinerarySectionTitle(
              title: '行程提示',
              icon: Icons.info_outline_rounded,
            ),
            const SizedBox(height: 12),
            for (final warning in visible)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _WarningRow(warning: warning),
              ),
          ],
        ),
      ),
    );
  }
}

class _WarningRow extends StatelessWidget {
  const _WarningRow({required this.warning});

  final ItineraryWarning warning;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final level = _WarningLevel.fromSeverity(warning.severity);
    final accent = switch (level) {
      _WarningLevel.high => colors.error,
      _WarningLevel.medium => colors.tertiary,
      _WarningLevel.info => colors.primary,
    };
    final icon = switch (level) {
      _WarningLevel.high => Icons.error_outline_rounded,
      _WarningLevel.medium => Icons.warning_amber_rounded,
      _WarningLevel.info => Icons.info_outline_rounded,
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: accent, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                [
                  _typeLabel(warning.type),
                  if (warning.dayIndex != null) '第 ${warning.dayIndex} 天',
                  _levelLabel(level),
                ].join(' · '),
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                warning.message,
                style: TextStyle(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _typeLabel(String type) {
    return switch (type.trim().toLowerCase()) {
      'schedule' => '时间安排',
      'transport' => '交通',
      'weather' => '天气',
      'budget' => '预算',
      'closed' => '营业信息',
      'conflict' => '行程冲突',
      _ => '行程提示',
    };
  }

  static String _levelLabel(_WarningLevel level) {
    return switch (level) {
      _WarningLevel.high => '高风险',
      _WarningLevel.medium => '中风险',
      _WarningLevel.info => '提示',
    };
  }
}

enum _WarningLevel {
  high,
  medium,
  info;

  factory _WarningLevel.fromSeverity(String? severity) {
    return switch (severity?.trim().toLowerCase()) {
      'critical' || 'error' || 'high' || 'danger' => _WarningLevel.high,
      'warning' || 'medium' => _WarningLevel.medium,
      _ => _WarningLevel.info,
    };
  }
}

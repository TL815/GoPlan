import '../agent_exception.dart';
import '../models/plan_draft.dart';

class PlanDraftParser {
  const PlanDraftParser();

  PlanDraft parse(Object? value) {
    if (value is! Map<String, Object?>) {
      throw const AgentException('planDraft is missing or invalid.');
    }

    final daysValue = value['days'];
    if (daysValue is! List || daysValue.isEmpty) {
      throw const AgentException('planDraft.days is missing or empty.');
    }

    final days = daysValue
        .whereType<Map<String, Object?>>()
        .map(_parseDay)
        .toList(growable: false);

    return PlanDraft(
      title: _asString(value['title'], fallback: 'Travel Plan'),
      destination: _asString(value['destination'], fallback: 'Unknown'),
      durationDays: _asInt(value['durationDays'], fallback: days.length),
      summary: _asString(value['summary']),
      days: days,
    );
  }

  PlanDraftDay _parseDay(Map<String, Object?> value) {
    return PlanDraftDay(
      day: _asInt(value['day']),
      title: _asString(value['title'], fallback: 'Day plan'),
      route: _asString(value['route']),
      transport: _asString(value['transport']),
      places: _asPlaceList(value['places']),
      food: _asStringList(value['food']),
      tips: _asString(value['tips']),
    );
  }

  List<PlanDraftPlace> _asPlaceList(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<Map<String, Object?>>()
        .map(
          (place) => PlanDraftPlace(
            name: _asString(place['name']),
            category: _asString(place['category'], fallback: 'other'),
            city: _asString(place['city']),
            latitude: _asDouble(place['latitude']),
            longitude: _asDouble(place['longitude']),
            note: _asString(place['note']),
          ),
        )
        .where((place) => place.name.isNotEmpty)
        .toList(growable: false);
  }

  List<String> _asStringList(Object? value) {
    if (value is! List) return const [];
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  String _asString(Object? value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  int _asInt(Object? value, {int fallback = 1}) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  double? _asDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}

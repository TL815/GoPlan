class PlanDraft {
  const PlanDraft({
    required this.title,
    required this.destination,
    required this.durationDays,
    required this.summary,
    required this.days,
  });

  final String title;
  final String destination;
  final int durationDays;
  final String summary;
  final List<PlanDraftDay> days;
}

class PlanDraftDay {
  const PlanDraftDay({
    required this.day,
    required this.title,
    required this.route,
    required this.transport,
    this.places = const [],
    this.food = const [],
    this.tips = '',
  });

  final int day;
  final String title;
  final String route;
  final String transport;
  final List<PlanDraftPlace> places;
  final List<String> food;
  final String tips;
}

class PlanDraftPlace {
  const PlanDraftPlace({
    required this.name,
    required this.category,
    this.city = '',
    this.latitude,
    this.longitude,
    this.note = '',
  });

  final String name;
  final String category;
  final String city;
  final double? latitude;
  final double? longitude;
  final String note;
}

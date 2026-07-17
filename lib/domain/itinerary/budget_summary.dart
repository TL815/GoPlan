class BudgetSummary {
  const BudgetSummary({
    this.total,
    this.currency = 'CNY',
    this.transport,
    this.accommodation,
    this.food,
    this.tickets,
    this.other,
    this.perPerson,
  });

  factory BudgetSummary.fromJson(Map<String, Object?> json) {
    return BudgetSummary(
      total: _parseNum(json['total']),
      currency: _nullableString(json['currency']) ?? 'CNY',
      transport: _parseNum(json['transport']),
      accommodation: _parseNum(json['accommodation']),
      food: _parseNum(json['food']),
      tickets: _parseNum(json['tickets']),
      other: _parseNum(json['other']),
      perPerson: _parseNum(json['per_person']),
    );
  }

  final num? total;
  final String currency;
  final num? transport;
  final num? accommodation;
  final num? food;
  final num? tickets;
  final num? other;
  final num? perPerson;

  Map<String, Object?> toJson() => {
    if (total != null) 'total': total,
    'currency': currency,
    if (transport != null) 'transport': transport,
    if (accommodation != null) 'accommodation': accommodation,
    if (food != null) 'food': food,
    if (tickets != null) 'tickets': tickets,
    if (other != null) 'other': other,
    if (perPerson != null) 'per_person': perPerson,
  };

  static num? _parseNum(Object? value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }

  static String? _nullableString(Object? value) {
    if (value == null) return null;
    return value.toString();
  }
}

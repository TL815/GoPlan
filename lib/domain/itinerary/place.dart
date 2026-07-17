class Place {
  const Place({
    required this.id,
    required this.name,
    this.latitude,
    this.longitude,
    this.category,
    this.address,
    this.city,
    this.source,
  });

  factory Place.fromJson(Map<String, Object?> json) {
    return Place(
      id: _stringValue(json['id']),
      name: _stringValue(json['name']),
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      category: _nullableString(json['category']),
      address: _nullableString(json['address']),
      city: _nullableString(json['city']),
      source: _nullableString(json['source']),
    );
  }

  final String id;
  final String name;
  final double? latitude;
  final double? longitude;
  final String? category;
  final String? address;
  final String? city;
  final String? source;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
    if (category != null) 'category': category,
    if (address != null) 'address': address,
    if (city != null) 'city': city,
    if (source != null) 'source': source,
  };

  static double? _parseDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static String _stringValue(Object? value) {
    if (value == null) return '';
    return value.toString();
  }

  static String? _nullableString(Object? value) {
    if (value == null) return null;
    return value.toString();
  }
}

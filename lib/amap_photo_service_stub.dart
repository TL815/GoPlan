Future<String?> fetchAmapPhotoUrl({
  required String keyword,
  String city = '',
}) async {
  return null;
}

Future<List<String>> fetchAmapPhotoUrls({
  required String keyword,
  String city = '',
}) async {
  return const [];
}

Future<List<AmapPhotoSpot>> fetchAmapPhotoSpots({
  required String keyword,
  String city = '',
}) async {
  return const [];
}

class AmapPhotoSpot {
  const AmapPhotoSpot({
    required this.name,
    required this.city,
    required this.address,
    required this.category,
    required this.tags,
    required this.photoUrl,
  });

  final String name;
  final String city;
  final String address;
  final String category;
  final List<String> tags;
  final String photoUrl;
}

Future<String?> fetchAmapPhotoUrl({
  required String keyword,
  String city = '',
  String types = '',
}) async {
  return null;
}

Future<List<String>> fetchAmapPhotoUrls({
  required String keyword,
  String city = '',
  String types = '',
}) async {
  return const [];
}

Future<List<AmapPhotoSpot>> fetchAmapPhotoSpots({
  required String keyword,
  String city = '',
  String types = '',
}) async {
  return const [];
}

class AmapPhotoSpot {
  const AmapPhotoSpot({
    this.id = '',
    required this.name,
    required this.city,
    required this.address,
    required this.category,
    required this.tags,
    required this.photoUrl,
    this.photoUrls = const [],
    this.photoTitles = const [],
    this.typecode = '',
    this.province = '',
    this.district = '',
    this.location = '',
    this.longitude,
    this.latitude,
    this.tel = '',
    this.website = '',
    this.email = '',
    this.postcode = '',
    this.alias = '',
    this.businessArea = '',
    this.entranceLocation = '',
    this.navigationPoiId = '',
    this.gridcode = '',
    this.indoorMap = false,
    this.rating = '',
    this.cost = '',
    this.openTime = '',
    this.featureTag = '',
    this.rawType = '',
  });

  final String id;
  final String name;
  final String city;
  final String address;
  final String category;
  final List<String> tags;
  final String photoUrl;
  final List<String> photoUrls;
  final List<String> photoTitles;
  final String typecode;
  final String province;
  final String district;
  final String location;
  final double? longitude;
  final double? latitude;
  final String tel;
  final String website;
  final String email;
  final String postcode;
  final String alias;
  final String businessArea;
  final String entranceLocation;
  final String navigationPoiId;
  final String gridcode;
  final bool indoorMap;
  final String rating;
  final String cost;
  final String openTime;
  final String featureTag;
  final String rawType;
}

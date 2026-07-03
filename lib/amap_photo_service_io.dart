import 'dart:convert';
import 'dart:io';

import 'local_config.dart';

const String _amapWebServiceKey = String.fromEnvironment(
  'AMAP_WEB_SERVICE_KEY',
  defaultValue: localAmapWebServiceKey,
);

Future<String?> fetchAmapPhotoUrl({
  required String keyword,
  String city = '',
}) async {
  final urls = await fetchAmapPhotoUrls(keyword: keyword, city: city);
  return urls.isEmpty ? null : urls.first;
}

Future<List<String>> fetchAmapPhotoUrls({
  required String keyword,
  String city = '',
}) async {
  final spots = await fetchAmapPhotoSpots(keyword: keyword, city: city);
  return spots.map((spot) => spot.photoUrl).toList(growable: false);
}

Future<List<AmapPhotoSpot>> fetchAmapPhotoSpots({
  required String keyword,
  String city = '',
}) async {
  if (_amapWebServiceKey.isEmpty) return const [];

  final uri = Uri.https('restapi.amap.com', '/v3/place/text', {
    'key': _amapWebServiceKey,
    'keywords': keyword,
    if (city.isNotEmpty) 'city': city,
    'offset': '6',
    'page': '1',
    'extensions': 'all',
    'output': 'json',
  });

  final client = HttpClient();
  try {
    final request = await client.getUrl(uri).timeout(const Duration(seconds: 5));
    final response = await request.close().timeout(const Duration(seconds: 8));
    if (response.statusCode != HttpStatus.ok) return const [];

    final body = await response.transform(utf8.decoder).join();
    final json = jsonDecode(body);
    if (json is! Map<String, Object?> || json['status'] != '1') {
      return const [];
    }

    final pois = json['pois'];
    if (pois is! List || pois.isEmpty) return const [];

    return pois
        .whereType<Map<String, Object?>>()
        .map(_spotFromPoi)
        .whereType<AmapPhotoSpot>()
        .toList(growable: false);
  } catch (_) {
    return const [];
  } finally {
    client.close(force: true);
  }
}

AmapPhotoSpot? _spotFromPoi(Map<String, Object?> poi) {
  final photos = poi['photos'];
  if (photos is! List || photos.isEmpty) return null;

  Map<String, Object?>? photo;
  for (final item in photos.whereType<Map<String, Object?>>()) {
    photo = item;
    break;
  }
  final url = _preferHttps(photo?['url']?.toString().trim() ?? '');
  if (!url.startsWith('http')) return null;

  final name = _read(poi, 'name', fallback: '旅行灵感地点');
  final city = _joinNonEmpty([
    _read(poi, 'cityname'),
    _read(poi, 'adname'),
  ], separator: ' · ');
  final address = _read(poi, 'address');
  final type = _read(poi, 'type');
  final tags = type
      .split(';')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .take(3)
      .toList(growable: false);

  return AmapPhotoSpot(
    name: name,
    city: city.isEmpty ? '位置待确认' : city,
    address: address,
    category: type,
    tags: tags.isEmpty ? const ['旅行灵感'] : tags,
    photoUrl: url,
  );
}

String _read(
  Map<String, Object?> source,
  String key, {
  String fallback = '',
}) {
  final value = source[key];
  if (value == null) return fallback;
  final text = value.toString().trim();
  return text.isEmpty || text == '[]' ? fallback : text;
}

String _joinNonEmpty(List<String> values, {required String separator}) {
  return values.where((value) => value.trim().isNotEmpty).join(separator);
}

String _preferHttps(String url) {
  if (url.startsWith('http://')) {
    return 'https://${url.substring('http://'.length)}';
  }
  return url;
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

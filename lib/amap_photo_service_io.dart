import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'local_config.dart';

const String _amapWebServiceKey = String.fromEnvironment(
  'AMAP_WEB_SERVICE_KEY',
  defaultValue: localAmapWebServiceKey,
);

Future<String?> fetchAmapPhotoUrl({
  required String keyword,
  String city = '',
  String types = '',
}) async {
  final urls = await fetchAmapPhotoUrls(
    keyword: keyword,
    city: city,
    types: types,
  );
  return urls.isEmpty ? null : urls.first;
}

Future<List<String>> fetchAmapPhotoUrls({
  required String keyword,
  String city = '',
  String types = '',
}) async {
  final spots = await fetchAmapPhotoSpots(
    keyword: keyword,
    city: city,
    types: types,
  );
  return spots.expand((spot) => spot.photoUrls).toList(growable: false);
}

Future<List<AmapPhotoSpot>> fetchAmapPhotoSpots({
  required String keyword,
  String city = '',
  String types = '',
}) async {
  if (_amapWebServiceKey.isEmpty) return const [];

  final uri = Uri.https('restapi.amap.com', '/v3/place/text', {
    'key': _amapWebServiceKey,
    'keywords': keyword,
    if (city.isNotEmpty) 'city': city,
    if (types.isNotEmpty) 'types': types,
    'offset': '6',
    'page': '1',
    'extensions': 'all',
    'output': 'json',
  });

  final client = HttpClient();
  try {
    final request = await client
        .getUrl(uri)
        .timeout(const Duration(seconds: 5));
    final response = await request.close().timeout(const Duration(seconds: 8));
    if (response.statusCode != HttpStatus.ok) return const [];

    final body = await response.transform(utf8.decoder).join();
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, Object?> || decoded['status'] != '1') {
      return const [];
    }

    final pois = decoded['pois'];
    if (pois is! List || pois.isEmpty) return const [];

    return pois
        .whereType<Map<String, Object?>>()
        .map(_spotFromPoi)
        .whereType<AmapPhotoSpot>()
        .where((spot) => types.isEmpty || _matchesAmapType(spot, types))
        .toList(growable: false);
  } catch (e) {
    debugPrint('Amap POI request failed: $e');
    return const [];
  } finally {
    client.close(force: true);
  }
}

bool _matchesAmapType(AmapPhotoSpot spot, String types) {
  final requestedTypes = types
      .split('|')
      .map((type) => type.trim())
      .where((type) => type.isNotEmpty);
  if (requestedTypes.isEmpty) return true;

  return requestedTypes.any((requestedType) {
    if (spot.typecode == requestedType) return true;
    if (requestedType.endsWith('0000') && requestedType.length >= 2) {
      return spot.typecode.startsWith(requestedType.substring(0, 2));
    }
    if (requestedType.endsWith('000') && requestedType.length >= 3) {
      return spot.typecode.startsWith(requestedType.substring(0, 3));
    }
    return false;
  });
}

AmapPhotoSpot? _spotFromPoi(Map<String, Object?> poi) {
  final photoItems = _readPhotos(poi['photos']);
  if (photoItems.isEmpty) return null;

  final url = photoItems.first.url;
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
  final location = _parseLocation(_read(poi, 'location'));
  final bizExt = _readMap(poi['biz_ext']);

  return AmapPhotoSpot(
    id: _read(poi, 'id'),
    name: name,
    city: city.isEmpty ? '位置待确认' : city,
    address: address,
    category: type,
    tags: tags.isEmpty ? const ['旅行灵感'] : tags,
    photoUrl: url,
    photoUrls: photoItems.map((photo) => photo.url).toList(growable: false),
    photoTitles: photoItems
        .map((photo) => photo.title)
        .where((title) => title.isNotEmpty)
        .toList(growable: false),
    typecode: _read(poi, 'typecode'),
    province: _read(poi, 'pname'),
    district: _read(poi, 'adname'),
    location: _read(poi, 'location'),
    longitude: location?.longitude,
    latitude: location?.latitude,
    tel: _read(poi, 'tel'),
    website: _read(poi, 'website'),
    email: _read(poi, 'email'),
    postcode: _read(poi, 'postcode'),
    alias: _read(poi, 'alias'),
    businessArea: _read(poi, 'business_area'),
    entranceLocation: _read(poi, 'entr_location'),
    navigationPoiId: _read(poi, 'navi_poiid'),
    gridcode: _read(poi, 'gridcode'),
    indoorMap: _read(poi, 'indoor_map') == '1',
    rating: _read(bizExt, 'rating'),
    cost: _read(bizExt, 'cost'),
    openTime: _read(poi, 'open_time'),
    featureTag: _read(poi, 'tag'),
    rawType: type,
  );
}

List<_AmapPhotoItem> _readPhotos(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map<String, Object?>>()
      .map((photo) {
        final url = _preferHttps(photo['url']?.toString().trim() ?? '');
        if (!url.startsWith('http')) return null;
        return _AmapPhotoItem(
          url: url,
          title: photo['title']?.toString().trim() ?? '',
        );
      })
      .whereType<_AmapPhotoItem>()
      .toList(growable: false);
}

Map<String, Object?> _readMap(Object? value) {
  if (value is Map<String, Object?>) return value;
  return const {};
}

_AmapLocation? _parseLocation(String value) {
  final parts = value.split(',');
  if (parts.length != 2) return null;
  final longitude = double.tryParse(parts[0].trim());
  final latitude = double.tryParse(parts[1].trim());
  if (longitude == null || latitude == null) return null;
  return _AmapLocation(longitude: longitude, latitude: latitude);
}

String _read(Map<String, Object?> source, String key, {String fallback = ''}) {
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

class _AmapPhotoItem {
  const _AmapPhotoItem({required this.url, required this.title});

  final String url;
  final String title;
}

class _AmapLocation {
  const _AmapLocation({required this.longitude, required this.latitude});

  final double longitude;
  final double latitude;
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

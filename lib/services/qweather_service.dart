import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:http/http.dart' as http;

import '../local_config.dart';

const String _configuredApiHost = String.fromEnvironment(
  'QWEATHER_API_HOST',
  defaultValue: localQWeatherApiHost,
);
const String _configuredGeoHost = String.fromEnvironment(
  'QWEATHER_GEO_HOST',
  defaultValue: localQWeatherGeoHost,
);
const String _credentialId = String.fromEnvironment(
  'QWEATHER_CREDENTIAL_ID',
  defaultValue: localQWeatherCredentialId,
);
const String _projectId = String.fromEnvironment(
  'QWEATHER_PROJECT_ID',
  defaultValue: localQWeatherProjectId,
);
const String _privateKeyBase64 = String.fromEnvironment(
  'QWEATHER_PRIVATE_KEY',
  defaultValue: localQWeatherPrivateKeyBase64,
);
const String _fallbackApiHost = 'api.qweather.com';
const String _fallbackGeoHost = 'geoapi.qweather.com';

class QWeatherService {
  QWeatherService._();

  static String? lastError;

  static String get _apiHost =>
      _configuredApiHost.isNotEmpty ? _configuredApiHost : _fallbackApiHost;

  static String get _geoHost {
    if (_configuredGeoHost.isNotEmpty) return _configuredGeoHost;
    if (_configuredApiHost.isNotEmpty) return _configuredApiHost;
    return _fallbackGeoHost;
  }

  static Future<QWeatherCity?> searchCity(String keyword) async {
    if (!_hasConfiguredHost()) return null;
    final token = await _generateToken();
    final uri = Uri.https(_geoHost, '/v2/city/lookup', {
      'location': keyword,
      'number': '1',
    });
    final data = await _get(uri, token);
    if (data == null) return null;
    final list = data['location'];
    if (list is! List || list.isEmpty) return null;
    final first = list.first;
    return first is Map<String, Object?> ? QWeatherCity.fromJson(first) : null;
  }

  static Future<QWeather7Day?> fetch7DayForecast(String locationId) async {
    if (!_hasConfiguredHost()) return null;
    final token = await _generateToken();
    final uri = Uri.https(_apiHost, '/v7/weather/7d', {'location': locationId});
    final data = await _get(uri, token);
    if (data == null) return null;
    return QWeather7Day.fromJson(data);
  }

  static Future<QWeatherNow?> fetchNow(String locationId) async {
    if (!_hasConfiguredHost()) return null;
    final token = await _generateToken();
    final uri = Uri.https(_apiHost, '/v7/weather/now', {
      'location': locationId,
    });
    final data = await _get(uri, token);
    if (data == null) return null;
    final now = data['now'];
    return now is Map<String, Object?> ? QWeatherNow.fromJson(now) : null;
  }

  static Future<String> _generateToken() async {
    try {
      final seedBytes = _decodePrivateKeySeed(_privateKeyBase64);
      final keyPair = await Ed25519().newKeyPairFromSeed(seedBytes);

      final header = _b64url(
        jsonEncode({'alg': 'EdDSA', 'kid': _credentialId}),
      );
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final issuedAt = now - 30;
      final payload = _b64url(
        jsonEncode({'sub': _projectId, 'iat': issuedAt, 'exp': issuedAt + 900}),
      );

      final signingInput = '$header.$payload';
      final sig = await Ed25519().signString(signingInput, keyPair: keyPair);
      debugPrint('JWT generated: kid=$_credentialId sub=$_projectId');
      return '$signingInput.${_b64urlBytes(sig.bytes)}';
    } catch (e) {
      debugPrint('JWT generation failed: $e');
      rethrow;
    }
  }

  static bool _hasConfiguredHost() {
    if (_configuredApiHost.isNotEmpty) return true;
    lastError = 'QWEATHER_API_HOST is not configured';
    debugPrint(lastError!);
    return false;
  }

  static Future<Map<String, Object?>?> _get(Uri uri, String token) async {
    try {
      debugPrint('GET ${uri.host}${uri.path}');
      final response = await http
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 8));
      final body = utf8.decode(response.bodyBytes);
      if (response.statusCode != 200) {
        lastError = 'HTTP ${response.statusCode}: $body';
        debugPrint(lastError!);
        return null;
      }
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, Object?>) {
        lastError = 'Response is not a JSON object';
        debugPrint(lastError!);
        return null;
      }
      if (decoded['code'] != '200') {
        lastError = 'API code error: ${decoded['code']} body=$body';
        debugPrint(lastError!);
        return null;
      }
      lastError = null;
      return decoded;
    } catch (e) {
      lastError = 'Request failed: $e';
      debugPrint(lastError!);
      return null;
    }
  }

  static void debugPrint(String msg) {
    // ignore: avoid_print
    print('[QWeather] $msg');
  }

  static String _b64url(String input) {
    return base64Url.encode(utf8.encode(input)).replaceAll('=', '');
  }

  static String _b64urlBytes(List<int> bytes) {
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  static List<int> _decodePrivateKeySeed(String input) {
    final normalized = input
        .replaceAll('-----BEGIN PRIVATE KEY-----', '')
        .replaceAll('-----END PRIVATE KEY-----', '')
        .replaceAll(RegExp(r'\s+'), '');
    if (normalized.isEmpty) {
      throw const FormatException('QWeather private key is empty');
    }

    final decoded = _decodeBase64Loose(normalized);
    if (decoded.length == 32) return decoded;

    final privateKeyOid = <int>[0x06, 0x03, 0x2B, 0x65, 0x70];
    final oidIndex = _indexOfBytes(decoded, privateKeyOid);
    if (oidIndex >= 0 && decoded.length >= 32) {
      return decoded.sublist(decoded.length - 32);
    }

    if (decoded.length == 64) return decoded.sublist(0, 32);
    throw FormatException(
      'Unsupported QWeather private key length: ${decoded.length}',
    );
  }

  static List<int> _decodeBase64Loose(String input) {
    final padded = input.padRight((input.length + 3) ~/ 4 * 4, '=');
    try {
      return base64Url.decode(padded);
    } on FormatException {
      return base64.decode(padded);
    }
  }

  static int _indexOfBytes(List<int> bytes, List<int> pattern) {
    for (var i = 0; i <= bytes.length - pattern.length; i++) {
      var matched = true;
      for (var j = 0; j < pattern.length; j++) {
        if (bytes[i + j] != pattern[j]) {
          matched = false;
          break;
        }
      }
      if (matched) return i;
    }
    return -1;
  }
}

class QWeatherNow {
  const QWeatherNow({
    required this.temp,
    required this.feelsLike,
    required this.icon,
    required this.text,
    required this.windDir,
    required this.windScale,
    required this.humidity,
    required this.vis,
  });

  final String temp;
  final String feelsLike;
  final String icon;
  final String text;
  final String windDir;
  final String windScale;
  final String humidity;
  final String vis;

  factory QWeatherNow.fromJson(Map<String, Object?> json) {
    return QWeatherNow(
      temp: '${json['temp'] ?? ''}',
      feelsLike: '${json['feelsLike'] ?? ''}',
      icon: '${json['icon'] ?? ''}',
      text: '${json['text'] ?? ''}',
      windDir: '${json['windDir'] ?? ''}',
      windScale: '${json['windScale'] ?? ''}',
      humidity: '${json['humidity'] ?? ''}',
      vis: '${json['vis'] ?? ''}',
    );
  }
}

class QWeatherCity {
  const QWeatherCity({
    required this.id,
    required this.name,
    required this.adm1,
    required this.adm2,
    required this.country,
  });

  final String id;
  final String name;
  final String adm1;
  final String adm2;
  final String country;

  factory QWeatherCity.fromJson(Map<String, Object?> json) {
    return QWeatherCity(
      id: '${json['id'] ?? ''}',
      name: '${json['name'] ?? ''}',
      adm1: '${json['adm1'] ?? ''}',
      adm2: '${json['adm2'] ?? ''}',
      country: '${json['country'] ?? ''}',
    );
  }
}

class QWeather7Day {
  const QWeather7Day({required this.days});

  final List<QWeatherDay> days;

  factory QWeather7Day.fromJson(Map<String, Object?> json) {
    final list = json['daily'];
    final days = <QWeatherDay>[];
    if (list is List) {
      for (final item in list) {
        if (item is Map<String, Object?>) {
          days.add(QWeatherDay.fromJson(item));
        }
      }
    }
    return QWeather7Day(days: days);
  }
}

class QWeatherDay {
  const QWeatherDay({
    required this.fxDate,
    required this.tempMax,
    required this.tempMin,
    required this.iconDay,
    required this.textDay,
    required this.iconNight,
    required this.textNight,
    required this.windDirDay,
    required this.windScaleDay,
    required this.humidity,
    required this.sunrise,
    required this.sunset,
  });

  final String fxDate;
  final String tempMax;
  final String tempMin;
  final String iconDay;
  final String textDay;
  final String iconNight;
  final String textNight;
  final String windDirDay;
  final String windScaleDay;
  final String humidity;
  final String sunrise;
  final String sunset;

  factory QWeatherDay.fromJson(Map<String, Object?> json) {
    return QWeatherDay(
      fxDate: '${json['fxDate'] ?? ''}',
      tempMax: '${json['tempMax'] ?? ''}',
      tempMin: '${json['tempMin'] ?? ''}',
      iconDay: '${json['iconDay'] ?? ''}',
      textDay: '${json['textDay'] ?? ''}',
      iconNight: '${json['iconNight'] ?? ''}',
      textNight: '${json['textNight'] ?? ''}',
      windDirDay: '${json['windDirDay'] ?? ''}',
      windScaleDay: '${json['windScaleDay'] ?? ''}',
      humidity: '${json['humidity'] ?? ''}',
      sunrise: '${json['sunrise'] ?? ''}',
      sunset: '${json['sunset'] ?? ''}',
    );
  }

  String get dateLabel {
    if (fxDate.length < 10) return fxDate;
    final parts = fxDate.split('-');
    if (parts.length < 3) return fxDate;
    return '${parts[1]}/${parts[2]}';
  }

  String get tempRange => '$tempMin\u00B0~$tempMax\u00B0';

  String get iconUrl =>
      'https://a.hecdn.net/img/common/icon/202106d/$iconDay.png';

  bool get isToday {
    final now = DateTime.now();
    final y = now.year.toString();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return fxDate == '$y-$m-$d';
  }

  String get dayLabel => isToday ? '\u4eca\u5929' : dateLabel;
}

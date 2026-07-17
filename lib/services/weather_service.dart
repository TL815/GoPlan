import 'dart:convert';

import 'package:http/http.dart' as http;

import '../local_config.dart';

const String _amapWeatherHost = 'restapi.amap.com';
const String _amapWeatherPath = '/v3/weather/weatherInfo';
const String _amapWebServiceKey = String.fromEnvironment(
  'AMAP_WEB_SERVICE_KEY',
  defaultValue: localAmapWebServiceKey,
);

class WeatherService {
  const WeatherService._();

  static Future<WeatherData?> fetchWeather(String adcode) async {
    if (_amapWebServiceKey.isEmpty) return null;

    try {
      final live = await _fetchLiveWeather(adcode);
      final forecast = await _fetchForecast(adcode);
      if (live == null && forecast == null) return null;
      return WeatherData.fromResponses(live: live, forecast: forecast);
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, Object?>?> _fetchLiveWeather(String adcode) async {
    final json = await _getWeather(adcode: adcode, extensions: 'base');
    final lives = json['lives'];
    if (lives is! List || lives.isEmpty) return null;
    final first = lives.first;
    return first is Map<String, Object?> ? first : null;
  }

  static Future<Map<String, Object?>?> _fetchForecast(String adcode) async {
    final json = await _getWeather(adcode: adcode, extensions: 'all');
    final forecasts = json['forecasts'];
    if (forecasts is! List || forecasts.isEmpty) return null;
    final first = forecasts.first;
    return first is Map<String, Object?> ? first : null;
  }

  static Future<Map<String, Object?>> _getWeather({
    required String adcode,
    required String extensions,
  }) async {
    final uri = Uri.https(_amapWeatherHost, _amapWeatherPath, {
      'key': _amapWebServiceKey,
      'city': adcode,
      'extensions': extensions,
      'output': 'JSON',
    });
    final response = await http.get(uri).timeout(const Duration(seconds: 8));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw WeatherServiceException('Amap HTTP ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, Object?>) {
      throw const WeatherServiceException('Amap response is not an object');
    }
    if (decoded['status'] != '1') {
      throw WeatherServiceException(
        'Amap weather failed: ${decoded['info'] ?? decoded['infocode']}',
      );
    }
    return decoded;
  }
}

class WeatherServiceException implements Exception {
  const WeatherServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class WeatherData {
  const WeatherData({
    required this.province,
    required this.city,
    required this.weather,
    required this.temperature,
    required this.windDirection,
    required this.windPower,
    required this.humidity,
    required this.reportTime,
    this.dayTemp,
    this.nightTemp,
    this.dayWeather,
    this.nightWeather,
  });

  final String province;
  final String city;
  final String weather;
  final String temperature;
  final String windDirection;
  final String windPower;
  final String humidity;
  final String reportTime;
  final String? dayTemp;
  final String? nightTemp;
  final String? dayWeather;
  final String? nightWeather;

  factory WeatherData.fromResponses({
    required Map<String, Object?>? live,
    required Map<String, Object?>? forecast,
  }) {
    final today = _firstCast(forecast);
    return WeatherData(
      province: _read(live, 'province', fallback: _read(forecast, 'province')),
      city: _read(live, 'city', fallback: _read(forecast, 'city')),
      weather: _read(
        live,
        'weather',
        fallback: _read(today, 'dayweather', fallback: '晴'),
      ),
      temperature: _read(
        live,
        'temperature',
        fallback: _read(today, 'daytemp', fallback: '25'),
      ),
      windDirection: _read(
        live,
        'winddirection',
        fallback: _read(today, 'daywind'),
      ),
      windPower: _read(live, 'windpower', fallback: _read(today, 'daypower')),
      humidity: _read(live, 'humidity'),
      reportTime: _read(
        live,
        'reporttime',
        fallback: _read(forecast, 'reporttime'),
      ),
      dayTemp: _nullableRead(today, 'daytemp'),
      nightTemp: _nullableRead(today, 'nighttemp'),
      dayWeather: _nullableRead(today, 'dayweather'),
      nightWeather: _nullableRead(today, 'nightweather'),
    );
  }

  String get temperatureRange {
    final high = int.tryParse(dayTemp ?? '');
    final low = int.tryParse(nightTemp ?? '');
    if (high != null && low != null) {
      final min = low <= high ? low : high;
      final max = low <= high ? high : low;
      return '$min℃~$max℃';
    }
    return '$temperature℃';
  }

  String get conditionLabel {
    if (dayWeather == null ||
        nightWeather == null ||
        dayWeather == nightWeather) {
      return weather;
    }
    return '$dayWeather转$nightWeather';
  }

  String get weatherIconAsset {
    final value = conditionLabel;
    if (value.contains('沙尘') || value.contains('浮尘') || value.contains('扬沙')) {
      return 'assets/icons/沙尘暴.png';
    }
    if (value.contains('雪')) return 'assets/icons/雪天.png';
    if (value.contains('雷阵雨')) return 'assets/icons/雷阵雨.png';
    if (value.contains('暴雨') || value.contains('大雨')) {
      return 'assets/icons/大雨及暴雨.png';
    }
    if (value.contains('阵雨')) return 'assets/icons/阵雨.png';
    if (value.contains('雨')) return 'assets/icons/雨.png';
    if (value.contains('雾') || value.contains('霾')) {
      return 'assets/icons/雾霾.png';
    }
    if (value.contains('阴')) return 'assets/icons/阴天.png';
    if (value.contains('云')) return 'assets/icons/多云.png';
    return 'assets/icons/晴天.png';
  }

  static Map<String, Object?>? _firstCast(Map<String, Object?>? forecast) {
    final casts = forecast?['casts'];
    if (casts is! List || casts.isEmpty) return null;
    final first = casts.first;
    return first is Map<String, Object?> ? first : null;
  }

  static String _read(
    Map<String, Object?>? source,
    String key, {
    String fallback = '',
  }) {
    final value = source?[key]?.toString().trim();
    return value == null || value.isEmpty ? fallback : value;
  }

  static String? _nullableRead(Map<String, Object?>? source, String key) {
    final value = _read(source, key);
    return value.isEmpty ? null : value;
  }
}

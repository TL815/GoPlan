import 'package:flutter/material.dart';

import '../services/qweather_service.dart';

class WeatherDrawer extends StatelessWidget {
  const WeatherDrawer({
    super.key,
    required this.forecast,
    this.now,
    this.cityName = '',
    this.errorMessage,
  });

  final QWeather7Day? forecast;
  final QWeatherNow? now;
  final String cityName;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final days = forecast?.days ?? [];
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final hasWeather = now != null || days.isNotEmpty;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            color: Color(0xFFF7F8F7),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                color: Color(0x24000000),
                blurRadius: 28,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _WeatherHeaderCard(now: now, cityName: cityName),
              ),
              const SizedBox(height: 12),
              if (!hasWeather)
                _WeatherEmptyState(message: errorMessage)
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    itemCount: days.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) => _DayRow(day: days[index]),
                  ),
                ),
              SizedBox(height: safeBottom + 12),
            ],
          ),
        ),
        const _WeatherSheetGrip(),
      ],
    );
  }
}

class _WeatherSheetGrip extends StatelessWidget {
  const _WeatherSheetGrip();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: -12,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          width: 42,
          height: 5,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            boxShadow: const [
              BoxShadow(
                color: Color(0x24000000),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeatherHeaderCard extends StatelessWidget {
  const _WeatherHeaderCard({required this.now, required this.cityName});

  final QWeatherNow? now;
  final String cityName;

  @override
  Widget build(BuildContext context) {
    final tint = _weatherTintFor(icon: now?.icon, text: now?.text);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 16, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, tint],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cityName.isNotEmpty ? cityName : '\u5f53\u524d\u4f4d\u7f6e',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF8A8F8C),
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      now?.temp ?? '--',
                      style: const TextStyle(
                        fontSize: 44,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111111),
                        letterSpacing: 0,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        '\u00B0C',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF777D7A),
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _WeatherMetaPill(label: now?.text ?? '--'),
              ],
            ),
          ),
          const SizedBox(width: 14),
          _WeatherIcon(icon: now?.icon, text: now?.text, size: 76),
        ],
      ),
    );
  }
}

Color _weatherTintFor({String? icon, String? text}) {
  final code = int.tryParse(icon ?? '');
  final label = text ?? '';
  if (code == 100 || label.contains('\u6674')) {
    return const Color(0xFFFFF8DF);
  }
  if ((code != null && code >= 300 && code <= 399) ||
      label.contains('\u96e8')) {
    return const Color(0xFFEAF3F5);
  }
  if ((code != null && code >= 400 && code <= 499) ||
      label.contains('\u96ea')) {
    return const Color(0xFFF0F6F8);
  }
  if ((code != null && code >= 500 && code <= 515) ||
      label.contains('\u96fe') ||
      label.contains('\u973e')) {
    return const Color(0xFFF1F0EA);
  }
  return const Color(0xFFEFF7F2);
}

class _WeatherMetaPill extends StatelessWidget {
  const _WeatherMetaPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 24),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 12,
          height: 1.1,
          fontWeight: FontWeight.w800,
          color: Color(0xFF4E5652),
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _WeatherIcon extends StatelessWidget {
  const _WeatherIcon({required this.icon, this.text, required this.size});

  final String? icon;
  final String? text;
  final double size;

  @override
  Widget build(BuildContext context) {
    final asset = _weatherAssetFor(icon: icon, text: text);
    if (asset != null) {
      return Image.asset(
        asset,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      );
    }

    if (icon == null || icon!.isEmpty) {
      return SizedBox(
        width: size,
        height: size,
        child: const Icon(
          Icons.cloud_outlined,
          color: Color(0xFFD5DCD8),
          size: 42,
        ),
      );
    }

    return Image.network(
      'https://a.hecdn.net/img/common/icon/202106d/$icon.png',
      width: size,
      height: size,
      errorBuilder: (_, _, _) => SizedBox(
        width: size,
        height: size,
        child: const Icon(
          Icons.cloud_outlined,
          color: Color(0xFFD5DCD8),
          size: 42,
        ),
      ),
    );
  }
}

String? _weatherAssetFor({String? icon, String? text}) {
  final code = int.tryParse(icon ?? '');
  final label = text ?? '';

  if (code != null) {
    if (code == 100) return 'assets/icons/\u6674\u5929.png';
    if (code >= 101 && code <= 103) return 'assets/icons/\u591a\u4e91.png';
    if (code == 104) return 'assets/icons/\u9634\u5929.png';
    if (code == 302 || code == 304) {
      return 'assets/icons/\u96f7\u9635\u96e8.png';
    }
    if (code == 305 || code == 309) return 'assets/icons/\u9635\u96e8.png';
    if (code >= 300 && code <= 399) {
      if (code >= 310 && code <= 318) {
        return 'assets/icons/\u5927\u96e8\u53ca\u66b4\u96e8.png';
      }
      return 'assets/icons/\u96e8.png';
    }
    if (code >= 400 && code <= 499) return 'assets/icons/\u96ea\u5929.png';
    if (code >= 503 && code <= 508) {
      return 'assets/icons/\u6c99\u5c18\u66b4.png';
    }
    if (code >= 500 && code <= 515) return 'assets/icons/\u96fe\u973e.png';
  }

  if (label.contains('\u6c99') || label.contains('\u5c18')) {
    return 'assets/icons/\u6c99\u5c18\u66b4.png';
  }
  if (label.contains('\u96f7')) return 'assets/icons/\u96f7\u9635\u96e8.png';
  if (label.contains('\u66b4\u96e8') || label.contains('\u5927\u96e8')) {
    return 'assets/icons/\u5927\u96e8\u53ca\u66b4\u96e8.png';
  }
  if (label.contains('\u9635\u96e8')) return 'assets/icons/\u9635\u96e8.png';
  if (label.contains('\u96e8')) return 'assets/icons/\u96e8.png';
  if (label.contains('\u96ea')) return 'assets/icons/\u96ea\u5929.png';
  if (label.contains('\u96fe') || label.contains('\u973e')) {
    return 'assets/icons/\u96fe\u973e.png';
  }
  if (label.contains('\u9634')) return 'assets/icons/\u9634\u5929.png';
  if (label.contains('\u4e91')) return 'assets/icons/\u591a\u4e91.png';
  if (label.contains('\u6674')) return 'assets/icons/\u6674\u5929.png';
  return null;
}

class _WeatherEmptyState extends StatelessWidget {
  const _WeatherEmptyState({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            '\u6682\u65e0\u5929\u6c14\u6570\u636e',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Color(0xFF333333),
              letterSpacing: 0,
            ),
          ),
          if (message != null && message!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: Color(0xFF999999),
                letterSpacing: 0,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({required this.day});

  final QWeatherDay day;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.fromLTRB(13, 8, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 46,
            child: Text(
              day.dayLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                height: 1,
                fontWeight: day.isToday ? FontWeight.w900 : FontWeight.w800,
                color: day.isToday
                    ? const Color(0xFF111111)
                    : const Color(0xFF777D7A),
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _WeatherIcon(icon: day.iconDay, text: day.textDay, size: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${day.textDay} ${day.windDirDay}${day.windScaleDay}\u7ea7',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                height: 1,
                fontWeight: FontWeight.w700,
                color: Color(0xFF666D69),
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            day.tempRange,
            maxLines: 1,
            style: const TextStyle(
              fontSize: 13,
              height: 1,
              fontWeight: FontWeight.w900,
              color: Color(0xFF222222),
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

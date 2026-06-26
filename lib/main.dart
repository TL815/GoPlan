import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GoPlanApp());
}

class GoPlanApp extends StatelessWidget {
  const GoPlanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GoPlan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF28D99A)),
        scaffoldBackgroundColor: const Color(0xFFF6F6F6),
        useMaterial3: true,
        fontFamily: Platform.isIOS ? '.SF Pro Text' : null,
      ),
      home: const GoPlanShell(),
    );
  }
}

enum AppTab { home, explore, schedule, profile }

class GoPlanShell extends StatefulWidget {
  const GoPlanShell({super.key});

  @override
  State<GoPlanShell> createState() => _GoPlanShellState();
}

class _GoPlanShellState extends State<GoPlanShell> {
  bool _showHome = false;
  AppTab _tab = AppTab.home;

  @override
  Widget build(BuildContext context) {
    if (!_showHome) {
      return LoadingPage(onStart: () => setState(() => _showHome = true));
    }

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: IndexedStack(
              index: _tab.index,
              children: const [
                HomePage(),
                ExplorePage(),
                PlaceholderPage(
                  icon: Icons.calendar_month_outlined,
                  title: '日程模块开发中...',
                ),
                PlaceholderPage(
                  icon: Icons.person_outline,
                  title: '个人中心开发中...',
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 22,
            child: BottomDock(
              current: _tab,
              onChanged: (tab) => setState(() => _tab = tab),
            ),
          ),
        ],
      ),
    );
  }
}

class LoadingPage extends StatelessWidget {
  const LoadingPage({super.key, required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/loading-bg.png', fit: BoxFit.cover),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Color(0x99FFFFFF), Color(0x00FFFFFF)],
                stops: [0, 0.28, 0.52],
              ),
            ),
          ),
          Positioned(
            left: 34,
            top: size.height * 0.09,
            child: Image.asset('assets/images/GoPlan.png', width: 156),
          ),
          Positioned(
            left: size.width * 0.29,
            top: size.height * 0.10,
            child: RotatedBox(
              quarterTurns: 0,
              child: Transform.rotate(
                angle: 0.18,
                child: _TravelPoster(
                  asset: 'assets/images/卡片一.png',
                  width: size.width * 0.92,
                ),
              ),
            ),
          ),
          Positioned(
            left: size.width * 0.05,
            top: size.height * 0.32,
            child: Transform.rotate(
              angle: -0.34,
              child: _TravelPoster(
                asset: 'assets/images/卡片二.png',
                width: size.width * 0.94,
              ),
            ),
          ),
          Positioned(
            left: size.width * 0.36,
            top: size.height * 0.52,
            child: Transform.rotate(
              angle: 0.36,
              child: _TravelPoster(
                asset: 'assets/images/卡片三.png',
                width: size.width * 0.92,
              ),
            ),
          ),
          Positioned(
            left: 32,
            right: 32,
            bottom: 28,
            child: FilledButton(
              onPressed: onStart,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1C1C1E),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(58),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Row(
                children: [
                  _GoPill(),
                  Expanded(
                    child: Text(
                      '去出发！',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TravelPoster extends StatelessWidget {
  const _TravelPoster({required this.asset, required this.width});

  final String asset;
  final double width;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.asset(asset, width: width, fit: BoxFit.cover),
    );
  }
}

class _GoPill extends StatelessWidget {
  const _GoPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 66,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Text(
        'Go',
        style: TextStyle(
          color: Color(0xFF1C1C1E),
          fontSize: 22,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 112),
        children: [
          const _HomeTopSection(),
          const _PlanFilters(),
          const SizedBox(height: 12),
          ...demoPlans.map(
            (plan) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PlanCard(plan: plan),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeTopSection extends StatelessWidget {
  const _HomeTopSection();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 228,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(left: 0, right: 0, top: 0, child: _HomeHeader()),
          Positioned(left: 0, right: 0, top: 54, child: _WeatherPanel()),
          Positioned(left: 0, right: 0, top: 112, child: _PhotoStrip()),
          Positioned(left: 0, right: 0, top: 96, child: _SearchBar()),
          Positioned(left: 0, right: 0, bottom: 8, child: _TopDivider()),
        ],
      ),
    );
  }
}

class _TopDivider extends StatelessWidget {
  const _TopDivider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: const Color(0xFFE6E6E6));
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 20,
          backgroundImage: NetworkImage(
            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=120&q=80',
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '张三',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 13,
                    color: Color(0xFFA8A8A8),
                  ),
                  Text(
                    '世纪大厦',
                    style: TextStyle(fontSize: 11, color: Color(0xFF9D9D9D)),
                  ),
                ],
              ),
            ],
          ),
        ),
        IconButton.filled(
          onPressed: () {},
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF151515),
          ),
          icon: const Icon(Icons.notifications_none),
        ),
      ],
    );
  }
}

class _WeatherPanel extends StatelessWidget {
  const _WeatherPanel();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      child: Row(
        children: [
          Image.asset(
            'assets/images/Group 9.png',
            width: 150,
            fit: BoxFit.contain,
          ),
          const Spacer(),
          const Text(
            '21℃~36℃',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF8D8D8D),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 14),
          Image.asset('assets/images/晴天.png', width: 36),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(Icons.search, color: Color(0xFF4C4C4C)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              '来构筑你的想法......',
              style: TextStyle(color: Color(0xFFB7B7B7), fontSize: 14),
            ),
          ),
          Icon(Icons.mic_none, color: Color(0xFF4C4C4C)),
        ],
      ),
    );
  }
}

class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip();

  @override
  Widget build(BuildContext context) {
    const photos = [
      'photo-1.png',
      'photo-2.png',
      'photo-3.png',
      'photo-4.png',
      'photo-5.png',
      'photo-6.png',
      'photo-7.png',
    ];
    return SizedBox(
      height: 86,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < photos.length; i++)
            Positioned(
              left: 6 + i * 43.0,
              top: i.isEven ? 22 : 14,
              child: Transform.rotate(
                angle: (i.isEven ? -1 : 1) * 0.07,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/images/${photos[i]}',
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlanFilters extends StatelessWidget {
  const _PlanFilters();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Text(
          '我的计划',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        SizedBox(width: 28),
        Text('探索', style: TextStyle(fontSize: 15, color: Color(0xFF9C9C9C))),
        Spacer(),
        Text('全部计划', style: TextStyle(fontSize: 11, color: Color(0xFF9C9C9C))),
        Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF9C9C9C)),
        SizedBox(width: 8),
        Text('状态', style: TextStyle(fontSize: 11, color: Color(0xFF9C9C9C))),
        Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF9C9C9C)),
      ],
    );
  }
}

class PlanCard extends StatelessWidget {
  const PlanCard({super.key, required this.plan});

  final TravelPlan plan;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 122),
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x09000000),
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  plan.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                _StatusChip(plan: plan),
                const SizedBox(height: 8),
                Text(
                  plan.dateRange,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFA4A4A4),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _Metric(icon: Icons.map_outlined, value: '${plan.places}'),
                    const SizedBox(width: 22),
                    _Metric(
                      icon: Icons.people_outline,
                      value: '${plan.members}',
                    ),
                    const SizedBox(width: 22),
                    _Metric(
                      icon: Icons.calendar_today_outlined,
                      value: '${plan.days}',
                    ),
                  ],
                ),
              ],
            ),
          ),
          RoutePreview(plan: plan),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.plan});

  final TravelPlan plan;

  @override
  Widget build(BuildContext context) {
    final text = plan.countdown == null ? '完美结束' : '倒计时${plan.countdown}天';
    final color = plan.countdown == null
        ? const Color(0xFF999999)
        : const Color(0xFFF7B733);
    final bg = plan.countdown == null
        ? const Color(0xFFF0F0F0)
        : const Color(0xFFFFF4E5);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFFB8B8B8)),
        const SizedBox(width: 5),
        Text(
          value,
          style: const TextStyle(fontSize: 12, color: Color(0xFFA9A9A9)),
        ),
      ],
    );
  }
}

class RoutePreview extends StatelessWidget {
  const RoutePreview({super.key, required this.plan});

  final TravelPlan plan;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 122,
        height: 97,
        decoration: BoxDecoration(
          color: const Color(0xFFF4F7F6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: CustomPaint(painter: _RouteMapPainter(plan)),
      ),
    );
  }
}

class _RouteMapPainter extends CustomPainter {
  const _RouteMapPainter(this.plan);

  final TravelPlan plan;

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFFF5F7F5);
    canvas.drawRect(Offset.zero & size, bgPaint);

    final waterPaint = Paint()..color = const Color(0xFFDCEFF7);
    final water = Path()
      ..moveTo(size.width * .56, -4)
      ..cubicTo(
        size.width * .82,
        size.height * .08,
        size.width * .72,
        size.height * .32,
        size.width + 8,
        size.height * .42,
      )
      ..lineTo(size.width + 8, -4)
      ..close();
    canvas.drawPath(water, waterPaint);

    final parkPaint = Paint()..color = const Color(0xFFE2F1E6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * .06, size.height * .1, 34, 24),
        const Radius.circular(8),
      ),
      parkPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * .63, size.height * .62, 36, 26),
        const Radius.circular(8),
      ),
      parkPaint,
    );

    final minorRoadPaint = Paint()
      ..color = const Color(0xFFE1E6E8)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 6; i++) {
      final y = size.height * (.15 + i * .14);
      canvas.drawLine(
        Offset(-8, y),
        Offset(size.width + 8, y + (i.isEven ? 10 : -6)),
        minorRoadPaint,
      );
    }
    for (var i = 0; i < 4; i++) {
      final x = size.width * (.18 + i * .2);
      canvas.drawLine(
        Offset(x, -6),
        Offset(x + 18, size.height + 6),
        minorRoadPaint,
      );
    }

    void drawRoad(List<Offset> points) {
      final shadowPaint = Paint()
        ..color = const Color(0xFFD1D8DC)
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      final roadPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      final path = _pathFrom(points, size);
      canvas.drawPath(path, shadowPaint);
      canvas.drawPath(path, roadPaint);
    }

    drawRoad(const [
      Offset(.02, .78),
      Offset(.24, .56),
      Offset(.44, .5),
      Offset(.64, .36),
      Offset(.96, .3),
    ]);
    drawRoad(const [
      Offset(.08, .2),
      Offset(.32, .38),
      Offset(.58, .62),
      Offset(.88, .86),
    ]);
    drawRoad(const [
      Offset(.22, 1.04),
      Offset(.42, .75),
      Offset(.68, .5),
      Offset(.88, .08),
    ]);

    final routeUnderlay = Paint()
      ..color = Colors.white
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final routePaint = Paint()
      ..color = plan.accent
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round;
    final routePath = _pathFrom(
      plan.routeStops.map((stop) => stop.position).toList(),
      size,
    );
    canvas.drawPath(routePath, routeUnderlay);
    canvas.drawPath(routePath, routePaint);

    for (var i = 0; i < plan.routeStops.length; i++) {
      final stop = plan.routeStops[i];
      final point = Offset(
        stop.position.dx * size.width,
        stop.position.dy * size.height,
      );
      final isStart = i == 0;
      final isEnd = i == plan.routeStops.length - 1;
      final pinColor = isStart
          ? const Color(0xFF24D391)
          : isEnd
              ? plan.accent
              : Colors.white;

      canvas.drawCircle(
        point,
        isStart || isEnd ? 5 : 4,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        point,
        isStart || isEnd ? 3.6 : 2.7,
        Paint()..color = pinColor,
      );
      if (!isStart && !isEnd) {
        canvas.drawCircle(
          point,
          3.4,
          Paint()
            ..color = plan.accent
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }

      if (i == 0 || i == plan.routeStops.length - 1) {
        _drawLabel(canvas, stop.label, point, size);
      }
    }
  }

  Path _pathFrom(List<Offset> points, Size size) {
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final point = Offset(points[i].dx * size.width, points[i].dy * size.height);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path;
  }

  void _drawLabel(Canvas canvas, String text, Offset point, Size size) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xFF46515A),
          fontSize: 8,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 44);
    final dx = (point.dx + 6).clamp(3.0, size.width - painter.width - 3);
    final dy = (point.dy - 12).clamp(3.0, size.height - painter.height - 3);
    final rect = Rect.fromLTWH(
      dx - 3,
      dy - 2,
      painter.width + 6,
      painter.height + 4,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(5)),
      Paint()..color = Colors.white.withValues(alpha: .82),
    );
    painter.paint(canvas, Offset(dx, dy));
  }

  @override
  bool shouldRepaint(covariant _RouteMapPainter oldDelegate) =>
      oldDelegate.plan != plan;
}

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  String? _category;

  @override
  Widget build(BuildContext context) {
    final pois = _category == null
        ? demoPois
        : demoPois.where((poi) => poi.category == _category).toList();

    return Stack(
      children: [
        Positioned.fill(child: NativeMapView(pois: pois)),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _ExploreSearch(),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final category in poiCategories)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _CategoryChip(
                            category: category,
                            active: _category == category.key,
                            onTap: () => setState(() {
                              _category = _category == category.key
                                  ? null
                                  : category.key;
                            }),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class NativeMapView extends StatefulWidget {
  const NativeMapView({super.key, required this.pois});

  final List<Poi> pois;

  @override
  State<NativeMapView> createState() => _NativeMapViewState();
}

class _NativeMapViewState extends State<NativeMapView> {
  static const MethodChannel _channel = MethodChannel('goplan/native_map');

  @override
  void didUpdateWidget(covariant NativeMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.pois, widget.pois)) {
      _syncMarkers();
    }
  }

  Future<void> _syncMarkers() async {
    await _channel.invokeMethod(
      'setMarkers',
      widget.pois.map((poi) => poi.toJson()).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidView(
        viewType: 'goplan/native_map_view',
        creationParams: {
          'pois': widget.pois.map((poi) => poi.toJson()).toList(),
        },
        creationParamsCodec: const StandardMessageCodec(),
      );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
        viewType: 'goplan/native_map_view',
        creationParams: {
          'pois': widget.pois.map((poi) => poi.toJson()).toList(),
        },
        creationParamsCodec: const StandardMessageCodec(),
      );
    }
    return const _MapFallback();
  }
}

class _MapFallback extends StatelessWidget {
  const _MapFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE8F0E8),
      alignment: Alignment.center,
      child: const Text(
        '原生地图视图将在 Android/iOS 设备上显示',
        style: TextStyle(color: Color(0xFF4C4C4C)),
      ),
    );
  }
}

class _ExploreSearch extends StatelessWidget {
  const _ExploreSearch();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        children: [
          Text(
            '沈阳市',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          Icon(Icons.keyboard_arrow_down, size: 16),
          SizedBox(width: 12),
          SizedBox(height: 20, child: VerticalDivider(width: 1)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              '搜索目的地...',
              style: TextStyle(fontSize: 14, color: Color(0xFFB7B7B7)),
            ),
          ),
          Icon(Icons.search, color: Color(0xFF4C4C4C)),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.active,
    required this.onTap,
  });

  final PoiCategory category;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Image.asset(category.icon, width: 15, height: 15),
            const SizedBox(width: 5),
            Text(
              category.label,
              style: TextStyle(
                fontSize: 12,
                color: active ? Colors.white : const Color(0xFF777777),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({super.key, required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: const Color(0xFFCCCCCC)),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 16, color: Color(0xFF999999)),
          ),
        ],
      ),
    );
  }
}

class BottomDock extends StatelessWidget {
  const BottomDock({super.key, required this.current, required this.onChanged});

  final AppTab current;
  final ValueChanged<AppTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 258,
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF050505),
          borderRadius: BorderRadius.circular(29),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _DockButton(
              icon: Icons.home_rounded,
              tab: AppTab.home,
              current: current,
              onChanged: onChanged,
            ),
            _DockButton(
              icon: Icons.map_outlined,
              tab: AppTab.explore,
              current: current,
              onChanged: onChanged,
            ),
            _DockButton(
              icon: Icons.calendar_month_outlined,
              tab: AppTab.schedule,
              current: current,
              onChanged: onChanged,
            ),
            _DockButton(
              icon: Icons.person_outline,
              tab: AppTab.profile,
              current: current,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _DockButton extends StatelessWidget {
  const _DockButton({
    required this.icon,
    required this.tab,
    required this.current,
    required this.onChanged,
  });

  final IconData icon;
  final AppTab tab;
  final AppTab current;
  final ValueChanged<AppTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final active = tab == current;
    return IconButton(
      onPressed: () => onChanged(tab),
      style: IconButton.styleFrom(
        fixedSize: const Size(32, 32),
        backgroundColor: active ? const Color(0xFF3C3C3C) : Colors.transparent,
        foregroundColor: active ? Colors.white : const Color(0xFF726E6E),
      ),
      icon: Icon(icon, size: 18),
    );
  }
}

class TravelPlan {
  const TravelPlan({
    required this.title,
    required this.dateRange,
    required this.places,
    required this.members,
    required this.days,
    required this.accent,
    required this.routeStops,
    this.countdown,
  });

  final String title;
  final String dateRange;
  final int places;
  final int members;
  final int days;
  final Color accent;
  final List<RouteStop> routeStops;
  final int? countdown;
}

class RouteStop {
  const RouteStop({required this.label, required this.position});

  final String label;
  final Offset position;
}

const demoPlans = [
  TravelPlan(
    title: '青甘大环线10天游',
    dateRange: '2026.03.24~2026.04.01',
    places: 15,
    members: 4,
    days: 10,
    accent: Color(0xFF69A7FF),
    routeStops: [
      RouteStop(label: '西宁', position: Offset(.12, .64)),
      RouteStop(label: '青海湖', position: Offset(.32, .42)),
      RouteStop(label: '茶卡', position: Offset(.51, .48)),
      RouteStop(label: '敦煌', position: Offset(.7, .26)),
      RouteStop(label: '张掖', position: Offset(.9, .58)),
    ],
  ),
  TravelPlan(
    title: '川西雪山小团行',
    dateRange: '2026.05.02~2026.05.07',
    places: 12,
    members: 6,
    days: 6,
    accent: Color(0xFF7BC69C),
    routeStops: [
      RouteStop(label: '成都', position: Offset(.16, .7)),
      RouteStop(label: '康定', position: Offset(.36, .54)),
      RouteStop(label: '新都桥', position: Offset(.55, .42)),
      RouteStop(label: '塔公', position: Offset(.72, .53)),
      RouteStop(label: '四姑娘山', position: Offset(.88, .28)),
    ],
  ),
  TravelPlan(
    title: '杭州情侣周末游',
    dateRange: '2026.06.12~2026.06.14',
    places: 8,
    members: 2,
    days: 3,
    accent: Color(0xFFFFB35D),
    routeStops: [
      RouteStop(label: '西湖', position: Offset(.16, .35)),
      RouteStop(label: '灵隐', position: Offset(.32, .2)),
      RouteStop(label: '河坊街', position: Offset(.48, .48)),
      RouteStop(label: '滨江', position: Offset(.66, .68)),
      RouteStop(label: '钱江', position: Offset(.86, .56)),
    ],
    countdown: 2,
  ),
  TravelPlan(
    title: '云南朋友毕业旅行',
    dateRange: '2026.07.18~2026.07.26',
    places: 18,
    members: 5,
    days: 9,
    accent: Color(0xFFC48BFF),
    routeStops: [
      RouteStop(label: '昆明', position: Offset(.14, .72)),
      RouteStop(label: '大理', position: Offset(.34, .5)),
      RouteStop(label: '丽江', position: Offset(.55, .34)),
      RouteStop(label: '泸沽湖', position: Offset(.74, .42)),
      RouteStop(label: '香格里拉', position: Offset(.88, .18)),
    ],
    countdown: 38,
  ),
];

class PoiCategory {
  const PoiCategory({
    required this.key,
    required this.label,
    required this.icon,
  });

  final String key;
  final String label;
  final String icon;
}

const poiCategories = [
  PoiCategory(key: 'scenic', label: '景点', icon: 'assets/icons/景点.png'),
  PoiCategory(key: 'food', label: '美食', icon: 'assets/icons/美食.png'),
  PoiCategory(key: 'hotel', label: '住宿', icon: 'assets/icons/住宿.png'),
  PoiCategory(key: 'shopping', label: '购物', icon: 'assets/icons/购物.png'),
  PoiCategory(key: 'transport', label: '交通', icon: 'assets/icons/交通.png'),
];

class Poi {
  const Poi({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.category,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String category;

  Map<String, Object> toJson() => {
    'id': id,
    'name': name,
    'latitude': latitude,
    'longitude': longitude,
    'category': category,
  };
}

const demoPois = [
  Poi(
    id: '1',
    name: '人民广场',
    latitude: 41.8003,
    longitude: 123.4315,
    category: 'scenic',
  ),
  Poi(
    id: '2',
    name: '市府恒隆广场',
    latitude: 41.7959,
    longitude: 123.4377,
    category: 'shopping',
  ),
  Poi(
    id: '3',
    name: '沈阳故宫',
    latitude: 41.7955,
    longitude: 123.4498,
    category: 'scenic',
  ),
  Poi(
    id: '4',
    name: '张氏帅府',
    latitude: 41.7936,
    longitude: 123.4510,
    category: 'scenic',
  ),
  Poi(
    id: '5',
    name: '北陵公园',
    latitude: 41.8268,
    longitude: 123.4249,
    category: 'scenic',
  ),
  Poi(
    id: '6',
    name: '中街步行街',
    latitude: 41.7970,
    longitude: 123.4525,
    category: 'shopping',
  ),
  Poi(
    id: '7',
    name: '老边饺子',
    latitude: 41.7978,
    longitude: 123.4480,
    category: 'food',
  ),
  Poi(
    id: '8',
    name: '沈阳站',
    latitude: 41.7890,
    longitude: 123.4100,
    category: 'transport',
  ),
  Poi(
    id: '9',
    name: '万达文华酒店',
    latitude: 41.7920,
    longitude: 123.4420,
    category: 'hotel',
  ),
];

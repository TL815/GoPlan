// ignore_for_file: dead_code, unused_element, unused_element_parameter

part of '../../main.dart';

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
    if (kIsWeb) {
      return AmapWebView(
        pois: widget.pois
            .map(
              (poi) => AmapWebPoi(
                id: poi.id,
                name: poi.name,
                latitude: poi.latitude,
                longitude: poi.longitude,
                category: poi.category,
              ),
            )
            .toList(),
      );
    }
    if (_useMockMapPreview) {
      return _MockExploreMap(pois: widget.pois);
    }
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

class _MockExploreMap extends StatelessWidget {
  const _MockExploreMap({required this.pois});

  final List<Poi> pois;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _MockExploreMapPainter(pois)),
            ),
            for (final poi in pois)
              Positioned(
                left: _mapPoi(poi, size).dx - 11,
                top: _mapPoi(poi, size).dy - 11,
                child: _MockPoiMarker(poi: poi),
              ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 108,
              child: _MockMapSummary(pois: pois),
            ),
          ],
        );
      },
    );
  }
}

class _MockPoiMarker extends StatelessWidget {
  const _MockPoiMarker({required this.poi});

  final Poi poi;

  @override
  Widget build(BuildContext context) {
    final color = _poiColor(poi.category);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .14),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          constraints: const BoxConstraints(maxWidth: 74),
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            poi.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF2F363A),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _MockMapSummary extends StatelessWidget {
  const _MockMapSummary({required this.pois});

  final List<Poi> pois;

  @override
  Widget build(BuildContext context) {
    final categories = pois.map((poi) => poi.category).toSet().length;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .92),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.route_rounded, color: Color(0xFF24D391), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Mock map 鐠?${pois.length} POI 鐠?$categories categories',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF30363A),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const Icon(Icons.layers_rounded, color: Color(0xFF7E8B92), size: 20),
        ],
      ),
    );
  }
}

class _MockExploreMapPainter extends CustomPainter {
  const _MockExploreMapPainter(this.pois);

  final List<Poi> pois;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFEAF1EC),
    );

    final water = Path()
      ..moveTo(size.width * .72, 0)
      ..cubicTo(
        size.width * .98,
        size.height * .18,
        size.width * .72,
        size.height * .42,
        size.width * .94,
        size.height * .72,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(water, Paint()..color = const Color(0xFFD7EDF6));

    final parkPaint = Paint()..color = const Color(0xFFD8ECDD);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * .05, size.height * .2, 120, 78),
        const Radius.circular(24),
      ),
      parkPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * .46, size.height * .58, 138, 88),
        const Radius.circular(26),
      ),
      parkPaint,
    );

    _drawRoadGrid(canvas, size);
    _drawRoute(canvas, size);
  }

  void _drawRoadGrid(Canvas canvas, Size size) {
    final minor = Paint()
      ..color = const Color(0xFFDCE3E2)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 10; i++) {
      final y = size.height * (.08 + i * .1);
      canvas.drawLine(
        Offset(-20, y),
        Offset(size.width + 20, y + (i.isEven ? 22 : -16)),
        minor,
      );
    }
    for (var i = 0; i < 7; i++) {
      final x = size.width * (.06 + i * .16);
      canvas.drawLine(Offset(x, -20), Offset(x + 34, size.height + 20), minor);
    }

    final highwayShadow = Paint()
      ..color = const Color(0xFFC9D2D4)
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final highway = Paint()
      ..color = Colors.white
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(-20, size.height * .72)
      ..cubicTo(
        size.width * .2,
        size.height * .58,
        size.width * .46,
        size.height * .62,
        size.width * .64,
        size.height * .42,
      )
      ..cubicTo(
        size.width * .78,
        size.height * .26,
        size.width * .88,
        size.height * .2,
        size.width + 24,
        size.height * .16,
      );
    canvas.drawPath(path, highwayShadow);
    canvas.drawPath(path, highway);
  }

  void _drawRoute(Canvas canvas, Size size) {
    if (pois.length < 2) return;

    final route = Path();
    for (var i = 0; i < pois.length; i++) {
      final point = _mapPoi(pois[i], size);
      if (i == 0) {
        route.moveTo(point.dx, point.dy);
      } else {
        route.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(
      route,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
    canvas.drawPath(
      route,
      Paint()
        ..color = const Color(0xFF24D391)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _MockExploreMapPainter oldDelegate) =>
      !listEquals(oldDelegate.pois, pois);
}

Offset _mapPoi(Poi poi, Size size) {
  const minLat = 41.785;
  const maxLat = 41.807;
  const minLng = 123.425;
  const maxLng = 123.459;
  final x = ((poi.longitude - minLng) / (maxLng - minLng)).clamp(.08, .92);
  final y = (1 - (poi.latitude - minLat) / (maxLat - minLat)).clamp(.16, .86);
  return Offset(x * size.width, y * size.height);
}

Color _poiColor(String category) {
  return switch (category) {
    'food' => const Color(0xFFFFA629),
    'hotel' => const Color(0xFF4EA9FF),
    'shopping' => const Color(0xFFFF6BA6),
    'transport' => const Color(0xFF7BC69C),
    _ => const Color(0xFF24D391),
  };
}

class _MapFallback extends StatelessWidget {
  const _MapFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE8F0E8),
      alignment: Alignment.center,
      child: const Text(
        'Native map view is available on Android/iOS devices.',
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
            'Shenyang',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          Icon(Icons.keyboard_arrow_down, size: 16),
          SizedBox(width: 12),
          SizedBox(height: 20, child: VerticalDivider(width: 1)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Search destination...',
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

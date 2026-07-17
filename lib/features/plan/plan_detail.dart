// ignore_for_file: dead_code, unused_element, unused_element_parameter

part of '../../main.dart';

class PlanDetailDrawer extends StatefulWidget {
  const PlanDetailDrawer({super.key, required this.plan});

  final TravelPlan plan;

  @override
  State<PlanDetailDrawer> createState() => _PlanDetailDrawerState();
}

class _PlanDetailDrawerState extends State<PlanDetailDrawer> {
  late final DraggableScrollableController _sheetController;
  bool _isFullScreen = false;
  bool _isPromotingToPage = false;

  @override
  void initState() {
    super.initState();
    _sheetController = DraggableScrollableController()
      ..addListener(_handleSheetChanged);
  }

  @override
  void dispose() {
    _sheetController
      ..removeListener(_handleSheetChanged)
      ..dispose();
    super.dispose();
  }

  void _handleSheetChanged() {
    if (_sheetController.size > .955 && !_isPromotingToPage) {
      _isPromotingToPage = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => PlanDetailFullPage(plan: widget.plan),
          ),
        );
      });
      return;
    }

    final nextFullScreen = _sheetController.size > .985;
    if (nextFullScreen != _isFullScreen) {
      setState(() => _isFullScreen = nextFullScreen);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: .88,
      minChildSize: .46,
      maxChildSize: 1,
      expand: false,
      snap: true,
      snapSizes: const [.88, 1],
      builder: (context, scrollController) {
        final topPadding = _isFullScreen
            ? MediaQuery.viewPaddingOf(context).top + 6.0
            : 18.0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8F7),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(_isFullScreen ? 0 : 30),
                  ),
                ),
                child: _PlanDetailContent(
                  plan: widget.plan,
                  controller: scrollController,
                  showHandle: false,
                  topPadding: topPadding,
                  onClose: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            if (!_isFullScreen) const _SheetTopGrip(),
          ],
        );
      },
    );
  }
}

class PlanDetailFullPage extends StatelessWidget {
  const PlanDetailFullPage({super.key, required this.plan});

  final TravelPlan plan;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      body: SafeArea(
        bottom: false,
        child: _PlanDetailContent(
          plan: plan,
          showHandle: false,
          showCoverClose: true,
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}

class _PlanDetailTopBar extends StatelessWidget {
  const _PlanDetailTopBar({required this.title, required this.onClose});

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111111),
                ),
              ),
            ),
            IconButton.filled(
              onPressed: onClose,
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF111111),
              ),
              icon: const Icon(Icons.close_rounded, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanDetailContent extends StatelessWidget {
  const _PlanDetailContent({
    required this.plan,
    required this.showHandle,
    required this.onClose,
    this.controller,
    this.topPadding,
    this.showCoverClose = false,
  });

  final TravelPlan plan;
  final ScrollController? controller;
  final bool showHandle;
  final VoidCallback onClose;
  final double? topPadding;
  final bool showCoverClose;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ListView(
            controller: controller,
            padding: EdgeInsets.fromLTRB(
              18,
              topPadding ?? (showHandle ? 0 : 6),
              18,
              100,
            ),
            children: [
              _PlanCover(plan: plan, onClose: showCoverClose ? onClose : null),
              const SizedBox(height: 16),
              const _PlanTags(),
              const SizedBox(height: 14),
              Text(
                '${plan.title} \u8def ${plan.days}\u5929',
                style: const TextStyle(
                  fontSize: 22,
                  height: 1.16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                  color: Color(0xFF141414),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _PlanMeta(
                    icon: Icons.payments_outlined,
                    text: '\u00a5${plan.days * 320} \u4eba\u5747',
                  ),
                  const SizedBox(width: 18),
                  _PlanMeta(
                    icon: Icons.map_outlined,
                    text: '${plan.places} \u4e2a\u5730\u70b9',
                  ),
                  const SizedBox(width: 18),
                  _PlanMeta(
                    icon: Icons.calendar_month_outlined,
                    text: _planDateRangeLabel(plan),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(height: 1, color: Color(0xFFE5E5E5)),
              const SizedBox(height: 18),
              Text(
                _planDetailDescription(plan),
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.7,
                  color: Color(0xFF747474),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 22),
              _PlanMiniMapCard(plan: plan),
              const SizedBox(height: 13),
              _PlanTimelineSection(plan: plan),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Center(
            child: SizedBox(
              width: 258,
              child: Container(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.paddingOf(context).bottom + 12,
                ),
                child: _PlanStartBar(plan: plan),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PlanCover extends StatelessWidget {
  const _PlanCover({required this.plan, this.onClose});

  final TravelPlan plan;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: 1.78,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _AmapPlanCoverImage(plan: plan),
            if (onClose != null)
              Positioned(
                right: 12,
                top: 12,
                child: _HeroCloseButton(onPressed: onClose!),
              ),
          ],
        ),
      ),
    );
  }
}

class _AmapPlanCoverImage extends StatelessWidget {
  const _AmapPlanCoverImage({required this.plan});

  final TravelPlan plan;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: fetchAmapPhotoUrls(
        keyword: _planCoverKeyword(plan),
        city: _planCoverCity(plan),
        types: '110000',
      ),
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState != ConnectionState.done;
        if (isLoading && !snapshot.hasData) {
          return const _PlanCoverLoading();
        }

        final urls = (snapshot.data?.isNotEmpty == true
            ? snapshot.data!.cast<String>()
            : <String>[]);
        if (urls.isEmpty) {
          return const _PlanCoverErrorPlaceholder();
        }
        return _PlanCoverCarousel(urls: urls);
      },
    );
  }
}

class _PlanCoverLoading extends StatelessWidget {
  const _PlanCoverLoading();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFEDEDED),
      child: Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _PlanCoverErrorPlaceholder extends StatelessWidget {
  const _PlanCoverErrorPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFEDEDED),
      child: Center(
        child: Icon(Icons.image_outlined, size: 30, color: Color(0xFFBDBDBD)),
      ),
    );
  }
}

class _PlanCoverCarousel extends StatefulWidget {
  const _PlanCoverCarousel({required this.urls});

  final List<String> urls;

  @override
  State<_PlanCoverCarousel> createState() => _PlanCoverCarouselState();
}

class _PlanCoverCarouselState extends State<_PlanCoverCarousel> {
  late final PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void didUpdateWidget(covariant _PlanCoverCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.urls != widget.urls) {
      _index = 0;
      if (_controller.hasClients) _controller.jumpToPage(0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _controller,
          itemCount: widget.urls.length,
          onPageChanged: (index) => setState(() => _index = index),
          itemBuilder: (context, index) {
            final url = widget.urls[index];
            return Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const _PlanCoverErrorPlaceholder(),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const ColoredBox(
                  color: Color(0xFFEDEDED),
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              },
            );
          },
        ),
        if (widget.urls.length > 1)
          Positioned(
            left: 0,
            right: 0,
            bottom: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < widget.urls.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: i == _index ? 16 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: i == _index ? .95 : .55,
                      ),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PlanTags extends StatelessWidget {
  const _PlanTags();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _PlanTag(icon: Icons.account_balance_outlined, text: '\u5efa\u7b51'),
        SizedBox(width: 8),
        _PlanTag(icon: Icons.eco_outlined, text: '\u81ea\u7136'),
        SizedBox(width: 8),
        _PlanTag(icon: Icons.museum_outlined, text: '\u4eba\u6587'),
      ],
    );
  }
}

class _PlanTag extends StatelessWidget {
  const _PlanTag({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF6C6C6C)),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF6C6C6C),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanMeta extends StatelessWidget {
  const _PlanMeta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF8A8A8A)),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF777777),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanMiniMapCard extends StatelessWidget {
  const _PlanMiniMapCard({required this.plan});

  final TravelPlan plan;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 199,
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _DetailRouteMap(plan: plan),
      ),
    );
  }
}

class _PlanTimelineSection extends StatelessWidget {
  const _PlanTimelineSection({required this.plan});

  final TravelPlan plan;

  @override
  Widget build(BuildContext context) {
    final days = _dailyPlanFor(plan);
    return Column(
      key: const Key('plan-detail-figma-timeline'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '\u884c\u7a0b\u5b89\u6392',
          style: TextStyle(
            fontSize: 14,
            height: 1,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
            color: Color(0xFF111111),
          ),
        ),
        const SizedBox(height: 8),
        Column(
          children: [
            for (var i = 0; i < days.length; i++)
              _TimelineDayRow(
                plan: plan,
                day: days[i],
                accent: plan.accent,
                isFirst: i == 0,
                isLast: i == days.length - 1,
              ),
          ],
        ),
      ],
    );
  }
}

class _TimelineDayRow extends StatelessWidget {
  const _TimelineDayRow({
    required this.plan,
    required this.day,
    required this.accent,
    required this.isFirst,
    required this.isLast,
  });

  final TravelPlan plan;
  final _DailyPlan day;
  final Color accent;
  final bool isFirst;
  final bool isLast;

  static const _lineGray = Color(0xFFE5E5E5);
  static const _lineW = 2.0;
  static const _rowH = 130.0;
  static const _dotSize = 17.0;
  static const _dotRowTop = 3.0; // 圆点距行顶

  @override
  Widget build(BuildContext context) {
    final lineBottomLast = _rowH - _dotRowTop - _dotSize / 2;

    return SizedBox(
      height: _rowH,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 贯穿直线（浅灰）— 跨越全部行，无截断
          Positioned(
            left: (_dotSize - _lineW) / 2,
            top: isFirst ? 8.0 : 0,
            bottom: isLast ? lineBottomLast : 0,
            child: Container(
              width: _lineW,
              decoration: BoxDecoration(
                color: _lineGray,
                borderRadius: isFirst
                    ? const BorderRadius.vertical(top: Radius.circular(1))
                    : null,
              ),
            ),
          ),
          // 圆点 + 卡片
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: _dotRowTop),
                child: SizedBox(
                  width: _dotSize,
                  height: _dotSize,
                  child: Container(
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Color(0xFF111111),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x30000000),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '${day.index}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _DailyPlanCard(
                  day: day,
                  accent: accent,
                  onTap: () => _openDailyPlanRoute(context, plan, day),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlanRouteInlineSection extends StatelessWidget {
  const _PlanRouteInlineSection({required this.plan});

  final TravelPlan plan;

  @override
  Widget build(BuildContext context) => _PlanTimelineSection(plan: plan);
}

class _PlanStartBar extends StatelessWidget {
  const _PlanStartBar({required this.plan});

  final TravelPlan plan;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 66,
      child: Row(
        children: [
          Material(
            color: Colors.white,
            shape: const CircleBorder(),
            elevation: 10,
            shadowColor: const Color(0x24000000),
            child: IconButton(
              onPressed: () {},
              style: IconButton.styleFrom(
                foregroundColor: const Color(0xFF111111),
                fixedSize: const Size(66, 66),
              ),
              icon: const Icon(Icons.edit_outlined, size: 22),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: FilledButton(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF020202),
                foregroundColor: Colors.white,
                fixedSize: const Size.fromHeight(66),
                elevation: 10,
                shadowColor: const Color(0x30000000),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(33),
                ),
                padding: const EdgeInsets.fromLTRB(28, 0, 10, 0),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      '\u5f00\u59cb\u4f60\u7684\u65c5\u884c\uff01',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFF292929),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.near_me_rounded, size: 17),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteSummaryTile extends StatelessWidget {
  const _RouteSummaryTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .16),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF151515),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF8A8A8A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteSectionTitle extends StatelessWidget {
  const _RouteSectionTitle({
    required this.icon,
    required this.title,
    required this.action,
  });

  final IconData icon;
  final String title;
  final String action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF1F2230)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFF151515),
            ),
          ),
        ),
        Text(
          action,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Color(0xFF8A8A8A),
          ),
        ),
      ],
    );
  }
}

class _RouteSegmentCard extends StatelessWidget {
  const _RouteSegmentCard({
    required this.segment,
    required this.index,
    required this.accent,
  });

  final _RouteSegment segment;
  final int index;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .16),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$index',
              style: TextStyle(
                color: accent,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${segment.from}  →  ${segment.to}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF151515),
                  ),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _TinyRoutePill(
                      icon: Icons.directions_car_filled_outlined,
                      text: segment.transport,
                    ),
                    _TinyRoutePill(
                      icon: Icons.straighten_rounded,
                      text: '${segment.distanceKm} km',
                    ),
                    _TinyRoutePill(
                      icon: Icons.schedule_rounded,
                      text: '${segment.durationHours.toStringAsFixed(1)} h',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  segment.note,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF707070),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyRoutePill extends StatelessWidget {
  const _TinyRoutePill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: const Color(0xFF777777)),
            const SizedBox(width: 4),
            Text(
              text,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF666666),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyPlanCard extends StatelessWidget {
  const _DailyPlanCard({required this.day, required this.accent, this.onTap});

  final _DailyPlan day;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 112,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(9, 9, 10, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(7),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFE0E0E0),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Day ${day.index}',
                      style: const TextStyle(
                        fontSize: 8,
                        height: 1,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111111),
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    day.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                      color: Color(0xFF111111),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    day.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      height: 1.25,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0,
                      color: Color(0xFF8A8A8A),
                    ),
                  ),
                  const Spacer(),
                  const Row(
                    children: [
                      _DailyPlanTag(
                        icon: Icons.directions_bus_outlined,
                        label: '\u5730\u94c1+\u6b65\u884c',
                      ),
                      SizedBox(width: 6),
                      _DailyPlanTag(
                        icon: Icons.pin_drop_outlined,
                        label: '12\u516c\u91cc',
                      ),
                      SizedBox(width: 6),
                      _DailyPlanTag(
                        icon: Icons.schedule_outlined,
                        label: '\u7ea64\u5c0f\u65f6',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 7),
            _DailyPlanImage(day: day.title),
          ],
        ),
      ),
    );
  }
}

class _DailyPlanTag extends StatelessWidget {
  const _DailyPlanTag({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 14,
      padding: EdgeInsets.only(left: icon != null ? 6 : 11, right: 11),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 8, color: const Color(0xFFB3B3B3)),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              height: 1,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
              color: Color(0xFFB3B3B3),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyPlanImage extends StatefulWidget {
  const _DailyPlanImage({required this.day});

  final String day;

  @override
  State<_DailyPlanImage> createState() => _DailyPlanImageState();
}

class _DailyPlanImageState extends State<_DailyPlanImage> {
  String? _url;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final urls = await fetchAmapPhotoUrls(
        keyword: widget.day,
        city: '',
        types: '110000',
      );
      if (mounted && urls.isNotEmpty) {
        setState(() => _url = urls.first);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(7),
      child: SizedBox(
        width: 93,
        height: 93,
        child: _url != null
            ? Image.network(
                _url!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return const ColoredBox(
      color: Color(0xFFEDEDED),
      child: Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

void _openDailyPlanRoute(
  BuildContext context,
  TravelPlan plan,
  _DailyPlan day,
) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => _DailyPlanRoutePage(plan: plan, day: day),
    ),
  );
}

class _DailyPlanRoutePage extends StatelessWidget {
  const _DailyPlanRoutePage({required this.plan, required this.day});

  final TravelPlan plan;
  final _DailyPlan day;

  @override
  Widget build(BuildContext context) {
    final stops = _dailyRouteStopsFor(plan, day);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.zero,
            children: [
              SizedBox(
                height: 224,
                width: double.infinity,
                child: _DailyPlanHeroImage(keyword: day.title),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(19, 16, 16, 108),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 12,
                          color: Color(0xFF111111),
                        ),
                        const SizedBox(width: 9),
                        Text(
                          _dailyRouteDateLabel(plan, day),
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0,
                            color: Color(0xFF111111),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _DailyRouteTitle(plan: plan, day: day),
                        ),
                        const SizedBox(width: 12),
                        _DailyWeatherBadge(plan: plan),
                      ],
                    ),
                    const SizedBox(height: 11),
                    Text(
                      _dailyRouteDescription(plan, day),
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0,
                        color: Color(0xFF777777),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _DailyRouteStats(plan: plan, stops: stops),
                    const SizedBox(height: 17),
                    _DailyAiNote(day: day),
                    const SizedBox(height: 13),
                    const _DailyRouteDots(),
                    const SizedBox(height: 14),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFE7E7E7),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            '\u884c\u7a0b\u7ad9\u70b9',
                            style: TextStyle(
                              fontSize: 14,
                              height: 1,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                              color: Color(0xFF111111),
                            ),
                          ),
                        ),
                        const _AddDailyStopButton(),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _DailyStopsTimeline(stops: stops),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            left: 68,
            right: 67,
            bottom: 17 + MediaQuery.viewPaddingOf(context).bottom,
            child: const _DailyRouteStartButton(),
          ),
        ],
      ),
    );
  }
}

class _DailyPlanHeroImage extends StatefulWidget {
  const _DailyPlanHeroImage({required this.keyword});

  final String keyword;

  @override
  State<_DailyPlanHeroImage> createState() => _DailyPlanHeroImageState();
}

class _DailyPlanHeroImageState extends State<_DailyPlanHeroImage> {
  String? _url;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final urls = await fetchAmapPhotoUrls(
        keyword: widget.keyword,
        city: '',
        types: '110000',
      );
      if (mounted && urls.isNotEmpty) {
        setState(() => _url = urls.first);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_url == null) {
      return const ColoredBox(color: Color(0xFFE0E0E0));
    }
    return Image.network(
      _url!,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const ColoredBox(color: Color(0xFFE0E0E0)),
    );
  }
}

class _DailyWeatherBadge extends StatelessWidget {
  const _DailyWeatherBadge({required this.plan});

  final TravelPlan plan;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 89,
      height: 40,
      padding: const EdgeInsets.fromLTRB(12, 0, 7, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              '10\u2103',
              style: TextStyle(
                fontSize: 14,
                height: 1,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
                color: Color(0xFF111111),
              ),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Image.asset(
              _planCoverAsset(plan),
              width: 30,
              height: 22,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyRouteTitle extends StatelessWidget {
  const _DailyRouteTitle({required this.plan, required this.day});

  final TravelPlan plan;
  final _DailyPlan day;

  @override
  Widget build(BuildContext context) {
    final start = _dailyRouteAnchor(plan, day.index);
    final end = _dailyRouteAnchor(plan, day.index + 1);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          start,
          style: const TextStyle(
            fontSize: 18,
            height: 1,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
            color: Color(0xFF111111),
          ),
        ),
        const SizedBox(width: 22),
        const Icon(
          Icons.arrow_upward_rounded,
          size: 24,
          color: Color(0xFF111111),
        ),
        const SizedBox(width: 12),
        Text(
          end,
          style: const TextStyle(
            fontSize: 18,
            height: 1,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
            color: Color(0xFF111111),
          ),
        ),
      ],
    );
  }
}

class _DailyRouteStats extends StatelessWidget {
  const _DailyRouteStats({required this.plan, required this.stops});

  final TravelPlan plan;
  final List<_DailyRouteStop> stops;

  @override
  Widget build(BuildContext context) {
    final distance = 48 + _dailyHash(plan.title) % 53;
    return Row(
      children: [
        _DailyStatBlock(
          value: '1\u5c0f\u65f650\u5206\u949f',
          label: '\u5e73\u5747\u65f6\u95f4',
        ),
        const SizedBox(width: 44),
        const SizedBox(height: 16, child: VerticalDivider(width: 1)),
        const SizedBox(width: 42),
        _DailyStatBlock(
          value: '$distance KM',
          label: '\u603b\u516c\u91cc\u6570',
        ),
        const Spacer(),
        const SizedBox(height: 16, child: VerticalDivider(width: 1)),
        const SizedBox(width: 42),
        _DailyStatBlock(
          value: '${stops.length} \u7ad9\u70b9',
          label: '\u8ba1\u5212\u505c\u9760\u7ad9',
        ),
        const SizedBox(width: 12),
      ],
    );
  }
}

class _DailyStatBlock extends StatelessWidget {
  const _DailyStatBlock({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
              color: Color(0xFF111111),
            ),
          ),
          const Spacer(),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              height: 1,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
              color: Color(0xFF888888),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyAiNote extends StatefulWidget {
  const _DailyAiNote({required this.day});

  final _DailyPlan day;

  @override
  State<_DailyAiNote> createState() => _DailyAiNoteState();
}

class _DailyAiNoteState extends State<_DailyAiNote> {
  int _tipIndex = 0;
  Timer? _timer;

  static const _tipsPool = [
    '出发前检查天气，雨天备好雨具和防水鞋',
    '热门景点尽量赶早，避开人流高峰',
    '随身带好充电宝，拍照导航耗电快',
    '提前下载离线地图，信号不好也能导航',
    '穿舒适的鞋子，一天走下来脚会很累',
    '当地特色小吃别错过，街边小店往往更好吃',
    '拍照选黄金时段，日出日落光线最美',
    '预留足够的交通时间，别把行程排太满',
    '随身带些现金零钱，有些小店只收现金',
    '注意保管好随身物品，人多的地方要当心',
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      setState(() {
        _tipIndex = (_tipIndex + 1) % (_tipsPool.length + 1);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _currentTip {
    if (_tipIndex == 0) return widget.day.description;
    return _tipsPool[(_tipIndex - 1) % _tipsPool.length];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.fromLTRB(11, 0, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          ClipOval(
            child: Image.asset(
              'assets/images/ai.png',
              width: 30,
              height: 30,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Text(
                _currentTip,
                key: ValueKey(_tipIndex),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  height: 1.25,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF777777),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyRouteDots extends StatelessWidget {
  const _DailyRouteDots();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DailyDot(active: true),
          SizedBox(width: 3),
          _DailyDot(active: false),
          SizedBox(width: 3),
          _DailyDot(active: false),
        ],
      ),
    );
  }
}

class _DailyDot extends StatelessWidget {
  const _DailyDot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(
        color: active ? const Color(0xFF111111) : const Color(0xFFD9D9D9),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _AddDailyStopButton extends StatelessWidget {
  const _AddDailyStopButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add_rounded, size: 17, color: Color(0xFF111111)),
          SizedBox(width: 6),
          Text(
            '\u6dfb\u52a0\u7ad9\u70b9',
            style: TextStyle(
              fontSize: 12,
              height: 1,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111111),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyStopsTimeline extends StatelessWidget {
  const _DailyStopsTimeline({required this.stops});

  final List<_DailyRouteStop> stops;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 10,
          top: 10,
          bottom: 38,
          child: Container(width: 1, color: const Color(0xFFBDBDBD)),
        ),
        Column(
          children: [
            for (var i = 0; i < stops.length; i++)
              _DailyStopRow(
                stop: stops[i],
                index: i + 1,
                isLast: i == stops.length - 1,
              ),
          ],
        ),
      ],
    );
  }
}

class _DailyStopRow extends StatelessWidget {
  const _DailyStopRow({
    required this.stop,
    required this.index,
    required this.isLast,
  });

  final _DailyRouteStop stop;
  final int index;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.zero,
            child: Image.asset(
              index == 1
                  ? 'assets/icons/Group 51.png'
                  : 'assets/icons/Group 52.png',
              width: 20,
              height: 20,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Container(
              height: 78,
              padding: const EdgeInsets.fromLTRB(13, 12, 13, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(9),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stop.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF111111),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(
                        Icons.alarm_rounded,
                        size: 12,
                        color: Color(0xFF9B9B9B),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        stop.time,
                        style: const TextStyle(
                          fontSize: 11,
                          height: 1,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF8A8A8A),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const SizedBox(
                        height: 16,
                        child: VerticalDivider(
                          width: 1,
                          color: Color(0xFFD8D8D8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: Color(0xFF9B9B9B),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          stop.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            height: 1,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF8A8A8A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyRouteStartButton extends StatelessWidget {
  const _DailyRouteStartButton();

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: () {},
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF020202),
        foregroundColor: Colors.white,
        fixedSize: const Size.fromHeight(58),
        elevation: 10,
        shadowColor: const Color(0x30000000),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(29)),
        padding: const EdgeInsets.fromLTRB(84, 0, 14, 0),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              '\u5f00\u542f\u8def\u7ebf',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFF292929),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.near_me_rounded, size: 17),
          ),
        ],
      ),
    );
  }
}

class _DailyRouteStop {
  const _DailyRouteStop({
    required this.title,
    required this.time,
    required this.address,
  });

  final String title;
  final String time;
  final String address;
}

class _RouteSegment {
  const _RouteSegment({
    required this.from,
    required this.to,
    required this.transport,
    required this.distanceKm,
    required this.durationHours,
    required this.note,
  });

  final String from;
  final String to;
  final String transport;
  final int distanceKm;
  final double durationHours;
  final String note;
}

class _DailyPlan {
  const _DailyPlan({
    required this.index,
    required this.title,
    required this.description,
  });

  final int index;
  final String title;
  final String description;
}

List<_RouteSegment> _routeSegmentsFor(TravelPlan plan) {
  final overrides = _routeSegmentOverrides[plan.title];
  if (overrides != null) return overrides;

  final stops = plan.routeStops;
  return [
    for (var i = 0; i < stops.length - 1; i++)
      _RouteSegment(
        from: stops[i].label,
        to: stops[i + 1].label,
        transport: '自驾/包车',
        distanceKm: _estimateDistanceKm(stops[i], stops[i + 1]),
        durationHours: _estimateDistanceKm(stops[i], stops[i + 1]) / 72,
        note: '建议上午出发，抵达后先办理入住，再安排轻量游玩。',
      ),
  ];
}

List<_DailyPlan> _dailyPlanFor(TravelPlan plan) {
  final overrides = _dailyPlanOverrides[plan.title];
  if (overrides != null) return overrides;

  final stops = plan.routeStops;
  return [
    for (var day = 1; day <= plan.days; day++)
      _DailyPlan(
        index: day,
        title: '${stops[((day - 1) * stops.length) ~/ plan.days].label}慢游',
        description: day == 1
            ? '抵达集合，整理行李，适应节奏，晚上补充当地美食。'
            : '上午安排核心景点，下午留给拍照和城市漫步，晚上复盘第二天路线。',
      ),
  ];
}

String _dailyRouteDateLabel(TravelPlan plan, _DailyPlan day) {
  final parsed = _parsePlanStartDate(plan.dateRange);
  if (parsed == null) return '3\u670811 \u661f\u671f\u5929';
  final date = parsed.add(Duration(days: day.index - 1));
  const weekdays = [
    '\u661f\u671f\u4e00',
    '\u661f\u671f\u4e8c',
    '\u661f\u671f\u4e09',
    '\u661f\u671f\u56db',
    '\u661f\u671f\u4e94',
    '\u661f\u671f\u516d',
    '\u661f\u671f\u5929',
  ];
  return '${date.month}\u6708${date.day} ${weekdays[date.weekday - 1]}';
}

DateTime? _parsePlanStartDate(String dateRange) {
  final start = dateRange.split('~').first;
  final parts = start.split('.');
  if (parts.length != 3) return null;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) return null;
  return DateTime(year, month, day);
}

String _dailyRouteAnchor(TravelPlan plan, int dayIndex) {
  final stops = plan.routeStops;
  if (stops.isEmpty) return plan.title;
  final source = ((dayIndex - 1) * stops.length) ~/ plan.days;
  final index = source < 0
      ? 0
      : source >= stops.length
      ? stops.length - 1
      : source;
  return stops[index].label;
}

String _dailyRouteDescription(TravelPlan plan, _DailyPlan day) {
  final start = _dailyRouteAnchor(plan, day.index);
  final end = _dailyRouteAnchor(plan, day.index + 1);
  return '\u4ece$start\u51fa\u53d1\u524d\u5f80$end\uff0c'
      '\u8def\u7ebf\u878d\u5408\u6587\u5316\u3001\u98ce\u666f\u4e0e\u653e\u677e\u4f53\u9a8c\u3002';
}

List<_DailyRouteStop> _dailyRouteStopsFor(TravelPlan plan, _DailyPlan day) {
  final start = _dailyRouteAnchor(plan, day.index);
  final end = _dailyRouteAnchor(plan, day.index + 1);
  final hub = _dailyRouteAnchor(plan, day.index + 2);
  return [
    _DailyRouteStop(
      title: '$start\u9152\u5e97',
      time: '8:30',
      address: _dailyPoiAddress(start, '\u9152\u5e97'),
    ),
    _DailyRouteStop(
      title: '$start\u2192$end',
      time: '10:20',
      address: _dailyPoiAddress(end, '\u98ce\u666f\u533a\u5165\u53e3'),
    ),
    _DailyRouteStop(
      title: '$end\u6df1\u5ea6\u6e38',
      time: '13:30',
      address: _dailyPoiAddress(end, '\u6838\u5fc3\u6e38\u89c8\u7ebf'),
    ),
    _DailyRouteStop(
      title: '$hub\u4f11\u6574',
      time: '17:40',
      address: _dailyPoiAddress(hub, '\u4f4f\u5bbf\u4e0e\u9910\u996e\u533a'),
    ),
  ];
}

String _dailyPoiAddress(String stop, String poi) {
  final cleanStop = stop.replaceAll(RegExp(r'\s+'), '');
  return '$cleanStop\u9644\u8fd1\u00b7$poi';
}

int _dailyHash(String value) {
  var result = 0;
  for (final unit in value.codeUnits) {
    result = (result * 31 + unit) & 0x7fffffff;
  }
  return result;
}

int _estimateDistanceKm(RouteStop from, RouteStop to) {
  final dx = (from.position.dx - to.position.dx).abs();
  final dy = (from.position.dy - to.position.dy).abs();
  return (90 + (dx + dy) * 520).round();
}

const Map<String, List<_RouteSegment>> _routeSegmentOverrides = {
  '青甘大环线10天游': [
    _RouteSegment(
      from: '西宁',
      to: '青海湖',
      transport: '包车/自驾',
      distanceKm: 150,
      durationHours: 2.5,
      note: '下午抵达湖边更适合看光线，旺季建议提前确认湖景住宿。',
    ),
    _RouteSegment(
      from: '青海湖',
      to: '茶卡',
      transport: '包车/自驾',
      distanceKm: 150,
      durationHours: 2.2,
      note: '清晨或傍晚进盐湖，避开正午强光和人流高峰。',
    ),
    _RouteSegment(
      from: '茶卡',
      to: '敦煌',
      transport: '包车/自驾',
      distanceKm: 720,
      durationHours: 8.5,
      note: '这是全程最长车段，建议中途安排补给点，不塞满景点。',
    ),
    _RouteSegment(
      from: '敦煌',
      to: '张掖',
      transport: '动车/包车',
      distanceKm: 590,
      durationHours: 6.5,
      note: '先看莫高窟和鸣沙山，再转张掖丹霞，视觉节奏更完整。',
    ),
  ],
  '川西雪山小团行': [
    _RouteSegment(
      from: '成都',
      to: '康定',
      transport: '包车/自驾',
      distanceKm: 270,
      durationHours: 4.5,
      note: '首日海拔爬升明显，抵达后不安排高强度徒步。',
    ),
    _RouteSegment(
      from: '康定',
      to: '新都桥',
      transport: '包车/自驾',
      distanceKm: 80,
      durationHours: 2,
      note: '翻越折多山后进入摄影路段，预留停车拍照时间。',
    ),
    _RouteSegment(
      from: '新都桥',
      to: '塔公',
      transport: '包车/自驾',
      distanceKm: 35,
      durationHours: 1,
      note: '短距离移动，适合把草原、寺庙和咖啡休息串在一天。',
    ),
    _RouteSegment(
      from: '塔公',
      to: '四姑娘山',
      transport: '包车/自驾',
      distanceKm: 260,
      durationHours: 5,
      note: '路况受天气影响较大，建议留一段机动时间。',
    ),
  ],
  '杭州情侣周末游': [
    _RouteSegment(
      from: '西湖',
      to: '灵隐',
      transport: '打车/公交',
      distanceKm: 7,
      durationHours: .5,
      note: '上午去灵隐更清静，下午回湖边散步。',
    ),
    _RouteSegment(
      from: '灵隐',
      to: '河坊街',
      transport: '打车',
      distanceKm: 9,
      durationHours: .5,
      note: '晚餐安排在河坊街一带，步行体验更完整。',
    ),
    _RouteSegment(
      from: '河坊街',
      to: '滨江',
      transport: '地铁/打车',
      distanceKm: 12,
      durationHours: .7,
      note: '傍晚过江看城市夜景，节奏轻松。',
    ),
    _RouteSegment(
      from: '滨江',
      to: '钱江',
      transport: '步行/骑行',
      distanceKm: 5,
      durationHours: .4,
      note: '适合安排江边骑行和日落拍照。',
    ),
  ],
  '云南朋友毕业旅行': [
    _RouteSegment(
      from: '昆明',
      to: '大理',
      transport: '动车',
      distanceKm: 330,
      durationHours: 2.2,
      note: '动车效率最高，抵达后直接住古城或洱海边。',
    ),
    _RouteSegment(
      from: '大理',
      to: '丽江',
      transport: '动车/包车',
      distanceKm: 160,
      durationHours: 2,
      note: '上午环洱海，下午移动到丽江更顺路。',
    ),
    _RouteSegment(
      from: '丽江',
      to: '泸沽湖',
      transport: '商务车',
      distanceKm: 200,
      durationHours: 4.5,
      note: '山路时间较长，建议轻装并提前备晕车药。',
    ),
    _RouteSegment(
      from: '泸沽湖',
      to: '香格里拉',
      transport: '包车',
      distanceKm: 360,
      durationHours: 6.5,
      note: '跨区域移动日不要塞活动，抵达后以休息适应海拔为主。',
    ),
  ],
};

const Map<String, List<_DailyPlan>> _dailyPlanOverrides = {
  '青甘大环线10天游': [
    _DailyPlan(
      index: 1,
      title: '西宁集合',
      description: '抵达西宁，补给防晒和保暖装备，晚上吃本地羊肉与面片。',
    ),
    _DailyPlan(
      index: 2,
      title: '西宁 → 青海湖',
      description: '塔尔寺或日月山后前往青海湖，傍晚看湖边日落。',
    ),
    _DailyPlan(
      index: 3,
      title: '青海湖深度游',
      description: '沿湖轻松拍照，避开高强度赶路，晚上住茶卡方向。',
    ),
    _DailyPlan(
      index: 4,
      title: '茶卡盐湖',
      description: '清晨进入盐湖，下午转向柴达木盆地，控制车程疲劳。',
    ),
    _DailyPlan(index: 5, title: '穿越无人区', description: '安排公路风景和补给点，保持轻量景点节奏。'),
    _DailyPlan(index: 6, title: '抵达敦煌', description: '下午休整，晚上去沙洲夜市，准备第二天莫高窟。'),
    _DailyPlan(index: 7, title: '敦煌双核心', description: '莫高窟预约上午场，傍晚鸣沙山月牙泉。'),
    _DailyPlan(index: 8, title: '敦煌 → 张掖', description: '城际移动为主，中途安排服务区和轻量观景。'),
    _DailyPlan(index: 9, title: '张掖丹霞', description: '下午进入七彩丹霞，等日落颜色最饱满。'),
    _DailyPlan(index: 10, title: '张掖返程', description: '上午补拍或买伴手礼，下午返程收尾。'),
  ],
};

String _planDateRangeLabel(TravelPlan plan) {
  final parts = plan.dateRange.split('~');
  if (parts.length != 2) return plan.dateRange;
  final startParts = parts.first.split('.');
  final endParts = parts.last.split('.');
  if (startParts.length != 3 || endParts.length != 3) return plan.dateRange;
  return '${startParts[1]}/${startParts[2]}-${endParts[1]}/${endParts[2]}';
}

String _planDetailDescription(TravelPlan plan) {
  final start = plan.routeStops.first.label;
  final end = plan.routeStops.last.label;
  return '这是一段为期${plan.days}天的中文旅行计划，路线从$start出发一路抵达$end，串联${plan.places}个灵感地点，适合${plan.members}人同行。行程兼顾城市漫步、自然风景与本地人文体验，节奏舒适，适合第一次探索这条路线的旅行者。';
}

String _planCoverAsset(TravelPlan plan) {
  if (plan.title.contains('青甘')) return 'assets/images/photo-xinjiang.png';
  if (plan.title.contains('川西')) return 'assets/images/photo-sichuan.png';
  if (plan.title.contains('杭州')) {
    return 'assets/images/c7fada39e6124c21b44577c65e25f962.webp';
  }
  if (plan.title.contains('云南')) return 'assets/images/photo-neimenggu.png';
  return _planCoverAssetFallback;
}

String _planCoverKeyword(TravelPlan plan) {
  if (plan.title.contains('青甘')) return '青海湖景区';
  if (plan.title.contains('川西')) return '四姑娘山景区';
  if (plan.title.contains('杭州')) return '西湖风景名胜区';
  if (plan.title.contains('云南')) return '香格里拉普达措国家公园';
  return plan.routeStops.last.label;
}

String _planCoverCity(TravelPlan plan) {
  if (plan.title.contains('青甘')) return '西宁';
  if (plan.title.contains('川西')) return '阿坝';
  if (plan.title.contains('杭州')) return '杭州';
  if (plan.title.contains('云南')) return '迪庆';
  return '';
}

class _DetailRouteMap extends StatelessWidget {
  const _DetailRouteMap({required this.plan});

  final TravelPlan plan;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(painter: _FigmaDetailMapPainter(plan)),
        ),
        Positioned(
          right: 12,
          bottom: 49,
          child: _DetailMapZoomControl(onTap: () {}),
        ),
        Positioned(
          right: 14,
          bottom: 14,
          child: _DetailMapLocateButton(onTap: () {}),
        ),
      ],
    );
  }
}

class _FigmaDetailMapPainter extends CustomPainter {
  const _FigmaDetailMapPainter(this.plan);

  final TravelPlan plan;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFF7F9FA),
    );

    final parkPaint = Paint()..color = const Color(0xFFBFEFC7);
    final paleParkPaint = Paint()..color = const Color(0xFFDDF7E2);
    canvas.drawPath(
      Path()
        ..moveTo(size.width * .72, size.height * .33)
        ..lineTo(size.width * .96, size.height * .22)
        ..lineTo(size.width * .98, size.height * .74)
        ..lineTo(size.width * .76, size.height * .9)
        ..lineTo(size.width * .66, size.height * .66)
        ..close(),
      paleParkPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width * .02, size.height * .7)
        ..lineTo(size.width * .22, size.height * .58)
        ..lineTo(size.width * .28, size.height * .92)
        ..lineTo(size.width * .02, size.height * .98)
        ..close(),
      parkPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width * .74, size.height * .54)
        ..lineTo(size.width * .9, size.height * .46)
        ..lineTo(size.width * .92, size.height * .72)
        ..lineTo(size.width * .79, size.height * .78)
        ..close(),
      parkPaint,
    );

    final minorRoad = Paint()
      ..color = const Color(0xFFE7EBEE)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 7; i++) {
      final y = size.height * (.12 + i * .13);
      canvas.drawLine(
        Offset(-8, y),
        Offset(size.width + 8, y + (i.isEven ? 11 : -8)),
        minorRoad,
      );
    }
    for (var i = 0; i < 6; i++) {
      final x = size.width * (.12 + i * .16);
      canvas.drawLine(
        Offset(x, -8),
        Offset(x + (i.isEven ? 26 : -12), size.height + 8),
        minorRoad,
      );
    }

    void drawRoad(List<Offset> points, {double width = 12}) {
      final border = Paint()
        ..color = const Color(0xFFE0E5E8)
        ..strokeWidth = width + 2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      final fill = Paint()
        ..color = Colors.white
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      final path = Path();
      for (var i = 0; i < points.length; i++) {
        final point = Offset(
          points[i].dx * size.width,
          points[i].dy * size.height,
        );
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      canvas.drawPath(path, border);
      canvas.drawPath(path, fill);
    }

    drawRoad(const [
      Offset(-.03, .2),
      Offset(.34, .42),
      Offset(.63, .38),
      Offset(1.04, .12),
    ], width: 10);
    drawRoad(const [
      Offset(.02, .86),
      Offset(.35, .62),
      Offset(.65, .44),
      Offset(.96, .34),
    ], width: 9);
    drawRoad(const [
      Offset(.23, -.04),
      Offset(.26, .35),
      Offset(.3, .82),
      Offset(.32, 1.06),
    ], width: 8);
    drawRoad(const [
      Offset(.58, -.05),
      Offset(.55, .32),
      Offset(.5, .7),
      Offset(.46, 1.04),
    ], width: 8);
    drawRoad(const [
      Offset(.82, -.04),
      Offset(.72, .32),
      Offset(.68, .66),
      Offset(.62, 1.03),
    ], width: 8);

    final labelStyle = const TextStyle(
      fontSize: 7,
      height: 1,
      fontWeight: FontWeight.w600,
      color: Color(0xFF7D8A94),
    );
    final redStyle = labelStyle.copyWith(color: const Color(0xFFE66565));
    final blueStyle = labelStyle.copyWith(color: const Color(0xFF348BE8));
    final orangeStyle = labelStyle.copyWith(color: const Color(0xFFF08A23));

    final labels = <({String text, Offset at, Color dot, TextStyle style})>[
      (
        text: plan.routeStops.first.label,
        at: const Offset(.18, .24),
        dot: const Color(0xFF3C8DFF),
        style: blueStyle,
      ),
      (
        text: plan.routeStops.length > 1
            ? plan.routeStops[1].label
            : plan.title,
        at: const Offset(.37, .38),
        dot: const Color(0xFFFFA726),
        style: orangeStyle,
      ),
      (
        text: plan.routeStops.length > 2
            ? plan.routeStops[2].label
            : plan.title,
        at: const Offset(.54, .58),
        dot: const Color(0xFF2EBB70),
        style: blueStyle,
      ),
      (
        text: plan.routeStops.last.label,
        at: const Offset(.78, .48),
        dot: const Color(0xFFE95858),
        style: redStyle,
      ),
      (
        text: '\u5730\u94c1\u7ad9',
        at: const Offset(.23, .74),
        dot: const Color(0xFF348BE8),
        style: blueStyle,
      ),
      (
        text: '\u5546\u5708',
        at: const Offset(.68, .24),
        dot: const Color(0xFFFFA726),
        style: orangeStyle,
      ),
      (
        text: '\u516c\u56ed',
        at: const Offset(.86, .66),
        dot: const Color(0xFF2EBB70),
        style: labelStyle,
      ),
      (
        text: '\u9152\u5e97',
        at: const Offset(.46, .28),
        dot: const Color(0xFFE95858),
        style: redStyle,
      ),
      (
        text: '\u666f\u70b9',
        at: const Offset(.34, .78),
        dot: const Color(0xFF9B72E8),
        style: labelStyle.copyWith(color: const Color(0xFF9B72E8)),
      ),
      (
        text: '\u9910\u5385',
        at: const Offset(.62, .82),
        dot: const Color(0xFFFFA726),
        style: orangeStyle,
      ),
    ];
    for (final label in labels) {
      _drawMapPoi(canvas, size, label.text, label.at, label.dot, label.style);
    }
  }

  void _drawMapPoi(
    Canvas canvas,
    Size size,
    String text,
    Offset at,
    Color dot,
    TextStyle style,
  ) {
    final point = Offset(at.dx * size.width, at.dy * size.height);
    canvas.drawCircle(point, 2.4, Paint()..color = Colors.white);
    canvas.drawCircle(point, 1.8, Paint()..color = dot);
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: 70);
    painter.paint(canvas, point + const Offset(4, -3));
  }

  @override
  bool shouldRepaint(covariant _FigmaDetailMapPainter oldDelegate) =>
      oldDelegate.plan != plan;
}

class _DetailMapZoomControl extends StatelessWidget {
  const _DetailMapZoomControl({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      elevation: 5,
      shadowColor: const Color(0x20000000),
      child: SizedBox(
        width: 34,
        height: 68,
        child: Column(
          children: [
            Expanded(
              child: InkWell(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(17),
                ),
                onTap: onTap,
                child: const Center(
                  child: Icon(Icons.add, size: 19, color: Color(0xFF111111)),
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(17),
                ),
                onTap: onTap,
                child: const Center(
                  child: Icon(Icons.remove, size: 19, color: Color(0xFF111111)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailMapLocateButton extends StatelessWidget {
  const _DetailMapLocateButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 5,
      shadowColor: const Color(0x20000000),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 31,
          height: 31,
          child: Icon(
            Icons.my_location_outlined,
            size: 16,
            color: Color(0xFF111111),
          ),
        ),
      ),
    );
  }
}

class _DetailPhotoMarker extends StatelessWidget {
  const _DetailPhotoMarker({
    required this.stop,
    required this.photo,
    required this.color,
  });

  final RouteStop stop;
  final String photo;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 24 + stop.position.dx * 280,
      top: 52 + stop.position.dy * 190,
      child: Container(
        width: 52,
        height: 52,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Image.asset(photo, fit: BoxFit.cover),
            ),
            Positioned(
              right: -5,
              bottom: -5,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.place_rounded,
                  color: Colors.white,
                  size: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapControlButton extends StatelessWidget {
  const _MapControlButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 8,
      shadowColor: const Color(0x22000000),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, size: 22, color: const Color(0xFF4F4F4F)),
        ),
      ),
    );
  }
}

class _DetailTipCard extends StatelessWidget {
  const _DetailTipCard({required this.plan});

  final TravelPlan plan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16000000),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: plan.accent.withValues(alpha: .2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.tips_and_updates, color: plan.accent, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: '优先体验${plan.routeStops[1].label}，再前往',
                children: [
                  TextSpan(
                    text: plan.routeStops.last.label,
                    style: const TextStyle(
                      color: Color(0xFF111111),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const TextSpan(text: '，节奏更舒服。'),
                ],
              ),
              style: const TextStyle(
                color: Color(0xFF6D6D6D),
                fontSize: 14,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
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
        width: 160,
        height: 110,
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
  const _RouteMapPainter(this.plan, {this.detailed = false});

  final TravelPlan plan;
  final bool detailed;

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = detailed ? const Color(0xFFF7F8F7) : const Color(0xFFF5F7F5);
    canvas.drawRect(Offset.zero & size, bgPaint);

    final waterPaint = Paint()
      ..color = detailed ? const Color(0xFFE9F1F5) : const Color(0xFFDCEFF7);
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

    final parkPaint = Paint()
      ..color = detailed ? const Color(0xFFE9F4EC) : const Color(0xFFE2F1E6);
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
      ..color = detailed ? const Color(0xFFE6EAEC) : const Color(0xFFE1E6E8)
      ..strokeWidth = detailed ? 1.1 : 1.4
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
        ..color = detailed ? const Color(0xFFDDE3E6) : const Color(0xFFD1D8DC)
        ..strokeWidth = detailed ? 6 : 7
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      final roadPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = detailed ? 4.2 : 5
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
      ..strokeWidth = detailed ? 5 : 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final routePaint = Paint()
      ..color = plan.accent
      ..strokeWidth = detailed ? 2.4 : 3.4
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
        detailed ? 3.6 : (isStart || isEnd ? 5 : 4),
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        point,
        detailed ? 2.4 : (isStart || isEnd ? 3.6 : 2.7),
        Paint()..color = pinColor,
      );
      if (!detailed && !isStart && !isEnd) {
        canvas.drawCircle(
          point,
          3.4,
          Paint()
            ..color = plan.accent
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }

      if (!detailed && (i == 0 || i == plan.routeStops.length - 1)) {
        _drawLabel(canvas, stop.label, point, size);
      }
    }
  }

  Path _pathFrom(List<Offset> points, Size size) {
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final point = Offset(
        points[i].dx * size.width,
        points[i].dy * size.height,
      );
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
      oldDelegate.plan != plan || oldDelegate.detailed != detailed;
}

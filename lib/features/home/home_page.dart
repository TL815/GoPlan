// ignore_for_file: dead_code, unused_element, unused_element_parameter

part of '../../main.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _showExplore = false;
  late final AssistantConversationHistoryController _historyController;

  @override
  void initState() {
    super.initState();
    _historyController = AssistantConversationHistoryController(
      store: createProductionConversationStore(),
      userId: AiChatRuntimeConfig.defaultUserId,
    )..load();
  }

  @override
  void dispose() {
    _historyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 112),
        children: [
          const _HomeTopSection(),
          _PlanFilters(
            activeTab: _showExplore ? 1 : 0,
            onTabChanged: (index) {
              final nextShowExplore = index == 1;
              setState(() => _showExplore = nextShowExplore);
              if (nextShowExplore) {
                unawaited(_historyController.load());
              }
            },
          ),
          const SizedBox(height: 12),
          if (_showExplore)
            _AssistantConversationHistoryPane(controller: _historyController)
          else
            ...demoPlans.map(
              (plan) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PlanCard(
                  plan: plan,
                  onTap: () => _openPlanDetail(context, plan),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AssistantConversationHistoryPane extends StatefulWidget {
  const _AssistantConversationHistoryPane({required this.controller});

  final AssistantConversationHistoryController controller;

  @override
  State<_AssistantConversationHistoryPane> createState() =>
      _AssistantConversationHistoryPaneState();
}

class _AssistantConversationHistoryPaneState
    extends State<_AssistantConversationHistoryPane> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleChanged);
  }

  @override
  void didUpdateWidget(covariant _AssistantConversationHistoryPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller.removeListener(_handleChanged);
    widget.controller.addListener(_handleChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleChanged);
    super.dispose();
  }

  void _handleChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.controller.state;
    return switch (state.phase) {
      AssistantConversationHistoryPhase.loading =>
        const _AssistantHistoryLoading(),
      AssistantConversationHistoryPhase.failure => _AssistantHistoryFailure(
        onRetry: widget.controller.load,
      ),
      AssistantConversationHistoryPhase.ready =>
        state.summaries.isEmpty
            ? const _AssistantHistoryEmpty()
            : Column(
                children: [
                  for (final summary in state.summaries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _AssistantConversationSummaryCard(
                        summary: summary,
                        onTap: () =>
                            _openAssistantConversation(context, summary.id),
                      ),
                    ),
                ],
              ),
    };
  }

  Future<void> _openAssistantConversation(
    BuildContext context,
    String localConversationId,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _AiChatPage(
          launchRequest: AiChatLaunchRequest.resumeById(localConversationId),
        ),
      ),
    );
    if (mounted) {
      unawaited(widget.controller.load());
    }
  }
}

class _AssistantConversationSummaryCard extends StatelessWidget {
  const _AssistantConversationSummaryCard({
    required this.summary,
    required this.onTap,
  });

  final AssistantConversationSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final destination = summary.destination?.trim();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 102),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(232, 231, 231, 0.25),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F8F7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  summary.hasItinerary
                      ? Icons.route_outlined
                      : Icons.chat_bubble_outline_rounded,
                  size: 22,
                  color: const Color(0xFF18C777),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1C1C1E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (destination != null && destination.isNotEmpty)
                          destination,
                        '${summary.messageCount} 条消息',
                        if (summary.hasItinerary) '已有行程',
                      ].join(' / '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF999999),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatAssistantHistoryTime(summary.updatedAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFBBBBBB),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssistantHistoryLoading extends StatelessWidget {
  const _AssistantHistoryLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 40),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.2),
        ),
      ),
    );
  }
}

class _AssistantHistoryFailure extends StatelessWidget {
  const _AssistantHistoryFailure({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '历史会话读取失败，请稍后重试。',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF666666),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}

class _AssistantHistoryEmpty extends StatelessWidget {
  const _AssistantHistoryEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 54),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFE8FFF3),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 34,
                color: Color(0xFF18C777),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '还没有 AI 会话',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1C1C1E),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '从首页打开 AI 聊天，旅行规划会自动保存在这里。',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Color(0xFF999999),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatAssistantHistoryTime(DateTime time) {
  final now = DateTime.now();
  final diff = now.difference(time);
  if (diff.inMinutes < 1) return '刚刚';
  if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
  if (diff.inHours < 24) return '${diff.inHours}小时前';
  if (diff.inDays < 7) return '${diff.inDays}天前';
  return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}';
}

void _openPlanDetail(BuildContext context, TravelPlan plan) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    backgroundColor: Colors.transparent,
    builder: (context) => PlanDetailDrawer(plan: plan),
  );
}

class _HomeTopSection extends StatelessWidget {
  const _HomeTopSection();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 196,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(left: 0, right: 0, top: 0, child: _HomeHeader()),
          Positioned(left: 0, right: 0, top: 90, child: _PhotoStrip()),
          Positioned(left: 0, right: 0, top: 66, child: _AiDialogBar()),
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
          child: Icon(Icons.person, color: Colors.white),
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
                    '世纪公园',
                    style: TextStyle(fontSize: 11, color: Color(0xFF9D9D9D)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const _WeatherSummary(),
        const SizedBox(width: 10),
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

class _WeatherSummary extends StatefulWidget {
  const _WeatherSummary();

  @override
  State<_WeatherSummary> createState() => _WeatherSummaryState();
}

class _WeatherSummaryState extends State<_WeatherSummary> {
  WeatherData? _weather;
  bool _loading = true;

  // 濮掓稒顭堥濠氬春鎼达紕顏崇紓鍌涚墱閻栨粓鏁嶅顓犵劶闂傚啰顒茬槐娆撳矗椤栨碍韬悹浣稿⒔閻ゅ棙绋夐鐐茬€奸柟璇℃緛缁?
  static const String _defaultAdcode = '210100';

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    final data = await WeatherService.fetchWeather(_defaultAdcode);
    if (mounted) {
      setState(() {
        _weather = data;
        _loading = false;
      });
    }
  }

  void _openWeatherSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _WeatherSheetContent(city: _weather?.city ?? ''),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 12,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: Color(0xFFE0E0E0),
              shape: BoxShape.circle,
            ),
          ),
        ],
      );
    }

    final tempText = _weather?.temperatureRange ?? '21C-36C';
    final iconAsset = _weather?.weatherIconAsset ?? 'assets/icons/晴天.png';

    return GestureDetector(
      onTap: _openWeatherSheet,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tempText,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF8D8D8D),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 8),
          Image.asset(iconAsset, width: 30),
        ],
      ),
    );
  }
}

/// 濠㈠灈鏅滈惃鐢稿础婵犲倻娼岄柟鎯版閻粙鎯冮崟顐㈡暥閻庡湱娅㈢槐娆忣嚕閸屾侗鍔勯柛鏃傚Ь濞村洭宕畝鍕垫濠㈠灈鏅滈惃鐢稿极閻楀牆绁﹂柨?
class _WeatherSheetContent extends StatefulWidget {
  const _WeatherSheetContent({required this.city});
  final String city;

  @override
  State<_WeatherSheetContent> createState() => _WeatherSheetContentState();
}

class _WeatherSheetContentState extends State<_WeatherSheetContent> {
  QWeather7Day? _forecast;
  QWeatherNow? _now;
  String _cityName = '';
  String? _weatherError;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      debugPrint('QWeather sheet: loading for city "${widget.city}"');
      // 闁稿繐鐗婇幃鎶藉春鎼达紕顏抽柤鎯у槻瑜?locationId
      final city = await QWeatherService.searchCity(
        widget.city.isNotEmpty ? widget.city : 'Shenyang',
      );
      final locationId = city?.id ?? '101070101'; // 濮掓稒顭堥璇测柦閸儲歇
      debugPrint(
        'QWeather sheet: city name=${city?.name}, id=${city?.id}, fallback=$locationId',
      );

      final results = await Future.wait([
        QWeatherService.fetch7DayForecast(locationId),
        QWeatherService.fetchNow(locationId),
      ]);

      final forecast = results[0] as QWeather7Day?;
      final now = results[1] as QWeatherNow?;
      debugPrint(
        'QWeather sheet: forecast days=${forecast?.days.length}, now temp=${now?.temp}',
      );

      if (mounted) {
        setState(() {
          _forecast = forecast;
          _now = now;
          _cityName = city?.name ?? widget.city;
          _weatherError = forecast == null && now == null
              ? QWeatherService.lastError
              : null;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('QWeather sheet ERROR: $e');
      if (mounted) {
        setState(() {
          _weatherError = '$e';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        height: 340,
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
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return WeatherDrawer(
      forecast: _forecast,
      now: _now,
      cityName: _cityName,
      errorMessage: _weatherError,
    );
  }
}

class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_HomePhotoItem>>(
      future: _fetchCurrentHomePhotoStripItems(),
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState != ConnectionState.done;
        if (isLoading && !snapshot.hasData) {
          return _PhotoStripStack(photos: _fallbackHomePhotoItems);
        }

        final photos = snapshot.data ?? const [];
        return _PhotoStripStack(
          photos: photos.isEmpty ? _fallbackHomePhotoItems : photos,
        );
      },
    );
  }
}

class _PhotoStripLoading extends StatelessWidget {
  const _PhotoStripLoading();

  @override
  Widget build(BuildContext context) {
    return _PhotoStripStack(photos: _fallbackHomePhotoItems);
  }
}

class _PhotoStripStack extends StatelessWidget {
  const _PhotoStripStack({required this.photos});

  final List<_HomePhotoItem> photos;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final visiblePhotos = _photoStripVisibleItems(photos);
        const stripWidth = 306.0;
        const cardSize = 55.0;
        final scale = constraints.maxWidth < stripWidth
            ? constraints.maxWidth / stripWidth
            : 1.0;

        return SizedBox(
          height: 82,
          child: Align(
            alignment: Alignment.topCenter,
            child: Transform.scale(
              alignment: Alignment.topCenter,
              scale: scale,
              child: SizedBox(
                width: stripWidth,
                height: 66,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (var i = 0; i < visiblePhotos.length; i++)
                      Positioned(
                        left: visiblePhotos.length == 1
                            ? (stripWidth - cardSize) / 2
                            : i *
                                  ((stripWidth - cardSize) /
                                      (visiblePhotos.length - 1)),
                        bottom: 0,
                        child: _HomePhotoCard(
                          item: visiblePhotos[i],
                          width: cardSize,
                          height: cardSize,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

List<_HomePhotoItem> _photoStripVisibleItems(List<_HomePhotoItem> photos) {
  final visiblePhotos = photos.take(7).toList();
  for (final fallback in _fallbackHomePhotoItems) {
    if (visiblePhotos.length >= 7) break;
    visiblePhotos.add(fallback);
  }
  return visiblePhotos;
}

class _HomePhotoCard extends StatelessWidget {
  const _HomePhotoCard({
    required this.item,
    required this.width,
    required this.height,
  });

  final _HomePhotoItem item;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _showHomePhotoSpotSheet(context, item: item),
        child: Container(
          width: width,
          height: height,
          padding: const EdgeInsets.all(2),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1F000000),
                blurRadius: 9,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            clipBehavior: Clip.antiAlias,
            child: item.isNetwork
                ? Image.network(
                    item.image,
                    width: width - 4,
                    height: height - 4,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (_, _, _) => Image.asset(
                      item.fallbackImage,
                      width: width - 4,
                      height: height - 4,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                    ),
                  )
                : Image.asset(
                    item.image,
                    width: width - 4,
                    height: height - 4,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                  ),
          ),
        ),
      ),
    );
  }
}

class _AmapImageErrorPlaceholder extends StatelessWidget {
  const _AmapImageErrorPlaceholder({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFEAF1EC),
      child: Center(
        child: compact
            ? const Icon(
                Icons.cloud_off_outlined,
                size: 18,
                color: Color(0xFF8AA096),
              )
            : const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_off_outlined,
                    size: 30,
                    color: Color(0xFF8AA096),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Amap image failed to load',
                    style: TextStyle(
                      color: Color(0xFF7C8B85),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

void _showHomePhotoSpotSheet(
  BuildContext context, {
  required _HomePhotoItem item,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    backgroundColor: Colors.transparent,
    builder: (context) => _HomePhotoSpotSheet(item: item),
  );
}

class _HomePhotoSpotSheet extends StatefulWidget {
  const _HomePhotoSpotSheet({required this.item});

  final _HomePhotoItem item;

  @override
  State<_HomePhotoSpotSheet> createState() => _HomePhotoSpotSheetState();
}

class _HomePhotoSpotSheetState extends State<_HomePhotoSpotSheet> {
  late final DraggableScrollableController _controller;
  bool _isFullScreen = false;
  bool _isPromotingToPage = false;

  @override
  void initState() {
    super.initState();
    _controller = DraggableScrollableController()..addListener(_handleChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleChanged)
      ..dispose();
    super.dispose();
  }

  void _handleChanged() {
    if (_controller.size > .955 && !_isPromotingToPage) {
      _isPromotingToPage = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => _HomePhotoSpotFullPage(item: widget.item),
          ),
        );
      });
      return;
    }

    final next = _controller.size > .92;
    if (next != _isFullScreen) setState(() => _isFullScreen = next);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: _controller,
      initialChildSize: .62,
      minChildSize: .42,
      maxChildSize: 1,
      expand: false,
      snap: true,
      snapSizes: const [.62, 1],
      builder: (context, scrollController) {
        final topPadding = _isFullScreen
            ? MediaQuery.viewPaddingOf(context).top + 6.0
            : 14.0;
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
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x24000000),
                      blurRadius: 28,
                      offset: Offset(0, 14),
                    ),
                  ],
                ),
                child: _HomePhotoSpotContent(
                  item: widget.item,
                  controller: scrollController,
                  topPadding: topPadding,
                  showHandle: false,
                  showClose: _isFullScreen,
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

class _HomePhotoSpotFullPage extends StatelessWidget {
  const _HomePhotoSpotFullPage({required this.item});

  final _HomePhotoItem item;

  @override
  Widget build(BuildContext context) {
    return _SafeFullPageScaffold(
      backgroundColor: const Color(0xFFF7F8F7),
      onClose: () => Navigator.of(context).pop(),
      child: _HomePhotoSpotContent(
        item: item,
        showHandle: false,
        showClose: false,
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }
}

class _HomePhotoSpotContent extends StatelessWidget {
  const _HomePhotoSpotContent({
    required this.item,
    required this.showHandle,
    required this.showClose,
    required this.onClose,
    this.controller,
    this.topPadding,
  });

  final _HomePhotoItem item;
  final ScrollController? controller;
  final bool showHandle;
  final bool showClose;
  final VoidCallback onClose;
  final double? topPadding;

  @override
  Widget build(BuildContext context) {
    final poiFacts = _poiFactItems(item);
    final galleryUrls = _homePhotoGalleryUrls(item);
    // 闁告艾鐗嗛懟鐔搞亜閸洖鍔ュ鍫嗗啯绂堥柛婊冭嫰缁ㄦ娊鏌堥妸褏绱氶柣锝冨劚濞存﹢鏁嶇仦鍊熷煂闁瑰瓨鍔橀悿鍡涘箻椤撶偛鐏欓悶?
    final carouselUrls = [item.image, ...galleryUrls];
    return ListView(
      controller: controller,
      padding: EdgeInsets.fromLTRB(14, topPadding ?? 14, 14, 22),
      children: [
        _PhotoCarousel(
          urls: carouselUrls,
          height: 180,
          showClose: showClose,
          onClose: onClose,
        ),
        const SizedBox(height: 18),
        Text(
          item.spot.name,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Color(0xFF111111),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 15,
              color: Color(0xFF8C9490),
            ),
            const SizedBox(width: 4),
            Text(
              item.spot.city,
              style: const TextStyle(
                color: Color(0xFF7D8581),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final tag in item.spot.tags) _SpotTag(label: tag)],
        ),
        if (poiFacts.isNotEmpty) ...[
          const SizedBox(height: 14),
          _HomePhotoPoiFacts(facts: poiFacts),
        ],
        const SizedBox(height: 16),
        Text(
          _homePhotoSpotDescription(item),
          style: const TextStyle(
            color: Color(0xFF555E5A),
            fontSize: 14,
            height: 1.55,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        _HomePhotoSpotTip(tip: item.spot.tip),
      ],
    );
  }
}

class _PhotoCarousel extends StatefulWidget {
  const _PhotoCarousel({
    required this.urls,
    required this.height,
    this.showClose = false,
    this.onClose,
  });

  final List<String> urls;
  final double height;
  final bool showClose;
  final VoidCallback? onClose;

  @override
  State<_PhotoCarousel> createState() => _PhotoCarouselState();
}

class _PhotoCarouselState extends State<_PhotoCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.urls.length <= 1) {
      // 闁告瑯浜濆﹢浣圭▔閳ь剙顕ｉ悩鍙夌闁哄啫澧庡ú鍧楀箳閵夛附鈻旂紒鈧?
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: widget.height,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _CarouselImage(url: widget.urls.first),
              if (widget.showClose && widget.onClose != null)
                Positioned(
                  right: 12,
                  top: 12,
                  child: _HeroCloseButton(onPressed: widget.onClose!),
                ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            height: widget.height,
            width: double.infinity,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  onPageChanged: (page) => setState(() => _currentPage = page),
                  itemCount: widget.urls.length,
                  itemBuilder: (context, index) {
                    return _CarouselImage(url: widget.urls[index]);
                  },
                ),
                if (widget.showClose && widget.onClose != null)
                  Positioned(
                    right: 12,
                    top: 12,
                    child: _HeroCloseButton(onPressed: widget.onClose!),
                  ),
                // 濡炪倗鏁搁悥婊堝箰閸モ斂浠涢柛?
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 12,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      widget.urls.length,
                      (index) => Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentPage == index
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.45),
                        ),
                      ),
                    ),
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

class _CarouselImage extends StatelessWidget {
  const _CarouselImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, _, _) => const _AmapImageErrorPlaceholder(),
    );
  }
}

class _HomePhotoSpotHero extends StatelessWidget {
  const _HomePhotoSpotHero({required this.item, this.onClose});

  final _HomePhotoItem item;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 180,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              item.image,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, _, _) => const _AmapImageErrorPlaceholder(),
            ),
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

class _HomePhotoGallery extends StatelessWidget {
  const _HomePhotoGallery({required this.urls});

  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              urls[index],
              width: 78,
              height: 58,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, _, _) =>
                  const _AmapImageErrorPlaceholder(compact: true),
            ),
          );
        },
      ),
    );
  }
}

List<String> _homePhotoGalleryUrls(_HomePhotoItem item) {
  final urls = item.amapSpot?.photoUrls ?? const <String>[];
  if (urls.isEmpty) return [item.image];
  return urls.take(8).toList(growable: false);
}

class _HomePhotoSpotTip extends StatelessWidget {
  const _HomePhotoSpotTip({required this.tip});

  final String tip;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
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
            decoration: const BoxDecoration(
              color: Color(0xFFE8FFF3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.tips_and_updates_outlined,
              size: 17,
              color: Color(0xFF18C777),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(
                color: Color(0xFF5E6662),
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomePhotoPoiFacts extends StatelessWidget {
  const _HomePhotoPoiFacts({required this.facts});

  final List<_PoiFact> facts;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '高德 POI 信息',
            style: TextStyle(
              color: Color(0xFF151515),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < facts.length; i++) ...[
            _PoiFactRow(fact: facts[i]),
            if (i != facts.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, color: Color(0xFFEDEDED)),
              ),
          ],
        ],
      ),
    );
  }
}

class _PoiFactRow extends StatelessWidget {
  const _PoiFactRow({required this.fact});

  final _PoiFact fact;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(fact.icon, size: 18, color: const Color(0xFF19B96D)),
        const SizedBox(width: 10),
        SizedBox(
          width: 58,
          child: Text(
            fact.label,
            style: const TextStyle(
              color: Color(0xFF8A8F8C),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            fact.value,
            style: const TextStyle(
              color: Color(0xFF343A37),
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _PoiFact {
  const _PoiFact({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

List<_PoiFact> _poiFactItems(_HomePhotoItem item) {
  final amapFacts = _amapPoiFactItems(item.amapSpot);
  if (amapFacts.isNotEmpty) return amapFacts;

  return [
    _PoiFact(icon: Icons.info_outline, label: '来源', value: '高德 POI'),
    _PoiFact(
      icon: Icons.location_city_outlined,
      label: '区域',
      value: item.spot.city,
    ),
    if (item.spot.tags.isNotEmpty)
      _PoiFact(
        icon: Icons.local_offer_outlined,
        label: '标签',
        value: item.spot.tags.join(' / '),
      ),
  ];
}

List<_PoiFact> _amapPoiFactItems(AmapPhotoSpot? spot) {
  if (spot == null) return const [];

  final facts = <_PoiFact>[
    if (spot.rating.isNotEmpty)
      _PoiFact(icon: Icons.star_rounded, label: '评分', value: spot.rating),
    if (spot.openTime.isNotEmpty)
      _PoiFact(
        icon: Icons.access_time_rounded,
        label: '开放',
        value: spot.openTime,
      ),
    if (spot.cost.isNotEmpty)
      _PoiFact(
        icon: Icons.confirmation_number_outlined,
        label: '费用',
        value: spot.cost,
      ),
    if (spot.tel.isNotEmpty)
      _PoiFact(icon: Icons.phone_outlined, label: '电话', value: spot.tel),
    if (spot.businessArea.isNotEmpty)
      _PoiFact(
        icon: Icons.storefront_outlined,
        label: '区域',
        value: spot.businessArea,
      ),
    if (spot.address.isNotEmpty)
      _PoiFact(icon: Icons.place_outlined, label: '地址', value: spot.address),
    if (spot.website.isNotEmpty)
      _PoiFact(icon: Icons.public_outlined, label: '网站', value: spot.website),
    if (spot.location.isNotEmpty)
      _PoiFact(
        icon: Icons.gps_fixed_outlined,
        label: '坐标',
        value: spot.location,
      ),
    if (spot.photoUrls.length > 1)
      _PoiFact(
        icon: Icons.photo_library_outlined,
        label: '图片',
        value: '${spot.photoUrls.length} 张',
      ),
  ];

  return facts.take(8).toList(growable: false);
}

String _homePhotoSpotDescription(_HomePhotoItem item) {
  final spot = item.amapSpot;
  if (spot == null) {
    return '${item.spot.name}\u5f53\u524d\u5c55\u793a\u672c\u5730\u515c\u5e95\u5185\u5bb9\u3002${item.spot.description}';
  }

  final address = spot.address.isEmpty ? spot.city : spot.address;
  final parts = <String>[
    '${spot.name}\u4f4d\u4e8e$address\u3002',
    if (spot.category.isNotEmpty)
      '\u9ad8\u5fb7\u5206\u7c7b\u4e3a${spot.category}\u3002',
    if (spot.rating.isNotEmpty)
      '\u5f53\u524d POI \u8bc4\u5206\u4e3a${spot.rating}\u3002',
    if (spot.openTime.isNotEmpty)
      '\u5f00\u653e\u65f6\u95f4\u4e3a${spot.openTime}\u3002',
  ];
  parts.add('\u8fd9\u4e9b\u4fe1\u606f\u6765\u81ea\u9ad8\u5fb7 POI\u3002');
  return parts.join();
}

String _compactAmapTag(String value) {
  final parts = value.split(';').where((item) => item.trim().isNotEmpty);
  final last = parts.isEmpty ? value : parts.last;
  return last.replaceAll('\u76f8\u5173\u5730\u70b9', '').trim();
}

class _SheetTopGrip extends StatelessWidget {
  const _SheetTopGrip();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: -12,
      left: 0,
      right: 0,
      child: Center(child: _SheetDragHandle()),
    );
  }
}

class _SheetDragHandle extends StatelessWidget {
  const _SheetDragHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
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
    );
  }
}

class _SafeFullPageScaffold extends StatelessWidget {
  const _SafeFullPageScaffold({
    required this.child,
    this.backgroundColor = const Color(0xFFF7F8F7),
    this.onClose,
  });

  final Widget child;
  final Color backgroundColor;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(child: child),
            if (onClose != null)
              Positioned(
                right: 18,
                top: 18,
                child: _HeroCloseButton(onPressed: onClose!),
              ),
          ],
        ),
      ),
    );
  }
}

class _HeroCloseButton extends StatelessWidget {
  const _HeroCloseButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111111),
      ),
      icon: const Icon(Icons.close_rounded, size: 20),
    );
  }
}

class _SpotTag extends StatelessWidget {
  const _SpotTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFEAFBF2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF19B96D),
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

double _photoTop(int index) {
  const tops = [8.0, 1.0, 5.0, 0.0, 7.0, 3.0];
  return tops[index % tops.length];
}

double _photoAngle(int index) {
  const angles = [-0.08, 0.05, -0.04, 0.06, -0.05, 0.04];
  return angles[index % angles.length];
}

class _PlanFilters extends StatelessWidget {
  const _PlanFilters({required this.activeTab, required this.onTabChanged});

  final int activeTab;
  final ValueChanged<int> onTabChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => onTabChanged(0),
          child: Text(
            '我的计划',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: activeTab == 0
                  ? const Color(0xFF1C1C1E)
                  : const Color(0xFF9C9C9C),
            ),
          ),
        ),
        const SizedBox(width: 28),
        GestureDetector(
          onTap: () => onTabChanged(1),
          child: Text(
            '探索',
            style: TextStyle(
              fontSize: 15,
              color: activeTab == 1
                  ? const Color(0xFF1C1C1E)
                  : const Color(0xFF9C9C9C),
              fontWeight: activeTab == 1 ? FontWeight.w900 : FontWeight.w400,
            ),
          ),
        ),
        const Spacer(),
        const Text(
          '全部计划',
          style: TextStyle(fontSize: 11, color: Color(0xFF9C9C9C)),
        ),
        const Icon(
          Icons.keyboard_arrow_down,
          size: 18,
          color: Color(0xFF9C9C9C),
        ),
        const SizedBox(width: 8),
        const Text(
          '状态',
          style: TextStyle(fontSize: 11, color: Color(0xFF9C9C9C)),
        ),
        const Icon(
          Icons.keyboard_arrow_down,
          size: 18,
          color: Color(0xFF9C9C9C),
        ),
      ],
    );
  }
}

class PlanCard extends StatelessWidget {
  const PlanCard({super.key, required this.plan, this.onTap});

  final TravelPlan plan;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          constraints: const BoxConstraints(minHeight: 134),
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(232, 231, 231, 0.38),
                blurRadius: 12,
                offset: Offset(0, 5),
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
                        _Metric(
                          icon: Icons.map_outlined,
                          value: '${plan.places}',
                        ),
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
        ),
      ),
    );
  }
}

const _fallbackHomePhotos = [
  'assets/images/photo-1.png',
  'assets/images/photo-2.png',
  'assets/images/photo-3.png',
  'assets/images/photo-4.png',
  'assets/images/photo-5.png',
  'assets/images/photo-6.png',
  'assets/images/photo-7.png',
  'assets/images/photo-sichuan.png',
];

List<_HomePhotoItem> get _fallbackHomePhotoItems {
  return List<_HomePhotoItem>.generate(
    _fallbackHomePhotos.length,
    (index) => _HomePhotoItem(
      image: _fallbackHomePhotos[index],
      fallbackImage: _fallbackHomePhotos[index],
      spot: _homePhotoSpots[index % _homePhotoSpots.length],
      isNetwork: false,
    ),
    growable: false,
  );
}

const _homePhotoSpots = [
  _HomePhotoSpot(
    name: '世纪公园',
    city: '上海 / 浦东',
    tags: ['公园', '散步', '亲子'],
    description: '适合散步、休闲和拍照的城市公园。',
    tip: '出发前建议确认交通和开放时间。',
  ),
  _HomePhotoSpot(
    name: '外滩',
    city: '上海 / 黄浦',
    tags: ['夜景', '建筑', '地标'],
    description: '经典城市天际线观景点。',
    tip: '傍晚到夜间通常更适合拍照。',
  ),
  _HomePhotoSpot(
    name: '陆家嘴',
    city: '上海 / 浦东',
    tags: ['观景', '拍照', '商圈'],
    description: '高楼地标密集，也适合沿江步行。',
    tip: '可以和外滩安排在同一条路线里。',
  ),
  _HomePhotoSpot(
    name: '东方明珠',
    city: '上海 / 浦东',
    tags: ['观景台', '亲子', '夜景'],
    description: '代表性的上海地标，适合高处观景。',
    tip: '热门时段建议提前预约。',
  ),
  _HomePhotoSpot(
    name: '豫园',
    city: '上海 / 黄浦',
    tags: ['园林', '老城', '美食'],
    description: '适合体验园林景致和老城氛围。',
    tip: '周末高峰建议错峰前往。',
  ),
  _HomePhotoSpot(
    name: '朱家角',
    city: '上海 / 青浦',
    tags: ['古镇', '水乡', '慢游'],
    description: '适合半日或一日慢游的水乡古镇。',
    tip: '可以和青浦周边景点组合安排。',
  ),
];

class _HomePhotoSpot {
  const _HomePhotoSpot({
    required this.name,
    required this.city,
    required this.tags,
    required this.description,
    required this.tip,
  });

  final String name;
  final String city;
  final List<String> tags;
  final String description;
  final String tip;
}

class _HomePhotoItem {
  const _HomePhotoItem({
    required this.image,
    required this.fallbackImage,
    required this.spot,
    required this.isNetwork,
    this.amapSpot,
  });

  final String image;
  final String fallbackImage;
  final _HomePhotoSpot spot;
  final bool isNetwork;
  final AmapPhotoSpot? amapSpot;
}

Future<List<_HomePhotoItem>> _fetchHomePhotoStripItems() async {
  const city = '上海';
  final spots = await fetchAmapPhotoSpots(
    keyword: '景点',
    city: city,
    types: '110000',
  );
  final results = spots.isNotEmpty
      ? spots
      : (await Future.wait(
          const ['外滩', '东方明珠', '陆家嘴', '世纪公园', '苏州河', '武康路'].map(
            (keyword) => fetchAmapPhotoSpots(
              keyword: keyword,
              city: city,
              types: '110000',
            ),
          ),
        )).expand((s) => s).toList(growable: false);
  final fallbackItems = _fallbackHomePhotoItems;
  if (results.isEmpty) return fallbackItems;
  return results
      .take(8)
      .indexed
      .map((entry) {
        final index = entry.$1;
        final spot = entry.$2;
        final fallback = fallbackItems[index % fallbackItems.length];
        return _HomePhotoItem(
          image: spot.photoUrl,
          fallbackImage: fallback.fallbackImage,
          spot: _homePhotoSpotFromAmap(spot),
          isNetwork: true,
          amapSpot: spot,
        );
      })
      .toList(growable: false);
}

Future<List<_HomePhotoItem>> _fetchCurrentHomePhotoStripItems() async {
  const scenicTypes = '110000';
  final currentLocation = await _fetchCurrentDeviceLocation();
  if (currentLocation == null) {
    return _fetchHomePhotoStripItems();
  }

  final spots = await fetchAmapPhotoSpotsAround(
    longitude: currentLocation.longitude,
    latitude: currentLocation.latitude,
    keyword: '景点',
    types: scenicTypes,
  );
  if (spots.isEmpty) {
    return _fetchHomePhotoStripItems();
  }

  final fallbackItems = _fallbackHomePhotoItems;
  return spots
      .take(8)
      .indexed
      .map((entry) {
        final index = entry.$1;
        final spot = entry.$2;
        final fallback = fallbackItems[index % fallbackItems.length];
        return _HomePhotoItem(
          image: spot.photoUrl,
          fallbackImage: fallback.fallbackImage,
          spot: _homePhotoSpotFromAmap(spot),
          isNetwork: true,
          amapSpot: spot,
        );
      })
      .toList(growable: false);
}

Future<_DeviceLocation?> _fetchCurrentDeviceLocation() async {
  try {
    final result = await const MethodChannel(
      'goplan/location',
    ).invokeMapMethod<String, Object?>('getCurrentLocation');
    final latitude = _readDouble(result?['latitude']);
    final longitude = _readDouble(result?['longitude']);
    if (latitude == null || longitude == null) return null;
    return _DeviceLocation(latitude: latitude, longitude: longitude);
  } catch (e) {
    debugPrint('Current location unavailable: $e');
    return null;
  }
}

double? _readDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

class _DeviceLocation {
  const _DeviceLocation({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

_HomePhotoSpot _homePhotoSpotFromAmap(AmapPhotoSpot spot) {
  final address = spot.address.isEmpty ? spot.city : spot.address;
  final tags = spot.tags
      .map(_compactAmapTag)
      .where((tag) => tag.isNotEmpty)
      .take(3)
      .toList(growable: false);
  return _HomePhotoSpot(
    name: spot.name,
    city: spot.city,
    tags: tags.isEmpty ? const ['旅行灵感'] : tags,
    description:
        '${spot.name}位于${address.isEmpty ? spot.city : address}，可加入城市探索路线。',
    tip: '图片、名称和位置来自高德 POI。出发前建议确认交通和开放时间。',
  );
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ai_travel_agent.dart';
import 'models/ai_conversation.dart';
import 'services/conversation_service.dart';
import 'services/weather_service.dart';
import 'services/qweather_service.dart';
import 'widgets/weather_sheet.dart';
import 'amap_photo_service_stub.dart'
    if (dart.library.io) 'amap_photo_service_io.dart';
import 'amap_web_view_stub.dart'
    if (dart.library.html) 'amap_web_view_web.dart';

const bool _useMockMapPreview = true;
const String _planCoverAssetFallback =
    'assets/images/4b5386239b0a7bb499c00d0c03fa39d4.webp';

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
        fontFamily: defaultTargetPlatform == TargetPlatform.iOS
            ? '.SF Pro Text'
            : null,
      ),
      builder: (context, child) => _ResponsiveAppFrame(child: child),
      home: const GoPlanShell(),
    );
  }
}

class _ResponsiveAppFrame extends StatelessWidget {
  const _ResponsiveAppFrame({required this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final content = child ?? const SizedBox.shrink();
    if (!kIsWeb || size.width < 760) return content;

    final previewWidth = size.width >= 1180 ? 430.0 : 390.0;
    final previewHeight = (size.height - 56).clamp(680.0, 860.0);

    return ColoredBox(
      color: const Color(0xFFEFF4F1),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Row(
            children: [
              if (size.width >= 1040)
                const Expanded(child: _WebIntroPanel())
              else
                const SizedBox(width: 24),
              SizedBox(
                width: previewWidth,
                height: previewHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F6F6),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .16),
                        blurRadius: 34,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        size: Size(previewWidth, previewHeight),
                        padding: EdgeInsets.zero,
                        viewPadding: EdgeInsets.zero,
                      ),
                      child: content,
                    ),
                  ),
                ),
              ),
              if (size.width >= 1040) const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _WebIntroPanel extends StatelessWidget {
  const _WebIntroPanel();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 36, right: 56),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset('assets/images/GoPlan.png', width: 156),
          const SizedBox(height: 34),
          const Text(
            '用 AI 把旅行想法\n整理成可执行计划',
            style: TextStyle(
              fontSize: 44,
              height: 1.12,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Web 端用于快速预览和调试，后续同一套 Flutter 代码仍可继续打包 Android / iOS。',
            style: TextStyle(
              fontSize: 17,
              height: 1.55,
              color: Color(0xFF5E6864),
            ),
          ),
          const SizedBox(height: 28),
          const Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _WebFeaturePill(label: 'AI 对话'),
              _WebFeaturePill(label: '旅行计划'),
              _WebFeaturePill(label: 'Mock 地图'),
              _WebFeaturePill(label: '跨端打包'),
            ],
          ),
        ],
      ),
    );
  }
}

class _WebFeaturePill extends StatelessWidget {
  const _WebFeaturePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFDDE6E2)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        child: Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        ),
      ),
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

  void _openCreatePlan() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const _AiChatPage()));
  }

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
              onCreatePlan: _openCreatePlan,
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
    final showLegacyLoadingArtwork = false;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/background.png', fit: BoxFit.cover),
          if (showLegacyLoadingArtwork) ...[
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
          ],
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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _showExplore = false;

  @override
  void initState() {
    super.initState();
    ConversationService.instance.addListener(_onConversationsChanged);
  }

  @override
  void dispose() {
    ConversationService.instance.removeListener(_onConversationsChanged);
    super.dispose();
  }

  void _onConversationsChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final conversations = ConversationService.instance.conversations;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 112),
        children: [
          const _HomeTopSection(),
          _PlanFilters(
            activeTab: _showExplore ? 1 : 0,
            onTabChanged: (index) => setState(() => _showExplore = index == 1),
          ),
          const SizedBox(height: 12),
          if (_showExplore)
            ..._buildExploreContent(conversations)
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

  List<Widget> _buildExploreContent(List<AiConversation> conversations) {
    if (conversations.isEmpty) {
      return const [_ExploreEmptyState()];
    }
    final widgets = <Widget>[];
    var lastWasPinned = false;
    for (final conv in conversations) {
      // 置顶与非置顶之间插入分隔
      if (!conv.isPinned && lastWasPinned) {
        widgets.add(const SizedBox(height: 4));
        widgets.add(
          const Padding(
            padding: EdgeInsets.only(bottom: 14),
            child: Text(
              '历史对话',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFFBBBBBB),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      }
      lastWasPinned = conv.isPinned;
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _ConversationCard(conversation: conv),
        ),
      );
    }
    return widgets;
  }
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
          Positioned(left: 0, right: 0, top: 88, child: _PhotoStrip()),
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
                    '世纪大厦',
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

  // 默认城市编码：沈阳（可在设置中切换）
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

    final tempText = _weather?.temperatureRange ?? '21℃~36℃';
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

/// 天气半屏抽屉的内容（异步加载和风天气数据）
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
      // 先搜城市获取 locationId
      final city = await QWeatherService.searchCity(
        widget.city.isNotEmpty ? widget.city : '沈阳',
      );
      final locationId = city?.id ?? '101070101'; // 默认沈阳
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

class _AiDialogBar extends StatelessWidget {
  const _AiDialogBar();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _openAiChat(context),
        child: Container(
          height: 46,
          padding: const EdgeInsets.only(left: 12, right: 13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x18000000),
                blurRadius: 22,
                offset: Offset(0, 10),
              ),
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Image.asset('assets/images/ai.png', width: 38, height: 38),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  '聊聊你的旅行想法',
                  style: TextStyle(color: Color(0xFF8F8F8F), fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              Container(width: 1, height: 22, color: const Color(0xFFE7E7E7)),
              const SizedBox(width: 10),
              const Icon(
                Icons.keyboard_voice_outlined,
                color: Color(0xFF4C4C4C),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openAiChat(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const _AiChatPage()));
  }
}

class _AiChatPage extends StatefulWidget {
  const _AiChatPage();

  @override
  State<_AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<_AiChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AiTravelAgent _agent = createAiTravelAgent();
  final List<_AiChatMessage> _messages = [];
  final List<AiTravelAgentTurn> _agentHistory = [];
  bool _isThinking = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _controller.text).trim();
    if (text.isEmpty || _isThinking) return;

    setState(() {
      _controller.clear();
      _messages.add(_AiChatMessage(role: _AiChatRole.user, text: text));
      _isThinking = true;
    });
    _scrollToBottom();

    try {
      final history = List<AiTravelAgentTurn>.of(_agentHistory);
      final reply = await _agent.planTrip(text, history: history);
      if (!mounted) return;
      final assistantText = reply.replyText;
      setState(() {
        _messages.add(
          _AiChatMessage(
            role: _AiChatRole.assistant,
            text: assistantText,
            plan: reply.plan,
            requestStartDate: reply.requestStartDate,
          ),
        );
        _agentHistory
          ..add(AiTravelAgentTurn(role: AiTravelAgentRole.user, content: text))
          ..add(
            AiTravelAgentTurn(
              role: AiTravelAgentRole.assistant,
              content: assistantText,
            ),
          );
        _isThinking = false;
      });
      // 保存对话到探索页
      ConversationService.instance.addConversation(
        userQuery: text,
        messages: [
          ConvMessage(role: 'user', content: text),
          ConvMessage(role: 'assistant', content: assistantText),
        ],
        result: reply.plan,
      );
    } on AiTravelAgentException catch (error) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          _AiChatMessage(role: _AiChatRole.assistant, text: error.message),
        );
        _isThinking = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          _AiChatMessage(role: _AiChatRole.assistant, text: 'AI 规划失败：$error'),
        );
        _isThinking = false;
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F7),
      body: SafeArea(
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Column(
            children: [
              const _AiChatHeader(),
              const _AiChatModeDivider(label: '真实 AI 旅行路线规划'),
              Expanded(
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 14),
                  children: [
                    if (_messages.isEmpty && !_isThinking)
                      _AiChatEmptyState(onPromptSelected: _send),
                    for (final message in _messages)
                      _AiMessageBubble(
                        message: message,
                        onStartDateSelected: (date) =>
                            _send(_formatStartDateMessage(date)),
                      ),
                    if (_isThinking) const _AiThinkingBubble(),
                  ],
                ),
              ),
              _AiChatInput(
                controller: _controller,
                enabled: !_isThinking,
                onSend: _send,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AiChatHeader extends StatelessWidget {
  const _AiChatHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 66,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded, size: 24),
              color: const Color(0xFF202326),
            ),
            const SizedBox(width: 4),
            const Expanded(
              child: Text(
                'GoPlan AI 旅行规划',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF151515),
                ),
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.edit_outlined, size: 22),
              color: const Color(0xFF202326),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.more_vert_rounded, size: 23),
              color: const Color(0xFF202326),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiChatModeDivider extends StatelessWidget {
  const _AiChatModeDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Color(0xFFE4E4E4))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFFB3B3B3),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Expanded(child: Divider(color: Color(0xFFE4E4E4))),
        ],
      ),
    );
  }
}

class _AiChatEmptyState extends StatelessWidget {
  const _AiChatEmptyState({required this.onPromptSelected});

  final ValueChanged<String> onPromptSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 18),
      child: Column(
        children: [
          const _AiOrb(size: 46),
          const SizedBox(height: 18),
          const Text(
            '告诉我你的旅行想法',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF151515),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '我会调用真实 AI Agent，生成可执行的每日路线、交通、美食和注意事项。',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: Color(0xFF858B8D),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              _AiPromptChip(
                text: '川西雪山 6 天',
                onTap: () => onPromptSelected('从成都出发，帮我规划川西雪山小环线 6 天，节奏舒适。'),
              ),
              _AiPromptChip(
                text: '杭州周末情侣游',
                onTap: () => onPromptSelected('帮我规划杭州 2 天情侣周末游，想要西湖、咖啡和轻松拍照。'),
              ),
              _AiPromptChip(
                text: '云南毕业旅行',
                onTap: () => onPromptSelected('帮我规划云南 8 天毕业旅行，4 个人，喜欢美食和自然风景。'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AiPromptChip extends StatelessWidget {
  const _AiPromptChip({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF343738),
            ),
          ),
        ),
      ),
    );
  }
}

class _AiMessageBubble extends StatelessWidget {
  const _AiMessageBubble({
    required this.message,
    required this.onStartDateSelected,
  });

  final _AiChatMessage message;
  final ValueChanged<DateTime> onStartDateSelected;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == _AiChatRole.user;
    final bubble = message.plan == null
        ? _AiTextBubble(message: message)
        : _AiPlanBubble(plan: message.plan!);

    if (isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: bubble,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AiOrb(size: 20),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                bubble,
                if (message.requestStartDate) ...[
                  const SizedBox(height: 10),
                  _AiStartDatePickerCard(onSelected: onStartDateSelected),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AiStartDatePickerCard extends StatelessWidget {
  const _AiStartDatePickerCard({required this.onSelected});

  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * .78,
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF18C777),
            primary: const Color(0xFF18C777),
          ),
        ),
        child: CalendarDatePicker(
          initialDate: today,
          firstDate: today,
          lastDate: DateTime(today.year + 2, today.month, today.day),
          onDateChanged: onSelected,
        ),
      ),
    );
  }
}

class _AiTextBubble extends StatelessWidget {
  const _AiTextBubble({required this.message});

  final _AiChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == _AiChatRole.user;
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * .7,
      ),
      padding: isUser
          ? const EdgeInsets.symmetric(horizontal: 15, vertical: 12)
          : EdgeInsets.zero,
      decoration: isUser
          ? BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(13),
            )
          : null,
      child: Text(
        message.text,
        style: TextStyle(
          color: isUser ? Colors.white : const Color(0xFF202426),
          fontSize: 14,
          height: 1.42,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AiPlanBubble extends StatelessWidget {
  const _AiPlanBubble({required this.plan});

  final TravelAgentResult plan;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * .74,
      ),
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${plan.destination} · ${plan.durationDays} 天',
            style: const TextStyle(
              color: Color(0xFF151515),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            plan.summary,
            style: const TextStyle(
              color: Color(0xFF5F6669),
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          for (final day in plan.days)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AiPlanDayRow(day: day),
            ),
        ],
      ),
    );
  }
}

class _AiPlanDayRow extends StatelessWidget {
  const _AiPlanDayRow({required this.day});

  final TravelAgentDay day;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8F7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'D${day.day} ${day.title}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: Color(0xFF202426),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              day.route,
              style: const TextStyle(
                fontSize: 12,
                height: 1.35,
                color: Color(0xFF636B6E),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              day.transport,
              style: const TextStyle(
                fontSize: 11,
                height: 1.35,
                color: Color(0xFF8A9294),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiThinkingBubble extends StatelessWidget {
  const _AiThinkingBubble();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          const _AiOrb(size: 20),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: const Text(
              'AI 正在整理  •••',
              style: TextStyle(fontSize: 14, color: Color(0xFF8A8F91)),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiChatInput extends StatelessWidget {
  const _AiChatInput({
    required this.controller,
    required this.enabled,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(27),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.attach_file_rounded, size: 20),
              color: const Color(0xFF4A4D50),
            ),
            Container(width: 1, height: 24, color: const Color(0xFFE8E8E8)),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                enabled: enabled,
                controller: controller,
                minLines: 1,
                maxLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: '问我任何旅行问题...',
                  hintStyle: TextStyle(
                    color: Color(0xFF9B9FA1),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: enabled ? onSend : null,
              icon: const Icon(Icons.keyboard_voice_outlined, size: 21),
              color: const Color(0xFF4A4D50),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiOrb extends StatelessWidget {
  const _AiOrb({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: Alignment(-.35, -.35),
          radius: .9,
          colors: [Color(0xFFE7FFF0), Color(0xFF6DE58E), Color(0xFF17B95A)],
          stops: [0, .48, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x3317B95A),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
    );
  }
}

enum _AiChatRole { user, assistant }

class _AiChatMessage {
  const _AiChatMessage({
    required this.role,
    required this.text,
    this.plan,
    this.requestStartDate = false,
  });

  final _AiChatRole role;
  final String text;
  final TravelAgentResult? plan;
  final bool requestStartDate;
}

String _formatStartDateMessage(DateTime date) {
  return '出发日期：${date.year}年${date.month}月${date.day}日。';
}

class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_HomePhotoItem>>(
      future: _fetchHomePhotoStripItems(),
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState != ConnectionState.done;
        if (isLoading && !snapshot.hasData) {
          return const _PhotoStripLoading();
        }

        final photos = snapshot.data ?? const [];
        if (photos.isEmpty) {
          return const SizedBox(height: 92);
        }
        return _PhotoStripStack(photos: photos);
      },
    );
  }
}

class _PhotoStripLoading extends StatelessWidget {
  const _PhotoStripLoading();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const count = 6;
        const cardWidth = 60.0;
        const cardHeight = 58.0;
        const step = 50.0;
        const totalWidth = cardWidth + step * (count - 1);
        final leftBase = ((constraints.maxWidth - totalWidth) / 2).clamp(
          10.0,
          28.0,
        );

        return SizedBox(
          height: 92,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (var i = 0; i < count; i++)
                Positioned(
                  left: leftBase + i * step,
                  top: _photoTop(i),
                  child: Transform.rotate(
                    angle: _photoAngle(i),
                    child: Container(
                      width: cardWidth,
                      height: cardHeight,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(13),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x18000000),
                            blurRadius: 12,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDEDED),
                          borderRadius: BorderRadius.circular(11),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _PhotoStripStack extends StatelessWidget {
  const _PhotoStripStack({required this.photos});

  final List<_HomePhotoItem> photos;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final visiblePhotos = photos.take(6).toList(growable: false);
        const cardWidth = 60.0;
        const step = 50.0;
        final totalWidth = cardWidth + step * (visiblePhotos.length - 1);
        final leftBase = ((constraints.maxWidth - totalWidth) / 2).clamp(
          10.0,
          28.0,
        );

        return SizedBox(
          height: 92,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (var i = 0; i < visiblePhotos.length; i++)
                Positioned(
                  left: leftBase + i * step,
                  top: _photoTop(i),
                  child: Transform.rotate(
                    angle: _photoAngle(i),
                    child: _HomePhotoCard(item: visiblePhotos[i]),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _HomePhotoCard extends StatelessWidget {
  const _HomePhotoCard({required this.item});

  final _HomePhotoItem item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: () => _showHomePhotoSpotSheet(context, item: item),
        child: Container(
          width: 60,
          height: 58,
          padding: const EdgeInsets.all(2),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(13),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 12,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            clipBehavior: Clip.antiAlias,
            child: Image.network(
              item.image,
              width: 60,
              height: 54,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, _, _) =>
                  const _AmapImageErrorPlaceholder(compact: true),
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
                    '高德图片加载失败',
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
    // 合并顶部大图和底部缩略图，形成轮播列表
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
      // 只有一张图时直接显示
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
                // 页码指示器
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
        label: '鏍囩',
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
        label: '价格',
        value: spot.cost,
      ),
    if (spot.tel.isNotEmpty)
      _PoiFact(icon: Icons.phone_outlined, label: '电话', value: spot.tel),
    if (spot.businessArea.isNotEmpty)
      _PoiFact(
        icon: Icons.storefront_outlined,
        label: '商圈',
        value: spot.businessArea,
      ),
    if (spot.address.isNotEmpty)
      _PoiFact(icon: Icons.place_outlined, label: '地址', value: spot.address),
    if (spot.website.isNotEmpty)
      _PoiFact(icon: Icons.public_outlined, label: '官网', value: spot.website),
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
    city: '上海 · 浦东新区',
    tags: ['城市绿地', '散步', '亲子'],
    description: '适合城市漫步和轻松拍照的绿地景点。',
    tip: '建议结合交通和开放时间安排。',
  ),
  _HomePhotoSpot(
    name: '外滩',
    city: '上海 · 黄浦区',
    tags: ['夜景', '建筑', '地标'],
    description: '适合观看黄浦江两岸天际线的经典景点。',
    tip: '傍晚到夜间体验更好。',
  ),
  _HomePhotoSpot(
    name: '陆家嘴',
    city: '上海 · 浦东新区',
    tags: ['观景', '拍照', '商圈'],
    description: '高层地标集中，适合城市观景和滨江漫步。',
    tip: '可与外滩串联成一条路线。',
  ),
  _HomePhotoSpot(
    name: '东方明珠',
    city: '上海 · 浦东新区',
    tags: ['观景台', '亲子', '夜景'],
    description: '上海代表性城市地标，适合登高观景。',
    tip: '建议提前预约。',
  ),
  _HomePhotoSpot(
    name: '豫园',
    city: '上海 · 黄浦区',
    tags: ['园林', '老城厢', '美食'],
    description: '适合体验江南园林和上海老城厢氛围。',
    tip: '周末人流较多，建议错峰。',
  ),
  _HomePhotoSpot(
    name: '朱家角',
    city: '上海 · 青浦区',
    tags: ['古镇', '水乡', '慢游'],
    description: '适合安排半天到一天的水乡古镇行程。',
    tip: '可与青浦周边景点一起安排。',
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
  // 如果没有结果，用热门景点作为关键词回退
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
  return results
      .take(6)
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
        '${spot.name}位于${address.isEmpty ? spot.city : address}，是高德 POI 推荐的旅行地点。这里适合加入城市探索路线，作为拍照、散步或短暂停留的节点。',
    tip: '图片、名称和位置均来自高德 POI。建议结合附近交通与开放时间，把它安排在同区域行程中，减少折返。',
  );
}

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

class _ExploreEmptyState extends StatelessWidget {
  const _ExploreEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
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
            '还没有AI对话记录',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1C1C1E),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '在首页点击AI对话框，\n生成旅行计划后会自动保存到这里',
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
    );
  }
}

class _ConversationCard extends StatefulWidget {
  const _ConversationCard({required this.conversation});

  final AiConversation conversation;

  @override
  State<_ConversationCard> createState() => _ConversationCardState();
}

class _ConversationCardState extends State<_ConversationCard>
    with SingleTickerProviderStateMixin {
  static const double _actionWidth = 160;
  double _offset = 0;
  late final AnimationController _ac;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _anim = _ac.drive(Tween<double>(begin: 0, end: 1));
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  void _animateTo(double target) {
    _anim.removeListener(_onAnimTick);
    _ac.reset();
    _anim = _ac.drive(Tween<double>(begin: _offset, end: target));
    _anim.addListener(_onAnimTick);
    _ac.forward();
  }

  void _onAnimTick() {
    setState(() => _offset = _anim.value);
  }

  void _close() => _animateTo(0);

  @override
  Widget build(BuildContext context) {
    final conv = widget.conversation;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 102,
        child: Stack(
          children: [
            // 背景操作按钮
            Positioned.fill(
              child: Row(
                children: [
                  const Spacer(),
                  // 置顶按钮
                  GestureDetector(
                    onTap: () {
                      ConversationService.instance.togglePinConversation(
                        conv.id,
                      );
                      _close();
                    },
                    child: Container(
                      width: _actionWidth / 2,
                      color: const Color(0xFFEDF5F0),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            conv.isPinned
                                ? Icons.push_pin_rounded
                                : Icons.push_pin_outlined,
                            color: const Color(0xFF18C777),
                            size: 22,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            conv.isPinned ? '取消' : '置顶',
                            style: const TextStyle(
                              color: Color(0xFF18C777),
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // 删除按钮
                  GestureDetector(
                    onTap: () {
                      ConversationService.instance.removeConversation(conv.id);
                    },
                    child: Container(
                      width: _actionWidth / 2,
                      color: const Color(0xFFF5EFEF),
                      alignment: Alignment.center,
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.delete_outline,
                            color: Color(0xFFC4A0A0),
                            size: 22,
                          ),
                          SizedBox(height: 4),
                          Text(
                            '删除',
                            style: TextStyle(
                              color: Color(0xFFC4A0A0),
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 卡片层
            GestureDetector(
              onHorizontalDragUpdate: (d) {
                setState(() {
                  _offset = (_offset + d.delta.dx).clamp(-_actionWidth, 0.0);
                });
              },
              onHorizontalDragEnd: (d) {
                if (_offset < -_actionWidth * .35) {
                  _animateTo(-_actionWidth);
                } else {
                  _animateTo(0);
                }
              },
              child: AnimatedContainer(
                duration: _ac.isAnimating
                    ? Duration.zero
                    : const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                transform: Matrix4.translationValues(_offset, 0, 0),
                child: GestureDetector(
                  onTap: () {
                    if (_offset < 0) {
                      _close();
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => _ConvChatPage(conversation: conv),
                        ),
                      );
                    }
                  },
                  child: Container(
                    height: 102,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: conv.isPinned
                          ? const Color(0xFFF4FAF6)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(232, 231, 231, 0.25),
                          blurRadius: 8,
                          offset: Offset(0, 0),
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
                          child: const Icon(
                            Icons.map_outlined,
                            size: 22,
                            color: Color(0xFF18C777),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                conv.title,
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
                                conv.subtitle,
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
                                _formatTime(conv.createdAt),
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${time.month}月${time.day}日';
  }
}

/// 可继续对话的 AI 聊天页 — 历史对话点击后进入
class _ConvChatPage extends StatefulWidget {
  const _ConvChatPage({required this.conversation});

  final AiConversation conversation;

  @override
  State<_ConvChatPage> createState() => _ConvChatPageState();
}

class _ConvChatPageState extends State<_ConvChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AiTravelAgent _agent = createAiTravelAgent();
  late final List<_AiChatMessage> _messages;
  final List<AiTravelAgentTurn> _agentHistory = [];
  bool _isThinking = false;

  @override
  void initState() {
    super.initState();
    _messages = widget.conversation.messages.map((m) {
      return _AiChatMessage(
        role: m.role == 'user' ? _AiChatRole.user : _AiChatRole.assistant,
        text: m.content,
      );
    }).toList();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _controller.text).trim();
    if (text.isEmpty || _isThinking) return;

    setState(() {
      _controller.clear();
      _messages.add(_AiChatMessage(role: _AiChatRole.user, text: text));
      _isThinking = true;
    });
    _scrollToBottom();

    try {
      final history = List<AiTravelAgentTurn>.of(_agentHistory);
      final reply = await _agent.planTrip(text, history: history);
      if (!mounted) return;
      final assistantText = reply.replyText;
      setState(() {
        _messages.add(
          _AiChatMessage(
            role: _AiChatRole.assistant,
            text: assistantText,
            plan: reply.plan,
            requestStartDate: reply.requestStartDate,
          ),
        );
        _agentHistory
          ..add(AiTravelAgentTurn(role: AiTravelAgentRole.user, content: text))
          ..add(
            AiTravelAgentTurn(
              role: AiTravelAgentRole.assistant,
              content: assistantText,
            ),
          );
        _isThinking = false;
      });
      // 追加保存到当前对话
      ConversationService.instance.appendToConversation(
        widget.conversation.id,
        messages: [
          ConvMessage(role: 'user', content: text),
          ConvMessage(role: 'assistant', content: assistantText),
        ],
        result: reply.plan,
      );
    } on AiTravelAgentException catch (error) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          _AiChatMessage(role: _AiChatRole.assistant, text: error.message),
        );
        _isThinking = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          _AiChatMessage(role: _AiChatRole.assistant, text: 'AI 规划失败：$error'),
        );
        _isThinking = false;
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
    });
  }

  void _renameTitle(BuildContext context) {
    final ctrl = TextEditingController(text: widget.conversation.title);
    showDialog(
      context: context,
      builder: (ctx) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 300,
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '修改标题',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF151515),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F8F7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: ctrl,
                    autofocus: true,
                    maxLength: 30,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1C1C1E),
                    ),
                    decoration: const InputDecoration(
                      hintText: '输入新标题',
                      hintStyle: TextStyle(
                        color: Color(0xFFBBBBBB),
                        fontSize: 15,
                      ),
                      counterText: '',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        child: const Text(
                          '取消',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF999999),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        final t = ctrl.text.trim();
                        if (t.isNotEmpty) {
                          ConversationService.instance.renameConversation(
                            widget.conversation.id,
                            t,
                          );
                          setState(() {});
                        }
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C1E),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          '确定',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F7),
      body: SafeArea(
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Column(
            children: [
              // Header — 复用聊天页头部 + 编辑/更多按钮
              SizedBox(
                height: 66,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_rounded, size: 24),
                        color: const Color(0xFF202326),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.conversation.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF151515),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _renameTitle(context),
                        icon: const Icon(Icons.edit_outlined, size: 22),
                        color: const Color(0xFF202326),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.more_vert_rounded, size: 23),
                        color: const Color(0xFF202326),
                      ),
                    ],
                  ),
                ),
              ),
              const _AiChatModeDivider(label: '继续对话'),
              Expanded(
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 14),
                  children: [
                    for (final message in _messages)
                      _AiMessageBubble(
                        message: message,
                        onStartDateSelected: (date) =>
                            _send(_formatStartDateMessage(date)),
                      ),
                    if (_isThinking) const _AiThinkingBubble(),
                  ],
                ),
              ),
              _AiChatInput(
                controller: _controller,
                enabled: !_isThinking,
                onSend: _send,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConvDetailBubble extends StatelessWidget {
  const _ConvDetailBubble({required this.text, required this.isUser});

  final String text;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    if (isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * .7,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.42,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _AiOrb(size: 20),
        const SizedBox(width: 10),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 12,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF202426),
                fontSize: 14,
                height: 1.42,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ConvPlanCard extends StatelessWidget {
  const _ConvPlanCard({required this.result});

  final TravelAgentResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF18C777),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${result.destination} · ${result.durationDays}天',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF151515),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            result.summary,
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: Color(0xFF5F6669),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          for (final day in result.days)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _AiPlanDayRow(day: day),
            ),
        ],
      ),
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
              'Mock map · ${pois.length} POI · $categories categories',
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
  const BottomDock({
    super.key,
    required this.current,
    required this.onChanged,
    required this.onCreatePlan,
  });

  final AppTab current;
  final ValueChanged<AppTab> onChanged;
  final VoidCallback onCreatePlan;

  static const double _width = 258;
  static const double _height = 81;
  static const double _barTop = 23;
  static const double _barHeight = 58;
  static const double _activeSize = 32;
  static const double _createSize = 45;
  static const List<double> _buttonCenters = [31, 86, 172, 227];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: _width,
        height: _height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              top: _barTop,
              child: Image.asset(
                'assets/icons/navigation.png',
                width: _width,
                height: _barHeight,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.high,
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              left: _buttonCenters[current.index] - (_activeSize / 2),
              top: _barTop + 13,
              child: Container(
                width: _activeSize,
                height: _activeSize,
                decoration: const BoxDecoration(
                  color: Color(0xFF3C3C3C),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            for (final item in _DockButtonItem.items)
              Positioned(
                left: _buttonCenters[item.tab.index] - 24,
                top: _barTop + 5,
                child: _DockButton(
                  item: item,
                  active: current == item.tab,
                  onChanged: onChanged,
                ),
              ),
            Positioned(
              left: (_width - _createSize) / 2,
              top: 0,
              child: _DockCreateButton(onPressed: onCreatePlan),
            ),
          ],
        ),
      ),
    );
  }
}

class _DockCreateButton extends StatelessWidget {
  const _DockCreateButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkResponse(
        onTap: onPressed,
        radius: 28,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: BottomDock._createSize,
          height: BottomDock._createSize,
          child: Image.asset(
            'assets/images/Group 61.png',
            width: BottomDock._createSize,
            height: BottomDock._createSize,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }
}

class _DockButton extends StatelessWidget {
  const _DockButton({
    required this.item,
    required this.active,
    required this.onChanged,
  });

  final _DockButtonItem item;
  final bool active;
  final ValueChanged<AppTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkResponse(
        onTap: () => onChanged(item.tab),
        radius: 24,
        containedInkWell: true,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: Image.asset(
              item.asset,
              width: item.width,
              height: item.height,
              color: active ? Colors.white : const Color(0xFF726E6E),
              colorBlendMode: BlendMode.srcIn,
              filterQuality: FilterQuality.none,
            ),
          ),
        ),
      ),
    );
  }
}

class _DockButtonItem {
  const _DockButtonItem({
    required this.tab,
    required this.asset,
    required this.width,
    required this.height,
  });

  final AppTab tab;
  final String asset;
  final double width;
  final double height;

  static const items = [
    _DockButtonItem(
      tab: AppTab.home,
      asset: 'assets/icons/nav-home-figma.png',
      width: 12,
      height: 12,
    ),
    _DockButtonItem(
      tab: AppTab.explore,
      asset: 'assets/icons/nav-map-figma.png',
      width: 16,
      height: 16,
    ),
    _DockButtonItem(
      tab: AppTab.schedule,
      asset: 'assets/icons/nav-calendar-figma.png',
      width: 15,
      height: 15,
    ),
    _DockButtonItem(
      tab: AppTab.profile,
      asset: 'assets/icons/nav-profile-figma.png',
      width: 16,
      height: 18,
    ),
  ];
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
    name: '娌堥槼鏁呭',
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

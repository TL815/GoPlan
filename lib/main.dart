import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ai_travel_agent.dart';
import 'services/weather_service.dart';
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

void _openPlanDetail(BuildContext context, TravelPlan plan) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
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
          backgroundImage: AssetImage('assets/images/我的.png'),
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

  @override
  Widget build(BuildContext context) {
    // 加载中显示骨架
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

    return Row(
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
      final plan = await _agent.planTrip(text, history: history);
      if (!mounted) return;
      final assistantText = plan.toChatText();
      setState(() {
        _messages.add(
          _AiChatMessage(
            role: _AiChatRole.assistant,
            text: assistantText,
            plan: plan,
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
                      _AiMessageBubble(message: message),
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
                onTap: () =>
                    onPromptSelected('从成都出发，帮我规划川西雪山小环线 6 天，节奏舒适，适合第一次去。'),
              ),
              _AiPromptChip(
                text: '杭州周末情侣游',
                onTap: () => onPromptSelected('帮我规划杭州 2 天情侣周末游，想要西湖、咖啡、轻松拍照。'),
              ),
              _AiPromptChip(
                text: '云南毕业旅行',
                onTap: () =>
                    onPromptSelected('帮我规划云南 8 天毕业旅行，4 个人，喜欢美食、古城和自然风景。'),
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
  const _AiMessageBubble({required this.message});

  final _AiChatMessage message;

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
          Flexible(child: bubble),
        ],
      ),
    );
  }
}

class _AiTextBubble extends StatelessWidget {
  const _AiTextBubble({required this.message});

  final _AiChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * .7,
      ),
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
        message.text,
        style: const TextStyle(
          color: Color(0xFF202426),
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
  const _AiChatMessage({required this.role, required this.text, this.plan});

  final _AiChatRole role;
  final String text;
  final TravelAgentResult? plan;
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
            child: item.isNetwork
                ? Image.network(
                    item.image,
                    width: 60,
                    height: 54,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (_, _, _) =>
                        const _AmapImageErrorPlaceholder(compact: true),
                  )
                : Image.asset(
                    item.image,
                    width: 60,
                    height: 54,
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
    useSafeArea: true,
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
        return Padding(
          padding: EdgeInsets.fromLTRB(14, 0, 14, _isFullScreen ? 0 : 14),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8F7),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(_isFullScreen ? 0 : 30),
                bottom: Radius.circular(_isFullScreen ? 0 : 30),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x24000000),
                  blurRadius: 28,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
              children: [
                const _SheetDragHandle(),
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: SizedBox(
                        height: 180,
                        width: double.infinity,
                        child: widget.item.isNetwork
                            ? Image.network(
                                widget.item.image,
                                fit: BoxFit.cover,
                                filterQuality: FilterQuality.high,
                                errorBuilder: (_, _, _) =>
                                    const _AmapImageErrorPlaceholder(),
                              )
                            : Image.asset(widget.item.image, fit: BoxFit.cover),
                      ),
                    ),
                    if (_isFullScreen)
                      Positioned(
                        right: 12,
                        top: 12,
                        child: IconButton.filled(
                          onPressed: () => Navigator.of(context).pop(),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withValues(
                              alpha: .92,
                            ),
                            foregroundColor: const Color(0xFF222222),
                          ),
                          icon: const Icon(Icons.close_rounded, size: 20),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.item.spot.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF111111),
                        ),
                      ),
                    ),
                  ],
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
                      widget.item.spot.city,
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
                  children: [
                    for (final tag in widget.item.spot.tags)
                      _SpotTag(label: tag),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  widget.item.spot.description,
                  style: const TextStyle(
                    color: Color(0xFF555E5A),
                    fontSize: 14,
                    height: 1.55,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
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
                          widget.item.spot.tip,
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
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SheetDragHandle extends StatelessWidget {
  const _SheetDragHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      child: Center(
        child: Container(
          width: 38,
          height: 5,
          decoration: BoxDecoration(
            color: const Color(0xFFDDE1E0),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
      ),
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
          constraints: const BoxConstraints(minHeight: 122),
          padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                color: Color(0x18000000),
                blurRadius: 22,
                offset: Offset(0, 10),
              ),
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 4,
                offset: Offset(0, 1),
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
    tags: ['城市绿地', '散步', '亲子友好'],
    description: '世纪公园是浦东中心城区里很适合慢逛的开放式绿地，湖面、林荫路和草坪空间都很舒展，适合安排在城市行程的轻松半天。',
    tip: '建议上午或傍晚前往，光线更柔和；可以和世纪大道、陆家嘴一带串成一条轻量城市漫步路线。',
  ),
  _HomePhotoSpot(
    name: '外滩万国建筑群',
    city: '上海 · 黄浦区',
    tags: ['夜景', '建筑', '经典地标'],
    description: '外滩是上海最具代表性的城市界面，一侧是历史建筑群，另一侧隔江望向陆家嘴天际线，适合第一次到上海的游客作为城市印象起点。',
    tip: '傍晚到夜间体验最好。想避开人流，可以从外白渡桥方向慢慢走到十六铺码头。',
  ),
  _HomePhotoSpot(
    name: '陆家嘴天际线',
    city: '上海 · 浦东新区',
    tags: ['城市摄影', '观景', '地标'],
    description: '陆家嘴聚集了东方明珠、上海中心、金茂大厦等高层地标，适合安排观景台、滨江步道和商圈休整。',
    tip: '如果时间紧，可以把陆家嘴滨江和外滩放在同一天，形成一条黄浦江两岸对望路线。',
  ),
  _HomePhotoSpot(
    name: '东方明珠',
    city: '上海 · 浦东新区',
    tags: ['观景台', '亲子', '夜景'],
    description: '东方明珠是上海辨识度最高的城市地标之一，适合登高看黄浦江弯道，也适合在周边拍摄城市夜景。',
    tip: '登塔建议提前预约；如果只想拍照，陆家嘴环岛和滨江步道就能获得不错视角。',
  ),
  _HomePhotoSpot(
    name: '苏州河城市漫步',
    city: '上海 · 静安/虹口',
    tags: ['慢行', '咖啡', '历史街区'],
    description: '苏州河沿线适合低强度城市漫步，桥梁、仓库改造空间和咖啡小店密集，节奏比热门景点更松弛。',
    tip: '可以从四行仓库出发，沿河走到外白渡桥，再接外滩夜景，路线衔接自然。',
  ),
  _HomePhotoSpot(
    name: '武康路街区',
    city: '上海 · 徐汇区',
    tags: ['梧桐街道', 'Citywalk', '拍照'],
    description: '武康路街区以梧桐树、老洋房和小型店铺构成轻松的城市漫步氛围，适合安排在下午慢慢逛。',
    tip: '周末人流较多，建议工作日上午或傍晚去；路线可串联安福路、湖南路和徐家汇公园。',
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
  });

  final String image;
  final String fallbackImage;
  final _HomePhotoSpot spot;
  final bool isNetwork;
}

Future<List<_HomePhotoItem>> _fetchHomePhotoStripItems() async {
  const keywords = ['世纪公园', '外滩', '陆家嘴', '东方明珠', '苏州河', '武康路'];
  final results = await Future.wait(
    keywords.map(
      (keyword) => fetchAmapPhotoSpots(keyword: keyword, city: '上海'),
    ),
  );
  final fallbackItems = _fallbackHomePhotoItems;
  return results
      .expand((spots) => spots)
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

String _compactAmapTag(String value) {
  final parts = value.split(';').where((item) => item.trim().isNotEmpty);
  final last = parts.isEmpty ? value : parts.last;
  return last.replaceAll('相关地点', '').trim();
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
      builder: (context, scrollController) => Container(
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
          showHandle: true,
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
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
        child: Column(
          children: [
            _PlanDetailTopBar(
              title: plan.title,
              onClose: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: _PlanDetailContent(
                plan: plan,
                showHandle: false,
                onClose: () => Navigator.of(context).pop(),
              ),
            ),
          ],
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
  });

  final TravelPlan plan;
  final ScrollController? controller;
  final bool showHandle;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: controller,
      padding: EdgeInsets.fromLTRB(18, showHandle ? 0 : 6, 18, 28),
      children: [
        if (showHandle) ...[const _SheetDragHandle()],
        _PlanCover(plan: plan),
        const SizedBox(height: 16),
        const _PlanTags(),
        const SizedBox(height: 14),
        Text(
          '${plan.title} · ${plan.days}天',
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
              text: '¥${plan.days * 320} 人均',
            ),
            const SizedBox(width: 18),
            _PlanMeta(icon: Icons.map_outlined, text: '${plan.places} 个地点'),
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
        const SizedBox(height: 18),
        _PlanRouteInlineSection(plan: plan),
        const SizedBox(height: 18),
        _DetailTipCard(plan: plan),
        const SizedBox(height: 18),
        _PlanStartBar(plan: plan),
      ],
    );
  }
}

class _PlanCover extends StatelessWidget {
  const _PlanCover({required this.plan});

  final TravelPlan plan;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: 1.78,
        child: Stack(
          fit: StackFit.expand,
          children: [_AmapPlanCoverImage(plan: plan)],
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
    final fallbackUrls = [_planCoverAsset(plan)];
    return FutureBuilder<List<String>>(
      future: fetchAmapPhotoUrls(
        keyword: _planCoverKeyword(plan),
        city: _planCoverCity(plan),
      ),
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState != ConnectionState.done;
        if (isLoading && !snapshot.hasData) {
          return const _PlanCoverLoading();
        }

        final urls = snapshot.data?.isNotEmpty == true
            ? snapshot.data!
            : fallbackUrls;
        return _PlanCoverCarousel(
          urls: urls,
          isNetwork: snapshot.data?.isNotEmpty == true,
        );
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

class _PlanCoverCarousel extends StatefulWidget {
  const _PlanCoverCarousel({required this.urls, required this.isNetwork});

  final List<String> urls;
  final bool isNetwork;

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
            if (!widget.isNetwork) {
              return Image.asset(url, fit: BoxFit.cover);
            }
            return Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  Image.asset(_planCoverAssetFallback, fit: BoxFit.cover),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return ColoredBox(
                  color: const Color(0xFFEDEDED),
                  child: const Center(
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
        _PlanTag(icon: Icons.account_balance_outlined, text: '建筑'),
        SizedBox(width: 8),
        _PlanTag(icon: Icons.eco_outlined, text: '自然'),
        SizedBox(width: 8),
        _PlanTag(icon: Icons.museum_outlined, text: '人文'),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(height: 154, child: _DetailRouteMap(plan: plan)),
    );
  }
}

class _PlanRouteInlineSection extends StatelessWidget {
  const _PlanRouteInlineSection({required this.plan});

  final TravelPlan plan;

  @override
  Widget build(BuildContext context) {
    final segments = _routeSegmentsFor(plan);
    final days = _dailyPlanFor(plan);
    final totalDistance = segments.fold<int>(
      0,
      (sum, segment) => sum + segment.distanceKm,
    );
    final totalHours = segments.fold<double>(
      0,
      (sum, segment) => sum + segment.durationHours,
    );

    return Column(
      key: const Key('route-planner-inline'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _RouteSummaryTile(
                icon: Icons.route_outlined,
                value: '$totalDistance km',
                label: '预估总里程',
                color: plan.accent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _RouteSummaryTile(
                icon: Icons.schedule_rounded,
                value: '${totalHours.toStringAsFixed(1)} h',
                label: '城际交通',
                color: const Color(0xFF24D391),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _RouteSectionTitle(
          icon: Icons.alt_route_rounded,
          title: '目的地路线',
          action: '共${segments.length}段',
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < segments.length; i++)
          _RouteSegmentCard(
            segment: segments[i],
            index: i + 1,
            accent: plan.accent,
          ),
        const SizedBox(height: 16),
        _RouteSectionTitle(
          icon: Icons.event_note_rounded,
          title: '每日安排',
          action: '${plan.days}天',
        ),
        const SizedBox(height: 10),
        for (final day in days) _DailyPlanCard(day: day, accent: plan.accent),
      ],
    );
  }
}

class _PlanStartBar extends StatelessWidget {
  const _PlanStartBar({required this.plan});

  final TravelPlan plan;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.filled(
          onPressed: () {},
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF1F1F1F),
            fixedSize: const Size(50, 50),
          ),
          icon: const Icon(Icons.edit_outlined, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: () {},
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1F2230),
              foregroundColor: Colors.white,
              fixedSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text(
              '开始我的旅行',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
        const SizedBox(width: 12),
        IconButton.filled(
          onPressed: () {},
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFF1F2230),
            foregroundColor: Colors.white,
            fixedSize: const Size(50, 50),
          ),
          icon: const Icon(Icons.near_me_outlined, size: 20),
        ),
      ],
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
  const _DailyPlanCard({required this.day, required this.accent});

  final _DailyPlan day;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'D${day.index}',
              style: TextStyle(
                color: accent,
                fontSize: 14,
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
                  day.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF151515),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  day.description,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF777777),
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
        Positioned.fill(child: CustomPaint(painter: _RouteMapPainter(plan))),
        Positioned(
          left: 28,
          bottom: 86,
          child: _MapControlButton(icon: Icons.add, onTap: () {}),
        ),
        Positioned(
          left: 28,
          bottom: 42,
          child: _MapControlButton(icon: Icons.remove, onTap: () {}),
        ),
        Positioned(
          right: 28,
          bottom: 56,
          child: _MapControlButton(
            icon: Icons.my_location_outlined,
            onTap: () {},
          ),
        ),
        for (var i = 0; i < plan.routeStops.length; i++)
          _DetailPhotoMarker(
            stop: plan.routeStops[i],
            photo: 'assets/images/photo-${(i % 7) + 1}.png',
            color: i.isEven ? plan.accent : const Color(0xFFFF7A45),
          ),
      ],
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
  const BottomDock({super.key, required this.current, required this.onChanged});

  final AppTab current;
  final ValueChanged<AppTab> onChanged;

  static const double _width = 258;
  static const double _height = 58;
  static const double _activeSize = 32;
  static const List<double> _buttonCenters = [38, 95, 154, 212];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: _width,
        height: _height,
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
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              left: _buttonCenters[current.index] - (_activeSize / 2),
              top: 13,
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
                top: 5,
                child: _DockButton(
                  item: item,
                  active: current == item.tab,
                  onChanged: onChanged,
                ),
              ),
          ],
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

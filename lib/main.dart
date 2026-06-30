import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const bool _useMockMapPreview = true;

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
          Positioned(left: 0, right: 0, top: 42, child: _WeatherPanel()),
          Positioned(left: 0, right: 0, top: 104, child: _PhotoStrip()),
          Positioned(left: 0, right: 0, top: 96, child: _AiDialogBar()),
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
              Icon(Icons.auto_awesome_rounded, color: Color(0xFF4C4C4C)),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '和 GoPlan AI 聊聊你的旅行想法',
                  style: TextStyle(color: Color(0xFF8F8F8F), fontSize: 14),
                ),
              ),
              Icon(Icons.keyboard_voice_outlined, color: Color(0xFF4C4C4C)),
            ],
          ),
        ),
      ),
    );
  }

  void _openAiChat(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AiChatSheet(),
    );
  }
}

class _AiChatSheet extends StatefulWidget {
  const _AiChatSheet();

  @override
  State<_AiChatSheet> createState() => _AiChatSheetState();
}

class _AiChatSheetState extends State<_AiChatSheet> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_AiChatMessage> _messages = [
    const _AiChatMessage(
      role: _AiChatRole.assistant,
      text: '你好，我是 GoPlan AI。你可以告诉我想去哪、几天、和谁去，我会先帮你整理成行程思路。',
    ),
  ];
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

    final reply = await _mockDeepSeekReply(text);
    if (!mounted) return;

    setState(() {
      _messages.add(_AiChatMessage(role: _AiChatRole.assistant, text: reply));
      _isThinking = false;
    });
    _scrollToBottom();
  }

  Future<String> _mockDeepSeekReply(String prompt) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (prompt.contains('川西') || prompt.contains('雪山')) {
      return '可以先按 6 天小团路线规划：成都集合，康定适应海拔，新都桥拍摄，塔公草原看雪山，最后回成都。我后续接入 DeepSeek 后，可以继续生成每日路线、预算和 POI。';
    }
    if (prompt.contains('杭州') || prompt.contains('周末')) {
      return '周末游建议控制在 2-3 个核心区域：西湖、灵隐、河坊街。第一天慢逛城市风景，第二天留给茶园或博物馆，会比较松弛。';
    }
    if (prompt.contains('云南') || prompt.contains('毕业')) {
      return '毕业旅行适合做成 8-9 天：昆明落地，大理放松，丽江古城和玉龙雪山，再去香格里拉。重点是减少搬运行李的频率。';
    }
    return '我先记下这个想法。可以继续补充出发城市、旅行天数、预算、人群和偏好的节奏，我会把它整理成可执行的行程草案。';
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
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: .82,
        minChildSize: .5,
        maxChildSize: .94,
        builder: (context, sheetController) {
          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF7F8F7),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8DCDC),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 10, 10),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          color: Color(0xFF111111),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: Color(0xFF28D99A),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'GoPlan AI',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              '本地 Mock 对话 · 预留 DeepSeek 接入',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF8C8C8C),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    children: [
                      _AiSuggestionChip(
                        text: '帮我规划川西 6 天',
                        onTap: () => _send('帮我规划川西雪山小团 6 天'),
                      ),
                      _AiSuggestionChip(
                        text: '杭州周末怎么安排',
                        onTap: () => _send('杭州情侣周末游怎么安排'),
                      ),
                      _AiSuggestionChip(
                        text: '云南毕业旅行',
                        onTap: () => _send('云南朋友毕业旅行 9 天'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(18, 6, 18, 12),
                    itemCount: _messages.length + (_isThinking ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isThinking && index == _messages.length) {
                        return const _AiThinkingBubble();
                      }
                      return _AiMessageBubble(message: _messages[index]);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                          decoration: InputDecoration(
                            hintText: '输入你的旅行想法...',
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 13,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(22),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton.filled(
                        onPressed: _isThinking ? null : () => _send(),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF111111),
                          disabledBackgroundColor: const Color(0xFFBFC4C2),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.arrow_upward_rounded),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AiSuggestionChip extends StatelessWidget {
  const _AiSuggestionChip({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        onPressed: onTap,
        label: Text(text),
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFFE8ECEA)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * .74,
        ),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF111111) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 6),
            bottomRight: Radius.circular(isUser ? 6 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .05),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: isUser ? Colors.white : const Color(0xFF242A2D),
            fontSize: 14,
            height: 1.38,
          ),
        ),
      ),
    );
  }
}

class _AiThinkingBubble extends StatelessWidget {
  const _AiThinkingBubble();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(bottom: 10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Text(
              'GoPlan AI 正在整理...',
              style: TextStyle(fontSize: 14, color: Color(0xFF7D8588)),
            ),
          ),
        ),
      ),
    );
  }
}

enum _AiChatRole { user, assistant }

class _AiChatMessage {
  const _AiChatMessage({required this.role, required this.text});

  final _AiChatRole role;
  final String text;
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
              left: 22 + i * 43.0,
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
      canvas.drawLine(
        Offset(x, -20),
        Offset(x + 34, size.height + 20),
        minor,
      );
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

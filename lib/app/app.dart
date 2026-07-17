part of '../main.dart';

const bool _useMockMapPreview = true;
const bool _showCalendarPreview = bool.fromEnvironment('CALENDAR_PREVIEW');
const String _planCoverAssetFallback =
    'assets/images/4b5386239b0a7bb499c00d0c03fa39d4.webp';

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
      home: _showCalendarPreview ? const _AiChatPage() : const GoPlanShell(),
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

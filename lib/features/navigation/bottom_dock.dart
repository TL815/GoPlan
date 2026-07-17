part of '../../main.dart';

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

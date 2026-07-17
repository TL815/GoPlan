// ignore_for_file: dead_code, unused_element, unused_element_parameter

part of '../../main.dart';

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

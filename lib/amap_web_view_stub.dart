import 'package:flutter/widgets.dart';

class AmapWebPoi {
  const AmapWebPoi({
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
}

class AmapWebView extends StatelessWidget {
  const AmapWebView({super.key, required this.pois});

  final List<AmapWebPoi> pois;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

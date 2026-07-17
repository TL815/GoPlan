import 'package:flutter/material.dart';

import 'ui_action_preview_page.dart';

void main() {
  runApp(const UiActionPreviewApp());
}

class UiActionPreviewApp extends StatelessWidget {
  const UiActionPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GoPlan UiAction Preview',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF28D99A)),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF28D99A),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const UiActionPreviewPage(),
    );
  }
}

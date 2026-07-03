import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:goplan/main.dart';

void main() {
  testWidgets('GoPlan shows loading page and enters home', (tester) async {
    await tester.pumpWidget(const GoPlanApp());

    expect(find.text('去出发！'), findsOneWidget);

    await tester.tap(find.text('去出发！'));
    await tester.pumpAndSettle();

    expect(find.text('青甘大环线10天游'), findsOneWidget);
  });

  testWidgets('AI chat entry opens full screen chat page', (tester) async {
    await tester.pumpWidget(const GoPlanApp());

    await tester.tap(find.text('去出发！'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('聊聊你的旅行想法'));
    await tester.pumpAndSettle();

    expect(find.text('GoPlan AI 旅行规划'), findsOneWidget);
    expect(find.text('告诉我你的旅行想法'), findsOneWidget);
    expect(find.text('问我任何旅行问题...'), findsOneWidget);
    expect(find.text('我下个月想去日本旅行。'), findsNothing);
  });

  testWidgets('plan detail shows route planner below map', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: PlanDetailFullPage(plan: demoPlans.first)),
    );

    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();

    expect(find.text('目的地路线'), findsOneWidget);
    expect(find.text('西宁  →  青海湖'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();

    expect(find.text('每日安排'), findsOneWidget);
  });
}

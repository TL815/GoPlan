import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goplan/domain/itinerary/budget_summary.dart';
import 'package:goplan/features/plan/itinerary/itinerary_budget_card.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
  }

  testWidgets('shows total per person and non-empty categories', (
    tester,
  ) async {
    await pump(
      tester,
      const ItineraryBudgetCard(
        budget: BudgetSummary(
          total: 1000,
          perPerson: 500,
          transport: 200,
          food: 300,
          currency: 'CNY',
        ),
      ),
    );

    expect(find.text('¥1000'), findsOneWidget);
    expect(find.text('人均 ¥500'), findsOneWidget);
    expect(find.text('交通 ¥200'), findsOneWidget);
    expect(find.text('餐饮 ¥300'), findsOneWidget);
    expect(find.textContaining('住宿'), findsNothing);
  });

  testWidgets('hides empty budget and does not calculate total', (
    tester,
  ) async {
    await pump(tester, const ItineraryBudgetCard(budget: BudgetSummary()));
    expect(find.byType(Card), findsNothing);

    await pump(
      tester,
      const ItineraryBudgetCard(
        budget: BudgetSummary(transport: 100, food: 200, currency: 'ABC'),
      ),
    );
    expect(find.text('ABC 300'), findsNothing);
    expect(find.text('交通 ABC 100'), findsOneWidget);
  });
}

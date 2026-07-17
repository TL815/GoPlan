import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goplan/application/assistant/ui_action/date_range_selection.dart';
import 'package:goplan/application/assistant/ui_action/ui_action_interaction_port.dart';
import 'package:goplan/domain/assistant/ui_action.dart';
import 'package:goplan/domain/assistant/ui_action_option.dart';
import 'package:goplan/domain/assistant/ui_action_type.dart';
import 'package:goplan/features/ai_chat/ui_action/flutter_ui_action_interaction_port.dart';

void main() {
  final today = DateTime(2026, 7, 15);

  Future<FlutterUiActionInteractionPort> pumpPort(
    WidgetTester tester, {
    bool mounted = true,
  }) async {
    late BuildContext hostContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            hostContext = context;
            return const Scaffold(body: Text('host'));
          },
        ),
      ),
    );
    return FlutterUiActionInteractionPort(
      contextProvider: () => hostContext,
      isMounted: () => mounted,
      today: () => today,
    );
  }

  UiAction action(
    UiActionType type, {
    String? title,
    String? description,
    bool allowCustomInput = false,
    List<UiActionOption> options = const [],
    Map<String, Object?> payload = const {},
  }) {
    return UiAction(
      type: type,
      title: title,
      description: description,
      allowCustomInput: allowCustomInput,
      options: options,
      payload: payload,
    );
  }

  testWidgets('implements UiActionInteractionPort and checks mounted', (
    tester,
  ) async {
    final port = await pumpPort(tester, mounted: false);

    expect(port, isA<UiActionInteractionPort>());
    expect(
      () => port.requestStartDate(action(UiActionType.requestStartDate)),
      throwsStateError,
    );
  });

  testWidgets('single date can cancel and can submit initial date', (
    tester,
  ) async {
    final port = await pumpPort(tester);
    final dateAction = action(
      UiActionType.requestStartDate,
      payload: {'initial_date': '2026-08-03'},
    );

    final cancelFuture = port.requestStartDate(dateAction);
    await tester.pumpAndSettle();
    expect(find.text('选择出发日期'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(await cancelFuture, isNull);

    final submitFuture = port.requestStartDate(dateAction);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(await submitFuture, DateTime(2026, 8, 3));
  });

  testWidgets('date range returns DateRangeSelection', (tester) async {
    final port = await pumpPort(tester);

    final future = port.requestDateRange(
      action(
        UiActionType.requestDateRange,
        payload: {'start_date': '2026-08-03', 'end_date': '2026-08-09'},
      ),
    );
    await tester.pumpAndSettle();
    await _tapFirstText(tester, const ['Save', 'SAVE', 'OK']);
    await tester.pumpAndSettle();

    final result = await future;
    expect(result, isA<DateRangeSelection>());
    expect(result?.start, DateTime(2026, 8, 3));
    expect(result?.end, DateTime(2026, 8, 9));
  });

  testWidgets('option sheet shows content and returns original option', (
    tester,
  ) async {
    final option = UiActionOption(
      id: 'relaxed',
      label: 'Relaxed',
      value: 'relaxed',
      description: 'Easy pace',
    );
    final port = await pumpPort(tester);

    final future = port.selectOption(
      action(
        UiActionType.selectOption,
        title: 'Choose pace',
        description: 'Pick one',
        options: [option],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Choose pace'), findsOneWidget);
    expect(find.text('Pick one'), findsOneWidget);
    expect(find.text('Relaxed'), findsOneWidget);
    await tester.tap(find.text('Relaxed'));
    await tester.pumpAndSettle();

    expect(await future, same(option));
  });

  testWidgets('custom option trims text and blocks empty submit', (
    tester,
  ) async {
    final port = await pumpPort(tester);

    final future = port.selectOption(
      action(
        UiActionType.selectOption,
        allowCustomInput: true,
        options: [UiActionOption(id: 'a', label: 'A')],
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('其他 / 自定义输入'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('提交'));
    await tester.pump();
    expect(find.byType(TextField), findsOneWidget);
    await tester.enterText(find.byType(TextField), '  museum  ');
    await tester.tap(find.text('提交'));
    await tester.pumpAndSettle();

    final result = await future;
    expect(result?.id, 'custom');
    expect(result?.label, 'museum');
    expect(result?.value, 'museum');
  });

  testWidgets('empty options show empty state and close returns null', (
    tester,
  ) async {
    final port = await pumpPort(tester);

    final future = port.selectOption(action(UiActionType.selectOption));
    await tester.pumpAndSettle();
    expect(find.text('暂无可选项'), findsOneWidget);
    expect(find.text('其他 / 自定义输入'), findsNothing);
    await tester.tap(find.text('关闭'));
    await tester.pumpAndSettle();

    expect(await future, isNull);
  });

  testWidgets('number sheet validates and returns int or double', (
    tester,
  ) async {
    final intPort = await pumpPort(tester);
    final intFuture = intPort.inputNumber(
      action(
        UiActionType.inputNumber,
        title: 'Travelers',
        description: 'How many?',
        payload: {'min': 2, 'max': 8, 'prefix': '#', 'suffix': 'people'},
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Travelers'), findsOneWidget);
    expect(find.text('How many?'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '1');
    await tester.tap(find.text('提交'));
    await tester.pump();
    expect(find.text('数值不能小于 2'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '5');
    await tester.tap(find.text('提交'));
    await tester.pumpAndSettle();
    expect(await intFuture, isA<int>());

    final doublePort = await pumpPort(tester);
    final doubleFuture = doublePort.inputNumber(
      action(UiActionType.inputNumber),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '5.5');
    await tester.tap(find.text('提交'));
    await tester.pumpAndSettle();
    expect(await doubleFuture, isA<double>());
  });

  testWidgets('number sheet rejects invalid and max values', (tester) async {
    final port = await pumpPort(tester);
    final future = port.inputNumber(
      action(UiActionType.inputNumber, payload: {'max': '10'}),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'abc');
    await tester.tap(find.text('提交'));
    await tester.pump();
    expect(find.text('请输入有效数字'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '11');
    await tester.tap(find.text('提交'));
    await tester.pump();
    expect(find.text('数值不能大于 10'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(await future, isNull);
  });

  testWidgets('confirmation distinguishes true false and null', (tester) async {
    final confirmPort = await pumpPort(tester);
    final confirmFuture = confirmPort.confirm(
      action(
        UiActionType.confirm,
        payload: {'confirm_label': 'Yes', 'cancel_label': 'No'},
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Yes'), findsOneWidget);
    expect(find.text('No'), findsOneWidget);
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();
    expect(await confirmFuture, isTrue);

    final falsePort = await pumpPort(tester);
    final falseFuture = falsePort.confirm(action(UiActionType.confirm));
    await tester.pumpAndSettle();
    await tester.tap(find.text('暂不确认'));
    await tester.pumpAndSettle();
    expect(await falseFuture, isFalse);

    final nullPort = await pumpPort(tester);
    final nullFuture = nullPort.confirm(action(UiActionType.confirm));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(await nullFuture, isNull);
  });

  testWidgets('date conflict returns original option and empty state closes', (
    tester,
  ) async {
    final option = UiActionOption(
      id: 'keep',
      label: 'Keep selected dates',
      value: {'mode': 'keep'},
    );
    final port = await pumpPort(tester);

    final future = port.confirmDateConflict(
      action(UiActionType.confirmDateConflict, options: [option]),
    );
    await tester.pumpAndSettle();
    expect(find.text('Keep selected dates'), findsOneWidget);
    await tester.tap(find.text('Keep selected dates'));
    await tester.pumpAndSettle();
    expect(await future, same(option));

    final emptyPort = await pumpPort(tester);
    final emptyFuture = emptyPort.confirmDateConflict(
      action(UiActionType.confirmDateConflict),
    );
    await tester.pumpAndSettle();
    expect(find.text('暂无可选日期方案'), findsOneWidget);
    await tester.tap(find.text('关闭'));
    await tester.pumpAndSettle();
    expect(await emptyFuture, isNull);
  });
}

Future<void> _tapFirstText(WidgetTester tester, List<String> labels) async {
  for (final label in labels) {
    final finder = find.text(label);
    if (finder.evaluate().isNotEmpty) {
      await tester.tap(finder);
      return;
    }
  }
  fail('None of the expected labels were found: $labels');
}

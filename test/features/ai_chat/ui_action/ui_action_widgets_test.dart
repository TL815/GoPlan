import 'package:flutter_test/flutter_test.dart';
import 'package:goplan/features/ai_chat/ui_action/preview/ui_action_preview_app.dart';
import 'package:goplan/features/ai_chat/ui_action/preview/ui_action_preview_page.dart';

void main() {
  testWidgets('preview app builds and exposes action buttons', (tester) async {
    await tester.pumpWidget(const UiActionPreviewApp());

    expect(find.byType(UiActionPreviewPage), findsOneWidget);
    expect(find.text('GoPlan UiAction 组件预览'), findsOneWidget);
    expect(find.text('单日期'), findsOneWidget);
    expect(find.text('日期范围'), findsOneWidget);
    expect(find.text('单选项'), findsOneWidget);
    expect(find.text('自定义选项'), findsOneWidget);
    expect(find.text('数字输入'), findsOneWidget);
    expect(find.text('确认操作'), findsOneWidget);
    expect(find.text('日期冲突'), findsOneWidget);
  });
}

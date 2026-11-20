import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valley_express_mobile/main.dart';

void main() {
  testWidgets('Valley Express smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ValleyExpressApp());
    expect(find.byType(ValleyExpressApp), findsOneWidget);

    // The splash runs looping entrance animations and a delayed route change,
    // so the tree never settles. Flush the scheduling timers, tear the tree
    // down, then let the splash's own delay elapse against the empty tree.
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
  });
}

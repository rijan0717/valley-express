import 'package:flutter_test/flutter_test.dart';
import 'package:valley_express_mobile/main.dart';

void main() {
  testWidgets('Valley Express smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ValleyExpressApp());
    expect(find.byType(ValleyExpressApp), findsOneWidget);
  });
}

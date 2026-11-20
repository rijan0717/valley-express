import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valley_express_mobile/widgets/valley_loader.dart';

void main() {
  testWidgets('ValleyLoader paints and keeps animating', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ValleyLoader(size: 84))),
    );

    expect(find.byType(ValleyLoader), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);

    // The painter is driven by two repeating controllers, so the widget must
    // still be scheduling frames after a tick.
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.binding.hasScheduledFrame, isTrue);

    await tester.pump(const Duration(milliseconds: 800));
    expect(tester.binding.hasScheduledFrame, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('ValleyLoaderScreen centres the mark and shows its label',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ValleyLoaderScreen(label: 'Loading orders...')),
      ),
    );

    expect(find.byType(ValleyLoader), findsOneWidget);
    expect(find.text('Loading orders...'), findsOneWidget);

    // Horizontally and vertically centred within the screen
    final screen = tester.getRect(find.byType(ValleyLoaderScreen));
    final mark = tester.getRect(find.byType(ValleyLoader));
    expect(mark.center.dx, closeTo(screen.center.dx, 1));
    expect(mark.center.dy, closeTo(screen.center.dy, 1));

    await tester.pumpWidget(const SizedBox.shrink());
  });
}

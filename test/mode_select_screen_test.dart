import 'package:color_dodge/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('displays both available game choices', (tester) async {
    await tester.pumpWidget(const App());

    expect(find.text('Color Dodge'), findsOneWidget);
    expect(find.text('Survival'), findsOneWidget);
    expect(find.text('Color Match'), findsOneWidget);
    expect(find.text('Recommended'), findsOneWidget);
    expect(find.text('Coming soon'), findsOneWidget);
  });

  testWidgets('explains the upcoming Color Match mode', (tester) async {
    await tester.pumpWidget(const App());

    await tester.tap(find.text('Color Match'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(
      find.text('Color Match mode lands in a future update.'),
      findsOneWidget,
    );

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });
}

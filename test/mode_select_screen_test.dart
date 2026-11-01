import 'package:color_dodge/main.dart';
import 'package:color_dodge/ui/color_match_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('displays all three game choices', (tester) async {
    await tester.pumpWidget(const App());
    await tester.pump();

    expect(find.text('Color Dodge'), findsOneWidget);
    expect(find.text('Survival'), findsOneWidget);
    expect(find.text('Color Match'), findsOneWidget);
    expect(find.text('Daily Challenge'), findsOneWidget);
    expect(find.text('Recommended'), findsOneWidget);
    expect(find.text('New'), findsOneWidget);
    expect(find.text('Coming soon'), findsNothing);
  });

  testWidgets('shows stored Color Match progress on its card', (tester) async {
    SharedPreferences.setMockInitialValues({
      'color_dodge.color_match.best_score': 23,
      'color_dodge.color_match.highest_level': 3,
      'color_dodge.color_match.runs_played': 4,
    });

    await tester.pumpWidget(const App());
    await tester.pump();

    expect(find.textContaining('Best 23 · Level 3'), findsOneWidget);
  });

  testWidgets('refreshes the Color Match card after returning from a run', (
    tester,
  ) async {
    await tester.pumpWidget(const App());
    await tester.pump();

    await tester.tap(find.text('Color Match'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // A run was saved while the game screen was open.
    SharedPreferences.setMockInitialValues({
      'color_dodge.color_match.best_score': 17,
      'color_dodge.color_match.highest_level': 3,
      'color_dodge.color_match.runs_played': 1,
    });

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Best 17 · Level 3'), findsOneWidget);
  });

  testWidgets('opens Color Match with its rules', (tester) async {
    await tester.pumpWidget(const App());
    await tester.pump();

    await tester.tap(find.text('Color Match'));
    // The game loop keeps scheduling frames, so pump a fixed time instead of settling.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(ColorMatchScreen), findsOneWidget);
    expect(
      find.text('Steer into the block with your colour and symbol.'),
      findsOneWidget,
    );
    expect(find.text('First run: no records yet.'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Start'), findsOneWidget);
  });
}

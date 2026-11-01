import 'package:color_dodge/storage/color_match_progress_store.dart';
import 'package:color_dodge/ui/color_match_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpSeconds(WidgetTester tester, double seconds) async {
    const step = Duration(milliseconds: 16);
    for (var elapsed = 0.0; elapsed < seconds; elapsed += 0.016) {
      await tester.pump(step);
    }
  }

  testWidgets(
    'a full run plays through the real game loop and saves progress',
    (tester) async {
      tester.view.physicalSize = const Size(420, 820);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(home: ColorMatchScreen(seed: 42)),
      );
      await tester.pump();

      expect(find.text('Score '), findsOneWidget);
      expect(find.byKey(const Key('hud-lives')), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('hud-lives'))).data,
        '♥ ♥ ♥',
      );

      await tester.tap(find.widgetWithText(ElevatedButton, 'Start'));
      await tester.pump();

      expect(
        find.text('Steer into the block with your colour and symbol.'),
        findsNothing,
      );

      // Without input the player stays in the middle lane, so the seeded course
      // decides every pass; the run must end once three wrong colours were hit.
      for (
        var second = 0;
        second < 240 && find.text('Out of lives').evaluate().isEmpty;
        second++
      ) {
        await pumpSeconds(tester, 1);
      }

      expect(find.text('Out of lives'), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('hud-lives'))).data,
        '♡ ♡ ♡',
      );
      // The rules panel must not come back on top of the results.
      expect(
        find.text('Steer into the block with your colour and symbol.'),
        findsNothing,
      );

      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();

      expect(find.widgetWithText(ElevatedButton, 'Start'), findsNothing);

      final progress = await tester.runAsync(
        () => const ColorMatchProgressStore().load(),
      );
      expect(progress!.runsPlayed, 1);
      expect(find.text('Runs played'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Play again'), findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Play again'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.text('Out of lives'), findsNothing);
      expect(
        tester.widget<Text>(find.byKey(const Key('hud-lives'))).data,
        '♥ ♥ ♥',
      );
    },
  );
}

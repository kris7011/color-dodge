import 'package:color_dodge/game/color_match/color_match_game.dart';
import 'package:color_dodge/main.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Plays Color Match in the real app on a device (run with `flutter test integration_test -d windows`).
///
/// A simple bot reads the approaching rows and steers with real key presses until level 3,
/// then stops steering so the run ends and the results and progress can be checked.
/// Progress is kept in memory so the device's own saved progress is not touched.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  Future<void> wait(WidgetTester tester, int milliseconds) async {
    final end = DateTime.now().add(Duration(milliseconds: milliseconds));
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  testWidgets('Color Match can be played to the end and records progress', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const App());
    await wait(tester, 1500);

    await tester.tap(find.text('Color Match'));
    await wait(tester, 2500); // rules panel visible

    await tester.tap(find.widgetWithText(ElevatedButton, 'Start'));
    await wait(tester, 300);

    final game = tester
        .widget<GameWidget<ColorMatchGame>>(
          find.byType(GameWidget<ColorMatchGame>),
        )
        .game!;
    final started = DateTime.now();

    while (!game.rules.isOver &&
        DateTime.now().difference(started) < const Duration(minutes: 4)) {
      final steering = game.rules.level < 3;
      final rows = game.approachingRows;

      if (steering && rows.isNotEmpty) {
        final colors = rows.first.colors;
        final matching =
            [
              for (var lane = 0; lane < colors.length; lane++)
                if (colors[lane] == game.rules.currentColorIndex) lane,
            ]..sort(
              (a, b) => (a - game.targetLane).abs().compareTo(
                (b - game.targetLane).abs(),
              ),
            );

        if (matching.isNotEmpty && matching.first != game.targetLane) {
          await tester.sendKeyEvent(
            matching.first < game.targetLane
                ? LogicalKeyboardKey.arrowLeft
                : LogicalKeyboardKey.arrowRight,
          );
        }
      }

      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(
      game.rules.isOver,
      isTrue,
      reason: 'the run should end once the bot stops steering',
    );
    expect(game.rules.level, greaterThanOrEqualTo(3));
    expect(game.rules.matches, greaterThanOrEqualTo(16));

    await wait(tester, 2500); // results panel visible
    expect(find.text('Out of lives'), findsOneWidget);
    expect(find.text('New best score!'), findsOneWidget);

    await tester.tap(find.text('Back'));
    await wait(tester, 2500); // menu with progress on the Color Match card

    expect(
      find.textContaining(
        'Best ${game.rules.score} · Level ${game.rules.level}',
      ),
      findsOneWidget,
    );

    // ignore: avoid_print
    print(
      'DEMO RESULT score=${game.rules.score} level=${game.rules.level} '
      'matches=${game.rules.matches} rows=${game.rules.rowsPassed} bestCombo=${game.rules.bestCombo}',
    );
  });
}

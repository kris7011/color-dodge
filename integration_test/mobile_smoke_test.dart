import 'package:color_dodge/game/color_match/color_match_game.dart';
import 'package:color_dodge/main.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bounded real-device smoke test. The four-minute steering bot is separately
/// verified on Android, Windows and Linux, not on iOS CI simulators.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('mobile app launches and starts a real Color Match game', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const App());
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Color Dodge'), findsOneWidget);
    expect(find.text('Color Match'), findsOneWidget);

    await tester.tap(find.text('Color Match'));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Steer into the block with your colour and symbol.'),
        findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Start'));
    await tester.pump(const Duration(milliseconds: 200));

    final game = tester
        .widget<GameWidget<ColorMatchGame>>(
          find.byType(GameWidget<ColorMatchGame>),
        )
        .game!;
    expect(game.hud.value.isRunning, isTrue);
    expect(game.rules.lives, 3);
    expect(find.byKey(const Key('hud-score')), findsOneWidget);
    expect(find.byKey(const Key('hud-lives')), findsOneWidget);
  });
}

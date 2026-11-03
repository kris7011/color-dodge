import 'package:color_dodge/features/preferences/presentation/game_preferences_screen.dart';
import 'package:color_dodge/main.dart';
import 'package:color_dodge/ui/color_match_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('can change saved flash preference and reuse it in Color Match', (
    tester,
  ) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Accessibility settings'));
    await tester.pumpAndSettle();
    expect(find.byType(GamePreferencesScreen), findsOneWidget);
    expect(find.text('Reduce colour flashes'), findsOneWidget);

    final control = find.byKey(const Key('reduce-flashes-switch'));
    expect(tester.widget<SwitchListTile>(control).value, isFalse);
    await tester.tap(control);
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(control).value, isTrue);

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getBool('color_dodge.preferences.reduce_flashes'),
      isTrue,
    );

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Color Match'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      tester.widget<ColorMatchScreen>(find.byType(ColorMatchScreen))
          .reduceFlashes,
      isTrue,
    );
  });
}

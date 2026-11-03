import 'package:color_dodge/features/preferences/data/shared_preferences_game_preferences_repository.dart';
import 'package:color_dodge/features/preferences/domain/game_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('default reduced flash setting is off and persists after saving', () async {
    const repository = SharedPreferencesGamePreferencesRepository();

    expect((await repository.load()).reduceFlashes, isFalse);
    await repository.save(const GamePreferences(reduceFlashes: true));
    expect((await repository.load()).reduceFlashes, isTrue);

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getBool(SharedPreferencesGamePreferencesRepository.keyReduceFlashes),
      isTrue,
    );
  });
}

import 'package:color_dodge/game/game_mode.dart';
import 'package:color_dodge/storage/best_score_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('loads persisted scores across store instances', () async {
    const scores = BestScoreStore(GameMode.survival);
    expect(await scores.load(), 0.0);
    await scores.saveIfHigher(42.5);
    expect(await const BestScoreStore(GameMode.survival).load(), 42.5);
  });

  test('does not replace high scores with lower or invalid values', () async {
    const scores = BestScoreStore(GameMode.survival);
    await scores.saveIfHigher(37.0);
    await scores.saveIfHigher(12.0);
    await scores.saveIfHigher(double.nan);
    await scores.saveIfHigher(-1.0);
    expect(await scores.load(), 37.0);
  });

  test('keeps scores separate for different modes', () async {
    const survival = BestScoreStore(GameMode.survival);
    const colorMatch = BestScoreStore(GameMode.colorMatch);
    await survival.saveIfHigher(17.0);
    expect(await colorMatch.load(), 0.0);
    expect(await survival.load(), 17.0);
  });
  test('daily records do not carry over to the next day', () async {
    const monday = BestScoreStore(
      GameMode.dailyChallenge,
      challengeDateKey: '2026-10-19',
    );
    const tuesday = BestScoreStore(
      GameMode.dailyChallenge,
      challengeDateKey: '2026-10-20',
    );
    await monday.saveIfHigher(56.0);
    expect(await monday.load(), 56.0);
    expect(await tuesday.load(), 0.0);
  });

}

import 'package:color_dodge/storage/color_match_progress_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('starts with no progress', () async {
    final progress = await const ColorMatchProgressStore().load();

    expect(progress.runsPlayed, 0);
    expect(progress.bestScore, 0);
    expect(progress.highestLevel, 0);
  });

  test(
    'keeps bests and adds up totals across runs and store instances',
    () async {
      final first = await const ColorMatchProgressStore().recordRun(
        score: 14,
        level: 2,
        bestCombo: 6,
        matches: 11,
      );

      expect(first.isNewBestScore, isTrue);
      expect(first.isNewHighestLevel, isTrue);

      final second = await const ColorMatchProgressStore().recordRun(
        score: 9,
        level: 3,
        bestCombo: 4,
        matches: 8,
      );

      expect(second.isNewBestScore, isFalse);
      expect(second.isNewHighestLevel, isTrue);

      final progress = await const ColorMatchProgressStore().load();
      expect(progress.bestScore, 14);
      expect(progress.highestLevel, 3);
      expect(progress.bestCombo, 6);
      expect(progress.totalMatches, 19);
      expect(progress.runsPlayed, 2);
    },
  );

  test('does not share keys with the other modes', () async {
    SharedPreferences.setMockInitialValues({
      'color_dodge.best_score.colorMatch': 99.0,
    });

    final progress = await const ColorMatchProgressStore().load();

    expect(progress.bestScore, 0);
  });

  test('refuses impossible results', () async {
    expect(
      () => const ColorMatchProgressStore().recordRun(
        score: -1,
        level: 1,
        bestCombo: 0,
        matches: 0,
      ),
      throwsArgumentError,
    );
    expect(
      () => const ColorMatchProgressStore().recordRun(
        score: 0,
        level: 0,
        bestCombo: 0,
        matches: 0,
      ),
      throwsArgumentError,
    );
  });
}

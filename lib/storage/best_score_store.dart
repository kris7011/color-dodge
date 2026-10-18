import 'package:shared_preferences/shared_preferences.dart';

import '../game/game_mode.dart';

/// Stores each game mode's best score locally across app launches.
class BestScoreStore {
  const BestScoreStore(this.mode);

  final GameMode mode;

  String get _key => 'color_dodge.best_score.${mode.name}';

  Future<double> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_key) ?? 0.0;
  }

  Future<void> saveIfHigher(double score) async {
    if (!score.isFinite || score < 0.0) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final previousBest = prefs.getDouble(_key) ?? 0.0;

    if (score > previousBest) {
      await prefs.setDouble(_key, score);
    }
  }
}

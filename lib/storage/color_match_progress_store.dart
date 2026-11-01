import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';

/// Color Match progress kept on the device across runs and app launches.
class ColorMatchProgress {
  const ColorMatchProgress({
    this.bestScore = 0,
    this.highestLevel = 0,
    this.bestCombo = 0,
    this.totalMatches = 0,
    this.runsPlayed = 0,
  });

  final int bestScore;
  final int highestLevel;
  final int bestCombo;
  final int totalMatches;
  final int runsPlayed;
}

/// What a finished run changed in the stored progress.
class ColorMatchRunRecord {
  const ColorMatchRunRecord({
    required this.progress,
    required this.isNewBestScore,
    required this.isNewHighestLevel,
  });

  final ColorMatchProgress progress;
  final bool isNewBestScore;
  final bool isNewHighestLevel;
}

class ColorMatchProgressStore {
  const ColorMatchProgressStore();

  static const String _prefix = 'color_dodge.color_match';

  Future<ColorMatchProgress> load() async {
    final prefs = await SharedPreferences.getInstance();

    return ColorMatchProgress(
      bestScore: prefs.getInt('$_prefix.best_score') ?? 0,
      highestLevel: prefs.getInt('$_prefix.highest_level') ?? 0,
      bestCombo: prefs.getInt('$_prefix.best_combo') ?? 0,
      totalMatches: prefs.getInt('$_prefix.total_matches') ?? 0,
      runsPlayed: prefs.getInt('$_prefix.runs_played') ?? 0,
    );
  }

  /// Adds a finished run: bests only go up, totals accumulate.
  Future<ColorMatchRunRecord> recordRun({
    required int score,
    required int level,
    required int bestCombo,
    required int matches,
  }) async {
    if (score < 0 || level < 1 || bestCombo < 0 || matches < 0) {
      throw ArgumentError('A run cannot have negative results.');
    }

    final previous = await load();
    final progress = ColorMatchProgress(
      bestScore: math.max(previous.bestScore, score),
      highestLevel: math.max(previous.highestLevel, level),
      bestCombo: math.max(previous.bestCombo, bestCombo),
      totalMatches: previous.totalMatches + matches,
      runsPlayed: previous.runsPlayed + 1,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_prefix.best_score', progress.bestScore);
    await prefs.setInt('$_prefix.highest_level', progress.highestLevel);
    await prefs.setInt('$_prefix.best_combo', progress.bestCombo);
    await prefs.setInt('$_prefix.total_matches', progress.totalMatches);
    await prefs.setInt('$_prefix.runs_played', progress.runsPlayed);

    return ColorMatchRunRecord(
      progress: progress,
      isNewBestScore: score > previous.bestScore,
      isNewHighestLevel: level > previous.highestLevel,
    );
  }
}

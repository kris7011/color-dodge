import 'dart:math' as math;
import 'dart:ui' show Color;

/// One colour of the Color Match palette. Each colour also has its own symbol,
/// so the mode can be played without telling the colours apart.
class MatchColor {
  const MatchColor(this.name, this.color, this.symbol);

  final String name;
  final Color color;
  final String symbol;
}

/// The rules of Color Match, independent of rendering and timing.
///
/// Rows of five coloured blocks fall towards the player. Passing through a
/// block of the player's own colour is a match; any other colour costs a life.
/// Matches build a combo multiplier, and every [matchesPerColor] matches the
/// player's colour changes. Levels raise the speed, add a fourth colour and
/// reduce the number of matching lanes.
class ColorMatchRules {
  ColorMatchRules({int? seed}) : _random = math.Random(seed) {
    _currentColor = _random.nextInt(colorsForLevel(1));
    _nextColor = _pickNextColor();
  }

  static const List<MatchColor> palette = [
    MatchColor('Blue', Color(0xFF3485FF), '●'),
    MatchColor('Green', Color(0xFF2FD38A), '▲'),
    MatchColor('Orange', Color(0xFFFF9F1C), '■'),
    MatchColor('Pink', Color(0xFFFF4D9A), '◆'),
  ];

  static const int laneCount = 5;
  static const int startingLives = 3;
  static const int matchesPerColor = 6;
  static const int matchesPerLevel = 8;
  static const int pointsPerMatch = 1;

  final math.Random _random;

  int score = 0;
  int lives = startingLives;
  int combo = 0;
  int bestCombo = 0;
  int matches = 0;
  int misses = 0;
  int rowsPassed = 0;
  int matchesSinceColorChange = 0;

  late int _currentColor;
  late int _nextColor;
  Set<int> _lastMatchingLanes = {};

  bool get isOver => lives <= 0;

  int get level => 1 + matches ~/ matchesPerLevel;

  MatchColor get currentColor => palette[_currentColor];

  int get currentColorIndex => _currentColor;

  MatchColor get nextColor => palette[_nextColor];

  int get matchesUntilColorChange => matchesPerColor - matchesSinceColorChange;

  /// The combo multiplier for the next match: x1, x2 from three matches in a row, x3 from six.
  int get multiplier => combo >= 6 ? 3 : (combo >= 3 ? 2 : 1);

  static int colorsForLevel(int level) => level >= 3 ? 4 : 3;

  static int matchingLanesForLevel(int level) => level >= 4 ? 1 : 2;

  /// Rows fall faster each level, capped so the game stays readable.
  static double rowSpeedForLevel(int level) =>
      math.min(170.0 + (level - 1) * 28.0, 360.0);

  /// Colours for the five lanes of the next row.
  ///
  /// At least one lane always has the player's colour, and that lane is at
  /// most two lanes from every matching lane of the previous row, so whichever
  /// match the player took, the next one is close. With five lanes such a lane
  /// always exists.
  List<int> nextRow() {
    final colorCount = colorsForLevel(level);
    final reachable = [
      for (var lane = 0; lane < laneCount; lane++)
        if (_lastMatchingLanes.every(
          (previous) => (lane - previous).abs() <= 2,
        ))
          lane,
    ];

    final matchingLanes = <int>{reachable[_random.nextInt(reachable.length)]};
    final wanted = matchingLanesForLevel(level);

    while (matchingLanes.length < wanted) {
      matchingLanes.add(_random.nextInt(laneCount));
    }

    final otherColors = [
      for (var index = 0; index < colorCount; index++)
        if (index != _currentColor) index,
    ];

    final row = [
      for (var lane = 0; lane < laneCount; lane++)
        matchingLanes.contains(lane)
            ? _currentColor
            : otherColors[_random.nextInt(otherColors.length)],
    ];

    _lastMatchingLanes = matchingLanes;

    return row;
  }

  /// Keep falling rows playable when the player's colour changes after they
  /// were spawned. Swap old/new colours rather than replacing arbitrary blocks:
  /// this preserves the matching lanes and their reachability.
  void retargetPendingRow(List<int> row, int previousColorIndex) {
    if (previousColorIndex == _currentColor) {
      return;
    }

    for (var lane = 0; lane < row.length; lane++) {
      if (row[lane] == previousColorIndex) {
        row[lane] = _currentColor;
      } else if (row[lane] == _currentColor) {
        row[lane] = previousColorIndex;
      }
    }
  }


  PassResult pass(int colorIndex) {
    if (isOver) {
      throw StateError('The run is over.');
    }

    rowsPassed++;

    if (colorIndex != _currentColor) {
      lives--;
      misses++;
      combo = 0;

      return PassResult(
        matched: false,
        points: 0,
        livesLeft: lives,
        isOver: isOver,
      );
    }

    final levelBefore = level;
    final points = pointsPerMatch * multiplier;

    score += points;
    combo++;
    bestCombo = math.max(bestCombo, combo);
    matches++;
    matchesSinceColorChange++;

    MatchColor? newColor;

    if (matchesSinceColorChange >= matchesPerColor) {
      _currentColor = _nextColor;
      _nextColor = _pickNextColor();
      matchesSinceColorChange = 0;
      newColor = currentColor;
    }

    return PassResult(
      matched: true,
      points: points,
      livesLeft: lives,
      isOver: false,
      newColor: newColor,
      levelUp: level > levelBefore ? level : null,
    );
  }

  int _pickNextColor() {
    final colorCount = colorsForLevel(level);
    final options = [
      for (var index = 0; index < colorCount; index++)
        if (index != _currentColor) index,
    ];

    return options[_random.nextInt(options.length)];
  }
}

class PassResult {
  const PassResult({
    required this.matched,
    required this.points,
    required this.livesLeft,
    required this.isOver,
    this.newColor,
    this.levelUp,
  });

  final bool matched;
  final int points;
  final int livesLeft;
  final bool isOver;

  /// Set when this match changed the player's colour.
  final MatchColor? newColor;

  /// The new level when this match reached one.
  final int? levelUp;
}

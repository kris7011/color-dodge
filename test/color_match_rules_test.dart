import 'package:color_dodge/game/color_match/color_match_rules.dart';
import 'package:flutter_test/flutter_test.dart';

int _otherColour(ColorMatchRules rules) =>
    (rules.currentColorIndex + 1) % ColorMatchRules.colorsForLevel(rules.level);

void main() {
  test('the same seed gives the same course', () {
    final first = ColorMatchRules(seed: 7);
    final second = ColorMatchRules(seed: 7);

    expect(first.currentColorIndex, second.currentColorIndex);
    for (var i = 0; i < 20; i++) {
      expect(first.nextRow(), second.nextRow());
    }
  });

  test('every row has the player colour close to every previous match', () {
    final rules = ColorMatchRules(seed: 3);
    var previousMatchingLanes = <int>[];

    for (var i = 0; i < 300; i++) {
      final row = rules.nextRow();
      final matchingLanes = [
        for (var lane = 0; lane < row.length; lane++)
          if (row[lane] == rules.currentColorIndex) lane,
      ];

      expect(row, hasLength(ColorMatchRules.laneCount));
      expect(
        matchingLanes,
        hasLength(ColorMatchRules.matchingLanesForLevel(rules.level)),
      );
      expect(
        row.every(
          (colour) => colour < ColorMatchRules.colorsForLevel(rules.level),
        ),
        isTrue,
      );

      // Whichever matching lane the player took last time, a match is at most two lanes away.
      for (final previous in previousMatchingLanes) {
        expect(
          matchingLanes.any((lane) => (lane - previous).abs() <= 2),
          isTrue,
          reason:
              'row $i: no match within two lanes of $previous in $matchingLanes',
        );
      }

      previousMatchingLanes = matchingLanes;
      rules.pass(rules.currentColorIndex);
    }
  });

  test('already-spawned rows stay playable after colour changes, even at level four', () {
    for (final seed in [0, 3, 7, 42, 999]) {
      final rules = ColorMatchRules(seed: seed);

      // Six consecutive colour changes also cross the level-four boundary,
      // where only one matching lane is allowed in newly spawned rows.
      for (var phase = 0; phase < 6; phase++) {
        final previousColor = rules.currentColorIndex;
        final pending = List.generate(4, (_) => rules.nextRow());
        final originals = pending.map((row) => List<int>.of(row)).toList();

        for (var match = 0; match < ColorMatchRules.matchesPerColor; match++) {
          expect(rules.pass(rules.currentColorIndex).matched, isTrue);
        }

        expect(rules.currentColorIndex, isNot(previousColor));

        for (var i = 0; i < pending.length; i++) {
          rules.retargetPendingRow(pending[i], previousColor);

          final originalMatches =
              originals[i].where((color) => color == previousColor).length;
          final newMatches = pending[i]
              .where((color) => color == rules.currentColorIndex)
              .length;
          expect(newMatches, originalMatches, reason: 'seed=$seed phase=$phase row=$i');
          expect(newMatches, greaterThan(0));

          for (var lane = 0; lane < ColorMatchRules.laneCount; lane++) {
            if (originals[i][lane] == previousColor) {
              expect(pending[i][lane], rules.currentColorIndex);
            }
          }
        }
      }
    }
  });


    final rules = ColorMatchRules(seed: 1);
    final points = [
      for (var i = 0; i < 7; i++) rules.pass(rules.currentColorIndex).points,
    ];

    expect(points, [1, 1, 1, 2, 2, 2, 3]);
    expect(rules.score, 12);
    expect(rules.combo, 7);
    expect(rules.bestCombo, 7);
    expect(rules.matches, 7);
  });

  test('a wrong colour costs a life and resets the combo', () {
    final rules = ColorMatchRules(seed: 1);
    rules.pass(rules.currentColorIndex);
    rules.pass(rules.currentColorIndex);

    final result = rules.pass(_otherColour(rules));

    expect(result.matched, isFalse);
    expect(result.points, 0);
    expect(result.livesLeft, 2);
    expect(rules.combo, 0);
    expect(rules.bestCombo, 2);
    expect(rules.misses, 1);
    expect(rules.score, 2);
  });

  test('the run ends when the last life is lost', () {
    final rules = ColorMatchRules(seed: 1);

    rules.pass(_otherColour(rules));
    rules.pass(_otherColour(rules));
    final last = rules.pass(_otherColour(rules));

    expect(last.isOver, isTrue);
    expect(rules.isOver, isTrue);
    expect(() => rules.pass(rules.currentColorIndex), throwsStateError);
  });

  test('the colour changes to the announced next colour every six matches', () {
    final rules = ColorMatchRules(seed: 5);
    final startColour = rules.currentColor;
    final announced = rules.nextColor;

    for (var i = 0; i < ColorMatchRules.matchesPerColor - 1; i++) {
      expect(rules.pass(rules.currentColorIndex).newColor, isNull);
    }

    expect(rules.matchesUntilColorChange, 1);

    final change = rules.pass(rules.currentColorIndex);

    expect(change.newColor, announced);
    expect(rules.currentColor, announced);
    expect(rules.currentColor, isNot(startColour));
    expect(rules.matchesUntilColorChange, ColorMatchRules.matchesPerColor);
  });

  test('levels rise every eight matches and make the game harder', () {
    final rules = ColorMatchRules(seed: 9);
    final levelUps = <int>[];

    for (var i = 0; i < 3 * ColorMatchRules.matchesPerLevel; i++) {
      final levelUp = rules.pass(rules.currentColorIndex).levelUp;
      if (levelUp != null) {
        levelUps.add(levelUp);
      }
    }

    expect(levelUps, [2, 3, 4]);
    expect(rules.level, 4);
    expect(ColorMatchRules.colorsForLevel(2), 3);
    expect(ColorMatchRules.colorsForLevel(3), 4);
    expect(ColorMatchRules.matchingLanesForLevel(3), 2);
    expect(ColorMatchRules.matchingLanesForLevel(4), 1);
    expect(
      ColorMatchRules.rowSpeedForLevel(4),
      greaterThan(ColorMatchRules.rowSpeedForLevel(1)),
    );
    expect(ColorMatchRules.rowSpeedForLevel(50), 360);
  });
}

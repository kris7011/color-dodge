import 'package:color_dodge/game/color_dodge_game.dart';
import 'package:flame/events.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

KeyDownEvent _down(LogicalKeyboardKey key, PhysicalKeyboardKey physical) =>
    KeyDownEvent(
      logicalKey: key,
      physicalKey: physical,
      timeStamp: Duration.zero,
    );

void main() {
  test('arrow keys and A/D move one lane at a time, clamped to the arena', () {
    final game = ColorDodgeGame(randomSeed: 42);
    expect(game.selectedLane, 2);

    expect(
      game.onKeyEvent(
        _down(LogicalKeyboardKey.arrowLeft, PhysicalKeyboardKey.arrowLeft),
        {LogicalKeyboardKey.arrowLeft},
      ),
      KeyEventResult.handled,
    );
    expect(game.selectedLane, 1);

    for (var i = 0; i < 5; i++) {
      game.onKeyEvent(
        _down(LogicalKeyboardKey.keyA, PhysicalKeyboardKey.keyA),
        {LogicalKeyboardKey.keyA},
      );
    }
    expect(game.selectedLane, 0);

    game.onKeyEvent(
      _down(LogicalKeyboardKey.arrowRight, PhysicalKeyboardKey.arrowRight),
      {LogicalKeyboardKey.arrowRight},
    );
    expect(game.selectedLane, 1);

    for (var i = 0; i < 10; i++) {
      game.onKeyEvent(
        _down(LogicalKeyboardKey.keyD, PhysicalKeyboardKey.keyD),
        {LogicalKeyboardKey.keyD},
      );
    }
    expect(game.selectedLane, 4);
  });

  test('unrelated keys and key releases do not move the player', () {
    final game = ColorDodgeGame(randomSeed: 1);
    expect(
      game.onKeyEvent(
        _down(LogicalKeyboardKey.space, PhysicalKeyboardKey.space),
        {LogicalKeyboardKey.space},
      ),
      KeyEventResult.ignored,
    );
    expect(
      game.onKeyEvent(
        KeyUpEvent(
          logicalKey: LogicalKeyboardKey.keyA,
          physicalKey: PhysicalKeyboardKey.keyA,
          timeStamp: Duration.zero,
        ),
        const {},
      ),
      KeyEventResult.ignored,
    );
    expect(game.selectedLane, 2);
  });
}

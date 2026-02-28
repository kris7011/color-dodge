import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../color_dodge_game.dart';
import 'player.dart';

class Obstacle extends RectangleComponent
    with CollisionCallbacks, HasGameReference<ColorDodgeGame> {
  final double fallSpeed;

  Obstacle({required this.fallSpeed, required double width})
    : super(
        size: Vector2(width, 22),
        paint: Paint()..color = Colors.redAccent,
        anchor: Anchor.topLeft,
      );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);

    position.y += fallSpeed * dt;

    if (position.y > game.size.y + 50) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is Player) {
      game.gameOver();
    }
  }
}

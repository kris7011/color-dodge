import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

class Player extends CircleComponent with DragCallbacks, CollisionCallbacks {
  Player()
    : super(
        radius: 18,
        paint: Paint()..color = Colors.blue,
        anchor: Anchor.center,
      );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    position.x += event.localDelta.x;
  }

  void clampToGameSize(Vector2 gameSize) {
    final minX = radius;
    final maxX = gameSize.x - radius;

    if (position.x < minX) position.x = minX;
    if (position.x > maxX) position.x = maxX;
  }
}

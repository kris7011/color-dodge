import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class Player extends CircleComponent {
  Player()
    : super(
        radius: 18,
        paint: Paint()..color = Colors.blue,
        anchor: Anchor.center,
      );

  void clampToGameSize(Vector2 gameSize) {
    final minX = radius;
    final maxX = gameSize.x - radius;

    if (position.x < minX) position.x = minX;
    if (position.x > maxX) position.x = maxX;
  }
}

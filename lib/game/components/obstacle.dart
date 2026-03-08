import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class Obstacle extends RectangleComponent {
  static final Paint _activePaint = Paint()..color = Colors.redAccent;

  bool isActive = false;
  double fallSpeed = 0;

  Obstacle() : super(anchor: Anchor.topLeft, size: Vector2.zero());

  void activate({
    required double x,
    required double y,
    required double width,
    required double height,
    required double newFallSpeed,
  }) {
    isActive = true;
    fallSpeed = newFallSpeed;
    position.setValues(x, y);
    size.setValues(width, height);
    paint = _activePaint;
  }

  void deactivate() {
    isActive = false;
    fallSpeed = 0;
    position.setValues(-1000, -1000);
    size.setValues(0, 0);
  }

  void step(double dt) {
    if (!isActive) return;
    position.y += fallSpeed * dt;
  }

  bool isOffScreen(double screenHeight) {
    return isActive && position.y > screenHeight + 60;
  }

  @override
  void render(Canvas canvas) {
    if (!isActive) return;
    super.render(canvas);
  }
}

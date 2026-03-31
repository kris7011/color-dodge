import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class Obstacle extends PositionComponent {
  bool isActive = false;
  bool nearMissRegistered = false;

  double fallSpeed = 0;
  double horizontalAmplitude = 0;
  double horizontalSpeed = 0;

  double _baseX = 0;
  double _time = 0;

  Color _color = const Color(0xFF9E2E2E);

  final Paint _paint = Paint();
  final Paint _glowPaint = Paint();

  Obstacle() : super(anchor: Anchor.topLeft, size: Vector2.zero());

  void activate({
    required double x,
    required double y,
    required double width,
    required double height,
    required double newFallSpeed,
    required Color color,
    double newHorizontalAmplitude = 0,
    double newHorizontalSpeed = 0,
  }) {
    isActive = true;
    nearMissRegistered = false;

    fallSpeed = newFallSpeed;
    horizontalAmplitude = newHorizontalAmplitude;
    horizontalSpeed = newHorizontalSpeed;

    _baseX = x;
    _time = 0;
    _color = color;

    position.setValues(x, y);
    size.setValues(width, height);
  }

  void deactivate() {
    isActive = false;
    nearMissRegistered = false;

    fallSpeed = 0;
    horizontalAmplitude = 0;
    horizontalSpeed = 0;

    position.setValues(-1000, -1000);
    size.setValues(0, 0);
  }

  void step(double dt) {
    if (!isActive) return;

    _time += dt;
    position.y += fallSpeed * dt;

    if (horizontalAmplitude > 0 && horizontalSpeed > 0) {
      position.x =
          _baseX + math.sin(_time * horizontalSpeed) * horizontalAmplitude;
    }
  }

  bool isOffScreen(double screenHeight) {
    return isActive && position.y > screenHeight + 80;
  }

  @override
  void render(Canvas canvas) {
    if (!isActive || size.x <= 0 || size.y <= 0) {
      return;
    }

    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));

    _glowPaint
      ..color = _color.withValues(alpha: 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    _paint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [_color.withValues(alpha: 0.95), _color.withValues(alpha: 0.78)],
    ).createShader(rect);

    canvas.drawRRect(rrect, _glowPaint);
    canvas.drawRRect(rrect, _paint);

    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.10);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(1, 1, size.x - 2, math.max(2, size.y * 0.22)),
        const Radius.circular(7),
      ),
      highlightPaint,
    );
  }
}

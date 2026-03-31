import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class Player extends PositionComponent {
  static const double _radius = 18.0;

  double get radius => _radius;

  Player() : super(anchor: Anchor.center, size: Vector2.all(_radius * 2));

  void clampToGameSize(Vector2 gameSize) {
    final minX = radius;
    final maxX = gameSize.x - radius;

    if (position.x < minX) {
      position.x = minX;
    }

    if (position.x > maxX) {
      position.x = maxX;
    }
  }

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromCircle(
      center: Offset(radius, radius),
      radius: radius,
    );

    final glowPaint = Paint()
      ..color = const Color(0xFF63B3FF).withValues(alpha: 0.24)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    final fillPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFBFE4FF), Color(0xFF5CAEFF), Color(0xFF2266D7)],
        stops: [0.0, 0.55, 1.0],
      ).createShader(rect);

    final innerHighlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.18);

    canvas.drawCircle(Offset(radius, radius), radius + 2, glowPaint);
    canvas.drawCircle(Offset(radius, radius), radius, fillPaint);
    canvas.drawCircle(
      Offset(radius - 5, radius - 6),
      radius * 0.28,
      innerHighlight,
    );
  }
}

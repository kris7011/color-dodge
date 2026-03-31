import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class FxParticle extends CircleComponent {
  final Vector2 velocity;
  final double lifetime;
  final double decay;

  double _elapsed = 0;

  FxParticle({
    required super.position,
    required super.radius,
    required this.velocity,
    required this.lifetime,
    required Color color,
    this.decay = 0.94,
  }) : super(anchor: Anchor.center, paint: Paint()..color = color);

  @override
  void update(double dt) {
    super.update(dt);

    _elapsed += dt;
    if (_elapsed >= lifetime) {
      removeFromParent();
      return;
    }

    position += velocity * dt;
    velocity.scale(decay);

    final remaining = (1 - (_elapsed / lifetime)).clamp(0.0, 1.0);
    paint.color = paint.color.withValues(alpha: remaining);
  }
}

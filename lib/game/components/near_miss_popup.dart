import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class NearMissPopup extends PositionComponent {
  final String text;
  final Color color;

  NearMissPopup({
    required Vector2 position,
    this.text = '+0.50',
    this.color = const Color(0xFF6CFFB5),
  }) : super(position: position, anchor: Anchor.center);

  late final TextComponent _label;

  final double _life = 0.65;
  double _t = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _label = TextComponent(
      text: text,
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: color,
          shadows: const [
            Shadow(blurRadius: 10, offset: Offset(0, 2), color: Colors.black54),
          ],
        ),
      ),
    );

    add(_label);
  }

  @override
  void update(double dt) {
    super.update(dt);

    _t += dt;
    position.y -= 40 * dt;

    final left = (_life - _t).clamp(0.0, _life);
    final a01 = (left / _life);

    final alpha = (a01 * 255.0).round().clamp(0, 255);
    final newColor = color.withValues(alpha: alpha.toDouble());

    _label.textRenderer = TextPaint(
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: newColor,
        shadows: const [
          Shadow(blurRadius: 10, offset: Offset(0, 2), color: Colors.black54),
        ],
      ),
    );

    if (_t >= _life) {
      removeFromParent();
    }
  }
}

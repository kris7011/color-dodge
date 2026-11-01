import 'package:flutter/material.dart';

/// The dark gradient and the five lane lines behind the game.
class ArenaBackground extends StatelessWidget {
  const ArenaBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ArenaPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _ArenaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF101726), Color(0xFF0B0F17)],
      ).createShader(rect);

    canvas.drawRect(rect, bgPaint);

    const sidePadding = 14.0;
    const laneCount = 5;
    final laneWidth = (size.width - (sidePadding * 2)) / laneCount;

    final linePaint = Paint()
      ..color = const Color(0x10FFFFFF)
      ..strokeWidth = 1;

    for (int i = 0; i <= laneCount; i++) {
      final x = sidePadding + (laneWidth * i);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

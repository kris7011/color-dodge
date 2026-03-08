import 'package:color_dodge/game/game_mode.dart';
import 'package:color_dodge/ui/game_screen.dart';
import 'package:flutter/material.dart';

Color _a(Color c, double opacity) {
  return c.withValues(alpha: opacity.clamp(0.0, 1.0));
}

class ModeSelectScreen extends StatelessWidget {
  const ModeSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF07070B), Color(0xFF0F1020), Color(0xFF07070B)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: Stack(
                    children: const [
                      _GlowBlob(
                        alignment: Alignment(-1.1, -0.9),
                        size: 260,
                        opacity: 0.06,
                      ),
                      _GlowBlob(
                        alignment: Alignment(1.2, -0.6),
                        size: 220,
                        opacity: 0.05,
                      ),
                      _GlowBlob(
                        alignment: Alignment(0.9, 1.1),
                        size: 260,
                        opacity: 0.05,
                      ),
                    ],
                  ),
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isCompactHeight = constraints.maxHeight < 700;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 36,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Color Dodge',
                              style: t.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Choose a mode',
                              style: t.bodyMedium?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                            SizedBox(height: isCompactHeight ? 14 : 18),
                            _ModeCard(
                              title: 'Survival',
                              subtitle:
                                  'Dodge falling blocks.\nLast as long as you can.',
                              icon: Icons.timer,
                              accent: const Color(0xFF4DA3FF),
                              badgeText: 'Recommended',
                              compact: isCompactHeight,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const GameScreen(mode: GameMode.survival),
                                ),
                              ),
                            ),
                            SizedBox(height: isCompactHeight ? 10 : 14),
                            _ModeCard(
                              title: 'Color Match',
                              subtitle:
                                  'Fast color swaps.\nCombos and multipliers.',
                              icon: Icons.palette,
                              accent: const Color(0xFFFF5DA2),
                              badgeText: 'Coming soon',
                              compact: isCompactHeight,
                              onTap: () => showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Coming soon'),
                                  content: const Text(
                                    'Color Match mode lands in a future update.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (!isCompactHeight) const SizedBox(height: 16),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: isCompactHeight ? 8 : 10,
                              ),
                              decoration: BoxDecoration(
                                color: _a(const Color(0xFF0B0C14), 0.70),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _a(Colors.white, 0.10),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.swipe,
                                    color: Colors.white70,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Tip: Drag left/right to move.',
                                      style: t.bodySmall?.copyWith(
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final String badgeText;
  final VoidCallback onTap;
  final bool compact;

  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.badgeText,
    required this.onTap,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: EdgeInsets.all(compact ? 14 : 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _a(Colors.white, 0.10)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _a(Colors.white, 0.06),
              _a(Colors.white, 0.04),
              _a(Colors.white, 0.03),
            ],
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 24,
              spreadRadius: 0,
              offset: const Offset(0, 10),
              color: _a(Colors.black, 0.35),
            ),
            BoxShadow(
              blurRadius: 30,
              spreadRadius: 0,
              offset: const Offset(0, 10),
              color: _a(accent, 0.10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: compact ? 46 : 52,
              height: compact ? 46 : 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_a(accent, 0.35), _a(accent, 0.12)],
                ),
                border: Border.all(color: _a(accent, 0.35)),
              ),
              child: Icon(
                icon,
                size: compact ? 22 : 24,
                color: _a(Colors.white, 0.90),
              ),
            ),
            SizedBox(width: compact ? 12 : 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: (compact ? t.titleMedium : t.titleLarge)
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                                color: Colors.white,
                              ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: _Badge(
                          text: badgeText,
                          accent: accent,
                          compact: compact,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? 6 : 8),
                  Text(
                    subtitle,
                    style: t.bodyMedium?.copyWith(
                      color: Colors.white70,
                      height: 1.25,
                      fontSize: compact ? 13 : null,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              Icons.chevron_right,
              size: compact ? 20 : 24,
              color: _a(Colors.white, 0.35),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color accent;
  final bool compact;

  const _Badge({
    required this.text,
    required this.accent,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Container(
      constraints: BoxConstraints(maxWidth: compact ? 110 : 130),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 5 : 6,
      ),
      decoration: BoxDecoration(
        color: _a(accent, 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _a(accent, 0.35)),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: t.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: compact ? 10.5 : null,
        ),
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final Alignment alignment;
  final double size;
  final double opacity;

  const _GlowBlob({
    required this.alignment,
    required this.size,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [_a(Colors.white, opacity), Colors.transparent],
            stops: const [0.0, 1.0],
          ),
        ),
      ),
    );
  }
}

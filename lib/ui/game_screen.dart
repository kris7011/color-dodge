
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/color_dodge_game.dart' as game_file;
import '../game/game_mode.dart';

class GameScreen extends StatelessWidget {
  final GameMode mode;

  const GameScreen({super.key, required this.mode});

  @override
  Widget build(BuildContext context) {
    final game = game_file.ColorDodgeGame(mode: mode);

    return Scaffold(
      body: GameWidget<game_file.ColorDodgeGame>(
        game: game,
        initialActiveOverlays: const ['Hud'],
        overlayBuilderMap: {
          'Hud': (ctx, g) => _HudOverlay(game: g),
          'GameOver': (ctx, g) => _GameOverOverlay(game: g),
        },
      ),
    );
  }
}

class _HudOverlay extends StatelessWidget {
  final game_file.ColorDodgeGame game;

  const _HudOverlay({required this.game});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    final style = t.labelMedium?.copyWith(
      color: Colors.white.withValues(alpha: 0.88),
      fontWeight: FontWeight.w800,
      letterSpacing: 0.1,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
        child: Align(
          alignment: Alignment.topLeft,
          child: ValueListenableBuilder<game_file.HudState>(
            valueListenable: game.hud,
            builder: (context, hud, _) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B0C14).withValues(alpha: 0.70),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _HudLabelValue(
                      label: 'SCORE',
                      value: hud.score.toStringAsFixed(1),
                      valueWidth: 52,
                      style: style,
                    ),
                    const SizedBox(width: 8),
                    _Dot(style: style),
                    const SizedBox(width: 8),
                    _HudLabelValue(
                      label: 'BEST',
                      value: hud.best.toStringAsFixed(1),
                      valueWidth: 52,
                      style: style,
                    ),
                    const SizedBox(width: 8),
                    _Dot(style: style),
                    const SizedBox(width: 8),
                    _HudLabelValue(
                      label: 'NM',
                      value: hud.nearMisses.toString(),
                      valueWidth: 24,
                      style: style,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final TextStyle? style;

  const _Dot({required this.style});

  @override
  Widget build(BuildContext context) {
    return Text(
      '•',
      style: style?.copyWith(color: Colors.white.withValues(alpha: 0.45)),
    );
  }
}

class _HudLabelValue extends StatelessWidget {
  final String label;
  final String value;
  final double valueWidth;
  final TextStyle? style;

  const _HudLabelValue({
    required this.label,
    required this.value,
    required this.valueWidth,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = style?.copyWith(
      color: Colors.white.withValues(alpha: 0.55),
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
      fontSize: (style?.fontSize ?? 13) - 1,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label ', style: labelStyle),
        SizedBox(
          width: valueWidth,
          child: Text(value, style: style, textAlign: TextAlign.right),
        ),
      ],
    );
  }
}

class _GameOverOverlay extends StatelessWidget {
  final game_file.ColorDodgeGame game;

  const _GameOverOverlay({required this.game});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: Center(
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(16),
          ),
          child: ValueListenableBuilder<game_file.HudState>(
            valueListenable: game.hud,
            builder: (context, hud, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Game Over',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text('Score: ${hud.score.toStringAsFixed(1)}'),
                  const SizedBox(height: 6),
                  Text('Best: ${hud.best.toStringAsFixed(1)}'),
                  const SizedBox(height: 6),
                  Text('NM: ${hud.nearMisses}'),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => game.resetRun(),
                      child: const Text('Retry'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Back'),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

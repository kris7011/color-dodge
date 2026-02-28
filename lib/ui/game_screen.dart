import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../game/color_dodge_game.dart';
import 'mode_select_screen.dart';

class GameScreen extends StatelessWidget {
  final GameMode mode;

  const GameScreen({super.key, required this.mode});

  @override
  Widget build(BuildContext context) {
    final game = ColorDodgeGame(mode: mode);

    return Scaffold(
      body: GameWidget<ColorDodgeGame>(
        game: game,
        overlayBuilderMap: {
          'GameOver': (ctx, g) => _GameOverOverlay(game: g),
        },
      ),
    );
  }
}

class _GameOverOverlay extends StatelessWidget {
  final ColorDodgeGame game;
  const _GameOverOverlay({required this.game});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Game Over', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text('Score: ${game.scoreSeconds.toStringAsFixed(1)}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                game.resetRun();
                game.overlays.remove('GameOver');
                game.resumeEngine();
              },
              child: const Text('Retry'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}
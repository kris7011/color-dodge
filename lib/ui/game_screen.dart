import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/color_dodge_game.dart' as game_file;
import '../game/game_mode.dart';
import '../storage/best_score_store.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.mode});

  final GameMode mode;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final BestScoreStore _scoreStore = BestScoreStore(widget.mode);
  late final Future<double> _bestScoreFuture = _scoreStore.load();
  game_file.ColorDodgeGame? _game;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<double>(
      future: _bestScoreFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: Color(0xFF0B0F17),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final game = _game ??= game_file.ColorDodgeGame(
          gameMode: widget.mode,
          initialBestScore: snapshot.data ?? 0.0,
          onNewBestScore: (score) {
            unawaited(_scoreStore.saveIfHigher(score));
          },
        );

        return Scaffold(
          backgroundColor: const Color(0xFF0B0F17),
          body: Stack(
            children: [
              const Positioned.fill(child: _BackgroundLayer()),
              GameWidget<game_file.ColorDodgeGame>(
                game: game,
                initialActiveOverlays: const ['Hud'],
                overlayBuilderMap: {
                  'Hud': (ctx, g) => _HudOverlay(game: g),
                  'GameOver': (ctx, g) => _GameOverOverlay(game: g),
                },
              ),
              const Positioned.fill(
                child: IgnorePointer(child: _TopBottomVignette()),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BackgroundLayer extends StatelessWidget {
  const _BackgroundLayer();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BackgroundPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _BackgroundPainter extends CustomPainter {
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

class _TopBottomVignette extends StatelessWidget {
  const _TopBottomVignette();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x22000000), Color(0x00000000), Color(0x33000000)],
        ),
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _HudOverlay extends StatelessWidget {
  const _HudOverlay({required this.game});

  final game_file.ColorDodgeGame game;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 0, 0),
        child: Align(
          alignment: Alignment.topLeft,
          child: ValueListenableBuilder<game_file.HudState>(
            valueListenable: game.hud,
            builder: (context, hud, _) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Score ',
                    style: TextStyle(
                      color: Color(0x99FFFFFF),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    hud.score.toStringAsFixed(0),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      height: 1,
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

class _GameOverOverlay extends StatelessWidget {
  const _GameOverOverlay({required this.game});

  final game_file.ColorDodgeGame game;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xB20A0D12),
      child: Center(
        child: ValueListenableBuilder<game_file.HudState>(
          valueListenable: game.hud,
          builder: (context, hud, _) {
            final title = hud.isVictory ? 'Level Complete' : 'Game Over';

            return Container(
              width: 304,
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
              decoration: BoxDecoration(
                color: const Color(0xFF151C29),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0x18FFFFFF)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x55000000),
                    blurRadius: 24,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _GameOverRow(
                    label: 'Score',
                    value: hud.score.toStringAsFixed(0),
                  ),
                  const SizedBox(height: 8),
                  _GameOverRow(
                    label: 'Best',
                    value: hud.best.toStringAsFixed(0),
                  ),
                  const SizedBox(height: 8),
                  _GameOverRow(
                    label: 'Near misses',
                    value: hud.nearMisses.toString(),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: game.resetRun,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF11151D),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Play again',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Back',
                        style: TextStyle(color: Color(0xCCFFFFFF)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GameOverRow extends StatelessWidget {
  const _GameOverRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 14),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/color_match/color_match_game.dart';
import '../game/color_match/color_match_rules.dart';
import '../storage/color_match_progress_store.dart';
import 'arena_background.dart';

const _panelColour = Color(0xFF151C29);
const _mutedText = Color(0x99FFFFFF);

class ColorMatchScreen extends StatefulWidget {
  const ColorMatchScreen({
    super.key,
    this.store = const ColorMatchProgressStore(),
    this.seed,
    this.reduceFlashes = false,
  });

  final ColorMatchProgressStore store;

  /// Fixed seed for reproducible runs (tests); null gives a new course every run.
  final int? seed;
  final bool reduceFlashes;

  @override
  State<ColorMatchScreen> createState() => _ColorMatchScreenState();
}

class _ColorMatchScreenState extends State<ColorMatchScreen> {
  late final ColorMatchGame _game = ColorMatchGame(
    seed: widget.seed,
    reduceFlashes: widget.reduceFlashes,
    onRunFinished: _recordRun,
  );
  late final Future<ColorMatchProgress> _progress = widget.store.load();
  final ValueNotifier<ColorMatchRunRecord?> _lastRecord = ValueNotifier(null);

  // Built once: rebuilding a GameWidget re-applies its initial overlays, which
  // would bring the rules panel back on top of the results.
  late final Widget _gameWidget = GameWidget<ColorMatchGame>(
    game: _game,
    initialActiveOverlays: const ['ColorMatchHud', 'ColorMatchIntro'],
    overlayBuilderMap: {
      'ColorMatchHud': (context, game) => _Hud(game: game),
      'ColorMatchIntro': (context, game) => _Intro(
        progress: _progress,
        onStart: () {
          game.overlays.remove('ColorMatchIntro');
          game.start();
        },
      ),
      'ColorMatchOver': (context, game) =>
          _Results(game: game, record: _lastRecord),
    },
  );

  /// Saves the run; the results overlay listens to [_lastRecord], so no rebuild is needed.
  Future<void> _recordRun(ColorMatchRules rules) async {
    final record = await widget.store.recordRun(
      score: rules.score,
      level: rules.level,
      bestCombo: rules.bestCombo,
      matches: rules.matches,
    );

    if (mounted) {
      _lastRecord.value = record;
    }
  }

  @override
  void dispose() {
    _lastRecord.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F17),
      body: Stack(
        children: [
          const Positioned.fill(child: ArenaBackground()),
          _gameWidget,
        ],
      ),
    );
  }
}

class _Hud extends StatelessWidget {
  const _Hud({required this.game});

  final ColorMatchGame game;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ValueListenableBuilder<ColorMatchHud>(
        valueListenable: game.hud,
        builder: (context, hud, _) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: [
                Row(
                  children: [
                    _HudValue(
                      label: 'Score',
                      value: '${hud.score}',
                      key: const Key('hud-score'),
                    ),
                    const SizedBox(width: 14),
                    _HudValue(label: 'Level', value: '${hud.level}'),
                    const Spacer(),
                    Text(
                      List.generate(
                        ColorMatchRules.startingLives,
                        (i) => i < hud.lives ? '♥' : '♡',
                      ).join(' '),
                      key: const Key('hud-lives'),
                      style: const TextStyle(
                        color: Color(0xFFFF5C7A),
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Wraps on narrow phones instead of overflowing.
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _ColourChip(colour: hud.color, label: 'Match'),
                    Text(
                      'Next ${hud.nextColor.symbol} in ${hud.matchesUntilColorChange}',
                      style: const TextStyle(color: _mutedText, fontSize: 13),
                    ),
                    if (hud.combo > 0)
                      Text(
                        'Combo ${hud.combo}  x${hud.multiplier}',
                        style: const TextStyle(
                          color: Color(0xFFFFD166),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                  ],
                ),
                if (hud.message != null) ...[
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xCC151C29),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      hud.message!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HudValue extends StatelessWidget {
  const _HudValue({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '$label ',
          style: const TextStyle(
            color: _mutedText,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ColourChip extends StatelessWidget {
  const _ColourChip({required this.colour, required this.label});

  final MatchColor colour;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colour.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label ${colour.symbol} ${colour.name}',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xB20A0D12),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: 320,
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
            decoration: BoxDecoration(
              color: _panelColour,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0x18FFFFFF)),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: children),
          ),
        ),
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro({required this.progress, required this.onStart});

  final Future<ColorMatchProgress> progress;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      children: [
        const Text(
          'Color Match',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        for (final rule in const [
          'Steer into the block with your colour and symbol.',
          'Every match scores. 3 in a row = x2, 6 in a row = x3.',
          'Another colour costs a life. You have 3.',
          'Your colour changes every 6 matches. The HUD shows the next one.',
          'Levels get faster, add a colour and leave fewer matching lanes.',
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('•  ', style: TextStyle(color: _mutedText)),
                Expanded(
                  child: Text(
                    rule,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 4),
        const Text(
          'Move: drag, tap a lane, or ← → / A D',
          style: TextStyle(color: _mutedText, fontSize: 13),
        ),
        const SizedBox(height: 12),
        FutureBuilder<ColorMatchProgress>(
          future: progress,
          builder: (context, snapshot) {
            final value = snapshot.data;

            if (value == null || value.runsPlayed == 0) {
              return const Text(
                'First run: no records yet.',
                style: TextStyle(color: _mutedText),
              );
            }

            return Text(
              'Best ${value.bestScore} · Highest level ${value.highestLevel} · Best combo ${value.bestCombo}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _mutedText),
            );
          },
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(onPressed: onStart, child: const Text('Start')),
        ),
      ],
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.game, required this.record});

  final ColorMatchGame game;
  final ValueNotifier<ColorMatchRunRecord?> record;

  @override
  Widget build(BuildContext context) {
    final rules = game.rules;

    return _Panel(
      children: [
        const Text(
          'Out of lives',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        _ResultRow('Score', '${rules.score}'),
        _ResultRow('Level reached', '${rules.level}'),
        _ResultRow('Matches', '${rules.matches} of ${rules.rowsPassed}'),
        _ResultRow('Best combo', '${rules.bestCombo}'),
        const SizedBox(height: 10),
        ValueListenableBuilder<ColorMatchRunRecord?>(
          valueListenable: record,
          builder: (context, value, _) {
            if (value == null) {
              return const Text(
                'Saving progress...',
                style: TextStyle(color: _mutedText),
              );
            }

            return Column(
              children: [
                if (value.isNewBestScore) const _Highlight('New best score!'),
                if (value.isNewHighestLevel)
                  const _Highlight('New highest level!'),
                _ResultRow('Best score', '${value.progress.bestScore}'),
                _ResultRow('Runs played', '${value.progress.runsPlayed}'),
                _ResultRow('Total matches', '${value.progress.totalMatches}'),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              record.value = null;
              game.restart();
            },
            child: const Text('Play again'),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Back', style: TextStyle(color: Color(0xCCFFFFFF))),
        ),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: _mutedText, fontSize: 14)),
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
      ),
    );
  }
}

class _Highlight extends StatelessWidget {
  const _Highlight(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF6CFFB5),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

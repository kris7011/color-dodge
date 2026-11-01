import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../components/near_miss_popup.dart';
import 'color_match_rules.dart';

/// What the HUD shows; rebuilt after every change of the rules state.
class ColorMatchHud {
  const ColorMatchHud({
    required this.score,
    required this.lives,
    required this.combo,
    required this.multiplier,
    required this.level,
    required this.color,
    required this.nextColor,
    required this.matchesUntilColorChange,
    required this.isRunning,
    required this.isOver,
    this.message,
  });

  final int score;
  final int lives;
  final int combo;
  final int multiplier;
  final int level;
  final MatchColor color;
  final MatchColor nextColor;
  final int matchesUntilColorChange;
  final bool isRunning;
  final bool isOver;

  /// A short announcement such as a colour change or a new level.
  final String? message;
}

/// The Flame side of Color Match: falling rows, the player and feedback.
/// All rules (scoring, lives, colours, levels) live in [ColorMatchRules].
class ColorMatchGame extends FlameGame
    with DragCallbacks, TapCallbacks, KeyboardEvents {
  ColorMatchGame({this.seed, this.onRunFinished})
    : rules = ColorMatchRules(seed: seed);

  final int? seed;
  final ValueChanged<ColorMatchRules>? onRunFinished;

  ColorMatchRules rules;

  late final ValueNotifier<ColorMatchHud> hud = ValueNotifier(_hudState());

  static const double _sidePadding = 14;
  static const double _laneGap = 8;
  static const double _rowHeight = 44;
  static const double _rowSpacing = 210;
  static const double _playerSize = 40;
  static const double _playerBottomMargin = 110;
  static const double _playerLaneSpeed = 980;
  static const double _messageDuration = 1.6;
  static const double _flashDuration = 0.3;

  final List<_ColorRow> _rows = [];
  late final _MatchPlayer _player;

  bool _isRunning = false;
  int _targetLane = 2;
  double _timeSinceSpawn = 0;
  double _messageTimeLeft = 0;
  double _flashTimeLeft = 0;
  String? _message;

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _player = _MatchPlayer(rules.currentColor)
      ..size = Vector2.all(_playerSize)
      ..position = Vector2(
        _laneLeft(_targetLane),
        size.y - _playerBottomMargin,
      );

    add(_player);
  }

  /// Rows still on their way to the player, nearest first: their lane colours and
  /// remaining distance. Read-only; used by the on-device demo test to steer.
  @visibleForTesting
  List<({List<int> colors, double distance})> get approachingRows {
    final playerCenter = _player.y + _player.height / 2;

    return [
      for (final row in _rows)
        if (row.resolvedLane == null)
          (
            colors: row.colors,
            distance: playerCenter - (row.y + row.height / 2),
          ),
    ]..sort((a, b) => a.distance.compareTo(b.distance));
  }

  @visibleForTesting
  int get targetLane => _targetLane;

  /// Starts the run after the player has read the rules.
  void start() {
    _isRunning = true;
    _timeSinceSpawn = _rowSpacing; // the first row appears straight away
    _pushHud();
  }

  void restart() {
    for (final row in _rows) {
      row.removeFromParent();
    }

    _rows.clear();
    rules = ColorMatchRules(seed: seed);
    _targetLane = 2;
    _player
      ..x = _laneLeft(_targetLane)
      ..matchColor = rules.currentColor;
    _message = null;
    _messageTimeLeft = 0;
    _flashTimeLeft = 0;
    overlays.remove('ColorMatchOver');
    start();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);

    if (isLoaded) {
      _player.position = Vector2(
        _laneLeft(_targetLane),
        size.y - _playerBottomMargin,
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    _flashTimeLeft = math.max(0, _flashTimeLeft - dt);

    if (_messageTimeLeft > 0) {
      _messageTimeLeft -= dt;

      if (_messageTimeLeft <= 0) {
        _message = null;
        _pushHud();
      }
    }

    if (!_isRunning) {
      return;
    }

    _movePlayer(dt);
    _spawnRows(dt);
    _resolveRowsReachingThePlayer();
    _removeRowsBelowTheScreen();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (_flashTimeLeft > 0) {
      final alpha = (_flashTimeLeft / _flashDuration * 90).round();
      canvas.drawRect(
        Offset.zero & Size(size.x, size.y),
        Paint()..color = Color.fromARGB(alpha, 255, 40, 70),
      );
    }
  }

  void _movePlayer(double dt) {
    final delta = _laneLeft(_targetLane) - _player.x;
    final maxStep = _playerLaneSpeed * dt;
    _player.x += delta.clamp(-maxStep, maxStep);
  }

  void _spawnRows(double dt) {
    final speed = ColorMatchRules.rowSpeedForLevel(rules.level);
    _timeSinceSpawn += dt * speed;

    if (_timeSinceSpawn < _rowSpacing) {
      return;
    }

    _timeSinceSpawn = 0;
    final row =
        _ColorRow(
            colors: rules.nextRow(),
            speed: speed,
            laneLeft: _blockLeft,
            laneWidth: _blockWidth,
          )
          ..position = Vector2(0, -_rowHeight)
          ..size = Vector2(size.x, _rowHeight);

    _rows.add(row);
    add(row);
  }

  void _resolveRowsReachingThePlayer() {
    final playerCenter = _player.y + _player.height / 2;

    for (final row in _rows) {
      if (row.resolvedLane != null || row.y + row.height / 2 < playerCenter) {
        continue;
      }

      final lane = _laneFromX(_player.x + _player.width / 2);
      row.resolvedLane = lane;
      _applyResult(rules.pass(row.colors[lane]));

      if (rules.isOver) {
        return;
      }
    }
  }

  void _applyResult(PassResult result) {
    final popupPosition = Vector2(
      _player.x + _player.width / 2,
      _player.y - 18,
    );

    if (result.matched) {
      add(NearMissPopup(position: popupPosition, text: '+${result.points}'));
    } else {
      add(
        NearMissPopup(
          position: popupPosition,
          text: '-1 ♥',
          color: const Color(0xFFFF5C7A),
        ),
      );
      _flashTimeLeft = _flashDuration;
    }

    if (result.newColor != null) {
      _player.matchColor = result.newColor!;
      _showMessage(
        'New colour: ${result.newColor!.name} ${result.newColor!.symbol}',
      );
    } else if (result.levelUp != null) {
      _showMessage('Level ${result.levelUp}!');
    }

    if (result.isOver) {
      _isRunning = false;
      _pushHud();
      overlays.add('ColorMatchOver');
      onRunFinished?.call(rules);
      return;
    }

    _pushHud();
  }

  void _showMessage(String message) {
    _message = message;
    _messageTimeLeft = _messageDuration;
  }

  void _removeRowsBelowTheScreen() {
    for (final row in _rows.where((row) => row.y > size.y + 40).toList()) {
      _rows.remove(row);
      row.removeFromParent();
    }
  }

  void _pushHud() {
    hud.value = _hudState();
  }

  ColorMatchHud _hudState() {
    return ColorMatchHud(
      score: rules.score,
      lives: rules.lives,
      combo: rules.combo,
      multiplier: rules.multiplier,
      level: rules.level,
      color: rules.currentColor,
      nextColor: rules.nextColor,
      matchesUntilColorChange: rules.matchesUntilColorChange,
      isRunning: _isRunning,
      isOver: rules.isOver,
      message: _message,
    );
  }

  double get _laneWidth =>
      (size.x - _sidePadding * 2) / ColorMatchRules.laneCount;

  double _blockLeft(int lane) =>
      _sidePadding + lane * _laneWidth + _laneGap / 2;

  double get _blockWidth => _laneWidth - _laneGap;

  double _laneLeft(int lane) =>
      _sidePadding + _laneWidth * lane + _laneWidth / 2 - _playerSize / 2;

  int _laneFromX(double x) => ((x - _sidePadding) / _laneWidth).floor().clamp(
    0,
    ColorMatchRules.laneCount - 1,
  );

  void _moveToLane(int lane) {
    if (_isRunning) {
      _targetLane = lane.clamp(0, ColorMatchRules.laneCount - 1);
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    _moveToLane(_laneFromX(event.localPosition.x));
    super.onTapDown(event);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    _moveToLane(_laneFromX(event.localEndPosition.x));
    super.onDragUpdate(event);
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
        event.logicalKey == LogicalKeyboardKey.keyA) {
      _moveToLane(_targetLane - 1);
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
        event.logicalKey == LogicalKeyboardKey.keyD) {
      _moveToLane(_targetLane + 1);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }
}

void _paintSymbol(
  Canvas canvas,
  String symbol,
  Rect rect,
  Color color,
  double fontSize,
) {
  final painter = TextPainter(
    text: TextSpan(
      text: symbol,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  painter.paint(
    canvas,
    rect.center - Offset(painter.width / 2, painter.height / 2),
  );
}

class _MatchPlayer extends PositionComponent {
  _MatchPlayer(this.matchColor);

  MatchColor matchColor;

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(13));

    canvas.drawRRect(
      rrect.shift(const Offset(0, 3)),
      Paint()..color = const Color(0x40000000),
    );
    canvas.drawRRect(rrect, Paint()..color = matchColor.color);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    _paintSymbol(canvas, matchColor.symbol, rect, Colors.white, 18);
  }
}

class _ColorRow extends PositionComponent {
  _ColorRow({
    required this.colors,
    required this.speed,
    required this.laneLeft,
    required this.laneWidth,
  });

  final List<int> colors;
  final double speed;
  final double Function(int lane) laneLeft;
  final double laneWidth;

  /// The lane the player passed through; null until the row reaches the player.
  int? resolvedLane;

  @override
  void update(double dt) {
    super.update(dt);
    y += speed * dt;
  }

  @override
  void render(Canvas canvas) {
    for (var lane = 0; lane < colors.length; lane++) {
      final matchColor = ColorMatchRules.palette[colors[lane]];
      final rect = Rect.fromLTWH(laneLeft(lane), 0, laneWidth, size.y);
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(11));
      final dimmed = resolvedLane != null && resolvedLane != lane;

      canvas.drawRRect(
        rrect,
        Paint()..color = matchColor.color.withAlpha(dimmed ? 90 : 235),
      );
      _paintSymbol(
        canvas,
        matchColor.symbol,
        rect,
        const Color(0xCCFFFFFF),
        16,
      );
    }
  }
}

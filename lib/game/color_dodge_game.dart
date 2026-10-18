import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'game_mode.dart';

class HudState {
  const HudState({
    required this.score,
    required this.best,
    required this.nearMisses,
    required this.isGameOver,
    required this.isVictory,
  });

  final double score;
  final double best;
  final int nearMisses;
  final bool isGameOver;
  final bool isVictory;

  HudState copyWith({
    double? score,
    double? best,
    int? nearMisses,
    bool? isGameOver,
    bool? isVictory,
  }) {
    return HudState(
      score: score ?? this.score,
      best: best ?? this.best,
      nearMisses: nearMisses ?? this.nearMisses,
      isGameOver: isGameOver ?? this.isGameOver,
      isVictory: isVictory ?? this.isVictory,
    );
  }
}

enum _ObstacleVisualStyle { normal, slim, heavy }

enum _SectionType {
  intro,
  staircase,
  weave,
  tunnel,
  alternating,
  edgeRun,
  sprint,
}

class _PlannedRow {
  const _PlannedRow({
    required this.blockedLanes,
    required this.visualStyle,
    required this.recommendedLane,
  });

  final List<int> blockedLanes;
  final _ObstacleVisualStyle visualStyle;
  final int recommendedLane;
}

class ColorDodgeGame extends FlameGame
    with DragCallbacks, TapCallbacks, HasCollisionDetection {
  ColorDodgeGame({
    this.onGameOver,
    this.onNewBestScore,
    this.gameMode = GameMode.survival,
    double initialBestScore = 0,
  }) : _bestScore = math.max(0.0, initialBestScore),
       _lastPersistedBestScore = math.max(0.0, initialBestScore);

  final VoidCallback? onGameOver;
  final ValueChanged<double>? onNewBestScore;
  final GameMode gameMode;

  late _PlayerComponent _player;
  final math.Random _random = math.Random();

  final List<_ObstacleRow> _rows = [];
  final List<_PlannedRow> _plannedRows = [];

  final ValueNotifier<HudState> hud = ValueNotifier<HudState>(
    const HudState(
      score: 0,
      best: 0,
      nearMisses: 0,
      isGameOver: false,
      isVictory: false,
    ),
  );

  double _timeSinceStart = 0;
  double _timeSinceLastSpawn = 0;
  double _nextSpawnDelay = 0.42;
  double _bestScore;
  double _lastPersistedBestScore;

  bool _isGameOver = false;
  bool _isVictory = false;

  int _recommendedLane = 2;
  int _targetLane = 2;
  int _nearMisses = 0;

  _SectionType? _lastSectionType;

  static const int _laneCount = 5;

  static const double _playerWidth = 38;
  static const double _playerHeight = 38;
  static const double _playerBottomMargin = 104;

  static const double _sidePadding = 14;
  static const double _laneGap = 8;

  static const double _baseRowHeight = 28;
  static const double _maxRowHeight = 48;

  static const double _baseRowSpeed = 150;
  static const double _maxRowSpeed = 380;

  static const double _playerLaneSpeed = 980;
  static const double _victoryScore = 150.0;
  static const int _planAheadCount = 16;

  @override
  Color backgroundColor() => const Color(0xFF0B0F17);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _player = _PlayerComponent()
      ..size = Vector2(_playerWidth, _playerHeight)
      ..position = Vector2(
        _laneLeft(_targetLane),
        size.y - _playerBottomMargin,
      );

    add(_player);
    _ensurePlanAhead();
    _pushHud();
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_isGameOver || _isVictory) {
      return;
    }

    _timeSinceStart += dt;
    _timeSinceLastSpawn += dt;

    _updatePlayerPosition(dt);
    _spawnIfNeeded();
    _cleanupRows();
    _checkCollisions();
    _checkNearMisses();
    _updateHud();
    _checkVictory();
  }

  void _updatePlayerPosition(double dt) {
    final targetX = _laneLeft(_targetLane);
    final delta = targetX - _player.x;

    if (delta.abs() < 0.5) {
      _player.x = targetX;
      return;
    }

    final maxStep = _playerLaneSpeed * dt;
    _player.x += delta.clamp(-maxStep, maxStep);
  }

  void _spawnIfNeeded() {
    if (_timeSinceLastSpawn < _nextSpawnDelay) {
      return;
    }

    _ensurePlanAhead();
    if (_plannedRows.isEmpty) {
      return;
    }

    final planned = _plannedRows.removeAt(0);
    final difficulty = _difficultyProgress();
    final rowHeight = _calculateRowHeight(
      difficulty: difficulty,
      style: planned.visualStyle,
    );
    final rowSpeed = _calculateRowSpeed(difficulty);

    final row = _ObstacleRow(
      y: -rowHeight,
      height: rowHeight,
      speed: rowSpeed,
      laneCount: _laneCount,
      blockedLanes: planned.blockedLanes,
      laneGap: _laneGap,
      color: _rowColor(),
      visualStyle: planned.visualStyle,
    );

    final laneShift = (planned.recommendedLane - _recommendedLane).abs();

    _rows.add(row);
    add(row);

    _recommendedLane = planned.recommendedLane;
    _timeSinceLastSpawn = 0;
    _nextSpawnDelay = _calculateNextSpawnDelay(
      speed: rowSpeed,
      laneShift: laneShift,
    );
  }

  void _ensurePlanAhead() {
    while (_plannedRows.length < _planAheadCount) {
      _appendNextSection();
    }
  }

  void _appendNextSection() {
    final sectionType = _chooseSectionType();
    final startLane = _plannedRows.isEmpty
        ? _recommendedLane
        : _plannedRows.last.recommendedLane;

    switch (sectionType) {
      case _SectionType.intro:
        _plannedRows.addAll(_buildIntroSection(startLane));
        break;
      case _SectionType.staircase:
        _plannedRows.addAll(_buildStaircaseSection(startLane));
        break;
      case _SectionType.weave:
        _plannedRows.addAll(_buildWeaveSection(startLane));
        break;
      case _SectionType.tunnel:
        _plannedRows.addAll(_buildTunnelSection(startLane));
        break;
      case _SectionType.alternating:
        _plannedRows.addAll(_buildAlternatingSection(startLane));
        break;
      case _SectionType.edgeRun:
        _plannedRows.addAll(_buildEdgeRunSection(startLane));
        break;
      case _SectionType.sprint:
        _plannedRows.addAll(_buildSprintSection(startLane));
        break;
    }

    _lastSectionType = sectionType;
  }

  _SectionType _chooseSectionType() {
    final options = <_SectionType>[];

    if (_timeSinceStart < 12) {
      options.addAll([_SectionType.intro, _SectionType.staircase]);
    } else if (_timeSinceStart < 30) {
      options.addAll([
        _SectionType.staircase,
        _SectionType.weave,
        _SectionType.tunnel,
      ]);
    } else if (_timeSinceStart < 55) {
      options.addAll([
        _SectionType.weave,
        _SectionType.tunnel,
        _SectionType.alternating,
      ]);
    } else if (_timeSinceStart < 85) {
      options.addAll([
        _SectionType.weave,
        _SectionType.tunnel,
        _SectionType.alternating,
        _SectionType.edgeRun,
      ]);
    } else {
      options.addAll([
        _SectionType.tunnel,
        _SectionType.alternating,
        _SectionType.edgeRun,
        _SectionType.sprint,
      ]);
    }

    if (_lastSectionType != null && options.length > 1) {
      options.remove(_lastSectionType);
    }

    return options[_random.nextInt(options.length)];
  }

  List<_PlannedRow> _buildIntroSection(int startLane) {
    final direction = _preferredDirection(startLane);
    final secondLane = _clampLane(startLane + direction);

    return [
      _singleGap(startLane, _ObstacleVisualStyle.normal),
      _singleGap(startLane, _ObstacleVisualStyle.slim),
      _singleGap(secondLane, _ObstacleVisualStyle.normal),
      _singleGap(secondLane, _ObstacleVisualStyle.slim),
    ];
  }

  List<_PlannedRow> _buildStaircaseSection(int startLane) {
    final rows = <_PlannedRow>[];
    final direction = _preferredDirection(startLane);
    int lane = startLane;
    final length = _timeSinceStart < 50 ? 4 : 5;

    for (int i = 0; i < length; i++) {
      lane = _clampLane(lane + direction);
      rows.add(
        _singleGap(
          lane,
          i.isEven ? _ObstacleVisualStyle.normal : _ObstacleVisualStyle.slim,
        ),
      );
    }

    return rows;
  }

  List<_PlannedRow> _buildWeaveSection(int startLane) {
    final rows = <_PlannedRow>[];
    int lane = startLane;
    int direction = _preferredDirection(startLane);

    for (int i = 0; i < 6; i++) {
      final candidate = lane + direction;
      if (candidate < 0 || candidate >= _laneCount) {
        direction *= -1;
      }

      lane = _clampLane(lane + direction);

      rows.add(
        _singleGap(
          lane,
          i == 2 || i == 4
              ? _ObstacleVisualStyle.heavy
              : _ObstacleVisualStyle.normal,
        ),
      );

      direction *= -1;
    }

    return rows;
  }

  List<_PlannedRow> _buildTunnelSection(int startLane) {
    final rows = <_PlannedRow>[];
    final lane = startLane.clamp(1, _laneCount - 2);

    rows.add(_singleGap(lane, _ObstacleVisualStyle.normal));
    rows.add(_singleGap(lane, _ObstacleVisualStyle.heavy));
    rows.add(_singleGap(lane, _ObstacleVisualStyle.normal));

    final exitLane = _clampLane(lane + (_random.nextBool() ? -1 : 1));
    rows.add(_singleGap(exitLane, _ObstacleVisualStyle.slim));

    return rows;
  }

  List<_PlannedRow> _buildAlternatingSection(int startLane) {
    final leftLane = startLane <= 2 ? 1 : 0;
    final rightLane = startLane >= 2 ? 3 : 4;

    return [
      _singleGap(leftLane, _ObstacleVisualStyle.normal),
      _singleGap(rightLane, _ObstacleVisualStyle.normal),
      _singleGap(_clampLane(leftLane + 1), _ObstacleVisualStyle.slim),
      _singleGap(_clampLane(rightLane - 1), _ObstacleVisualStyle.heavy),
    ];
  }

  List<_PlannedRow> _buildEdgeRunSection(int startLane) {
    final rows = <_PlannedRow>[];
    final edge = startLane <= 2 ? 0 : _laneCount - 1;
    int lane = startLane;

    while (lane != edge) {
      lane += lane < edge ? 1 : -1;
      rows.add(_singleGap(lane, _ObstacleVisualStyle.normal));
    }

    rows.add(_singleGap(edge, _ObstacleVisualStyle.heavy));

    final returnLane = edge == 0 ? 1 : _laneCount - 2;
    rows.add(_singleGap(returnLane, _ObstacleVisualStyle.slim));

    return rows;
  }

  List<_PlannedRow> _buildSprintSection(int startLane) {
    final rows = <_PlannedRow>[];
    int lane = startLane;

    for (int i = 0; i < 7; i++) {
      final direction = _preferredDirection(lane);
      lane = _clampLane(lane + direction);

      rows.add(
        _singleGap(
          lane,
          i.isEven ? _ObstacleVisualStyle.slim : _ObstacleVisualStyle.normal,
        ),
      );
    }

    return rows;
  }

  _PlannedRow _singleGap(int safeLane, _ObstacleVisualStyle style) {
    final blocked = <int>[];

    for (int lane = 0; lane < _laneCount; lane++) {
      if (lane != safeLane) {
        blocked.add(lane);
      }
    }

    return _PlannedRow(
      blockedLanes: blocked,
      visualStyle: style,
      recommendedLane: safeLane,
    );
  }

  int _preferredDirection(int lane) {
    if (lane <= 0) {
      return 1;
    }

    if (lane >= _laneCount - 1) {
      return -1;
    }

    if (lane == 2) {
      return _random.nextBool() ? -1 : 1;
    }

    return lane < 2 ? 1 : -1;
  }

  int _clampLane(int lane) {
    return lane.clamp(0, _laneCount - 1);
  }

  double _calculateNextSpawnDelay({
    required double speed,
    required int laneShift,
  }) {
    final laneWidth = _laneWidth();
    final moveDistance = laneShift * laneWidth;
    final moveTime = laneShift == 0 ? 0.0 : moveDistance / _playerLaneSpeed;

    double baseDelay;
    if (_timeSinceStart < 10) {
      baseDelay = 0.56;
    } else if (_timeSinceStart < 20) {
      baseDelay = 0.52;
    } else if (_timeSinceStart < 40) {
      baseDelay = 0.49;
    } else if (_timeSinceStart < 70) {
      baseDelay = 0.46;
    } else if (_timeSinceStart < 100) {
      baseDelay = 0.43;
    } else {
      baseDelay = 0.40;
    }

    final fairnessDelay = moveTime + 0.14;
    return math.max(baseDelay, fairnessDelay).clamp(0.38, 0.74);
  }

  double _calculateRowHeight({
    required double difficulty,
    required _ObstacleVisualStyle style,
  }) {
    double base;
    if (_timeSinceStart < 25) {
      base = 30;
    } else if (_timeSinceStart < 60) {
      base = 31 + (difficulty * 3);
    } else if (_timeSinceStart < 100) {
      base = 33 + (difficulty * 5);
    } else {
      base = 35 + (difficulty * 7);
    }

    switch (style) {
      case _ObstacleVisualStyle.slim:
        return (base - 4).clamp(_baseRowHeight, _maxRowHeight);
      case _ObstacleVisualStyle.heavy:
        return (base + 5).clamp(_baseRowHeight, _maxRowHeight);
      case _ObstacleVisualStyle.normal:
        return base.clamp(_baseRowHeight, _maxRowHeight);
    }
  }

  double _calculateRowSpeed(double difficulty) {
    if (_timeSinceStart < 12) {
      return 155;
    }

    if (_timeSinceStart < 25) {
      return 170;
    }

    if (_timeSinceStart < 45) {
      return 185 + ((difficulty - 0.15).clamp(0.0, 1.0) * 18);
    }

    if (_timeSinceStart < 75) {
      return 210 + ((difficulty - 0.30).clamp(0.0, 1.0) * 32);
    }

    if (_timeSinceStart < 110) {
      return 245 + ((difficulty - 0.55).clamp(0.0, 1.0) * 50);
    }

    return (295 + ((difficulty - 0.75).clamp(0.0, 1.0) * 60)).clamp(
      _baseRowSpeed,
      _maxRowSpeed,
    );
  }

  void _checkNearMisses() {
    final playerRect = _player.toRect();

    for (final row in _rows) {
      if (row.nearMissAwarded) {
        continue;
      }

      final rowCenterY = row.y + (row.size.y / 2);
      final playerCenterY = playerRect.center.dy;
      final closeY = (rowCenterY - playerCenterY).abs() < 18;

      if (!closeY) {
        continue;
      }

      final closestBlockedDistance = row.closestBlockedEdgeDistance(playerRect);
      if (closestBlockedDistance != null && closestBlockedDistance < 8) {
        row.nearMissAwarded = true;
        _nearMisses++;
      }
    }
  }

  void _cleanupRows() {
    final rowsToRemove = _rows.where((row) => row.y > size.y + 80).toList();

    for (final row in rowsToRemove) {
      _rows.remove(row);
      row.removeFromParent();
    }
  }

  void _checkCollisions() {
    final playerRect = _player.toRect();

    for (final row in _rows) {
      if (!row.intersectsVertically(playerRect)) {
        continue;
      }

      if (row.collidesWith(playerRect)) {
        _gameOver();
        return;
      }
    }
  }

  void _updateHud() {
    final currentScore = _timeSinceStart;
    if (currentScore > _bestScore) {
      _bestScore = currentScore;
    }

    hud.value = hud.value.copyWith(
      score: currentScore,
      best: _bestScore,
      nearMisses: _nearMisses,
      isGameOver: false,
      isVictory: false,
    );
  }

  void _checkVictory() {
    if (_timeSinceStart >= _victoryScore) {
      _victory();
    }
  }

  void _saveNewRecord() {
    _bestScore = math.max(_bestScore, _timeSinceStart);
    if (_bestScore > _lastPersistedBestScore) {
      _lastPersistedBestScore = _bestScore;
      onNewBestScore?.call(_bestScore);
    }
  }

  void _gameOver() {
    if (_isGameOver || _isVictory) {
      return;
    }

    _isGameOver = true;
    _saveNewRecord();

    hud.value = hud.value.copyWith(
      score: _timeSinceStart,
      best: _bestScore,
      nearMisses: _nearMisses,
      isGameOver: true,
      isVictory: false,
    );

    overlays.add('GameOver');
    onGameOver?.call();
  }

  void _victory() {
    if (_isVictory || _isGameOver) {
      return;
    }

    _isVictory = true;
    _saveNewRecord();

    hud.value = hud.value.copyWith(
      score: _timeSinceStart,
      best: math.max(_bestScore, _timeSinceStart),
      nearMisses: _nearMisses,
      isGameOver: false,
      isVictory: true,
    );

    overlays.add('GameOver');
  }

  void resetRun() {
    _isGameOver = false;
    _isVictory = false;
    _timeSinceStart = 0;
    _timeSinceLastSpawn = 0;
    _nextSpawnDelay = 0.42;
    _nearMisses = 0;
    _lastSectionType = null;

    for (final row in List<_ObstacleRow>.from(_rows)) {
      row.removeFromParent();
    }

    _rows.clear();
    _plannedRows.clear();

    _targetLane = 2;
    _recommendedLane = 2;

    _player.position = Vector2(
      _laneLeft(_targetLane),
      size.y - _playerBottomMargin,
    );

    _ensurePlanAhead();

    overlays.remove('GameOver');
    _pushHud();
  }

  void _pushHud() {
    hud.value = HudState(
      score: _timeSinceStart,
      best: _bestScore,
      nearMisses: _nearMisses,
      isGameOver: _isGameOver,
      isVictory: _isVictory,
    );
  }

  double _difficultyProgress() {
    return (_timeSinceStart / 100.0).clamp(0.0, 1.0);
  }

  double _laneWidth() {
    return (size.x - (_sidePadding * 2)) / _laneCount;
  }

  double _laneLeft(int lane) {
    final laneWidth = _laneWidth();
    final centerX = _sidePadding + (laneWidth * lane) + (laneWidth / 2);
    return centerX - (_playerWidth / 2);
  }

  int _laneFromX(double x) {
    final laneWidth = _laneWidth();
    final lane = ((x - _sidePadding) / laneWidth).floor();
    return lane.clamp(0, _laneCount - 1);
  }

  Color _rowColor() {
    if (_timeSinceStart < 20) {
      return const Color(0xFF3485FF);
    }
    if (_timeSinceStart < 40) {
      return const Color(0xFF00A86B);
    }
    if (_timeSinceStart < 65) {
      return const Color(0xFFFFB020);
    }
    if (_timeSinceStart < 90) {
      return const Color(0xFFFF6B35);
    }
    if (_timeSinceStart < 120) {
      return const Color(0xFF8C42FF);
    }
    return const Color(0xFFFF2D8A);
  }

  void _moveToLane(int lane) {
    if (_isGameOver || _isVictory) {
      return;
    }

    _targetLane = _clampLane(lane);
  }

  @override
  void onTapDown(TapDownEvent event) {
    _moveToLane(_laneFromX(event.localPosition.x));
    super.onTapDown(event);
  }

  @override
  void onDragStart(DragStartEvent event) {
    _moveToLane(_laneFromX(event.localPosition.x));
    super.onDragStart(event);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    _moveToLane(_laneFromX(event.localEndPosition.x));
    super.onDragUpdate(event);
  }
}

class _PlayerComponent extends PositionComponent {
  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(13));

    final shadowPaint = Paint()..color = const Color(0x26000000);
    final fillPaint = Paint()..color = const Color(0xFFFFFFFF);
    final innerPaint = Paint()
      ..color = const Color(0x14000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawRRect(rrect.shift(const Offset(0, 3)), shadowPaint);
    canvas.drawRRect(rrect, fillPaint);
    canvas.drawRRect(rrect, innerPaint);
  }

  @override
  Rect toRect() {
    return Rect.fromLTWH(position.x, position.y, size.x, size.y);
  }
}

class _ObstacleRow extends PositionComponent {
  _ObstacleRow({
    required double y,
    required double height,
    required this.speed,
    required this.laneCount,
    required this.blockedLanes,
    required this.laneGap,
    required this.color,
    required this.visualStyle,
  }) {
    position = Vector2(0, y);
    size = Vector2.zero();
    this.height = height;
  }

  final double speed;
  final int laneCount;
  final List<int> blockedLanes;
  final double laneGap;
  final Color color;
  final _ObstacleVisualStyle visualStyle;

  bool nearMissAwarded = false;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = Vector2(size.x, height);
  }

  @override
  void update(double dt) {
    super.update(dt);
    y += speed * dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final totalWidth = size.x;
    const sidePadding = 14.0;
    final laneWidth = (totalWidth - (sidePadding * 2)) / laneCount;

    final pulse = (232 + (math.sin(y * 0.035) * 18)).round().clamp(0, 255);
    final fillPaint = Paint()..color = color.withAlpha(pulse);
    final shadowPaint = Paint()..color = const Color(0x1C000000);
    final innerPaint = Paint()
      ..color = const Color(0x10FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (final lane in blockedLanes) {
      final x = sidePadding + (lane * laneWidth) + (laneGap / 2);
      final width = laneWidth - laneGap;
      final rect = Rect.fromLTWH(x, 0, width, size.y);

      final radius = switch (visualStyle) {
        _ObstacleVisualStyle.slim => 8.0,
        _ObstacleVisualStyle.normal => 11.0,
        _ObstacleVisualStyle.heavy => 14.0,
      };

      final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

      canvas.drawRRect(rrect.shift(const Offset(0, 2)), shadowPaint);
      canvas.drawRRect(rrect, fillPaint);
      canvas.drawRRect(rrect, innerPaint);
    }
  }

  bool intersectsVertically(Rect playerRect) {
    final rowTop = y;
    final rowBottom = y + size.y;
    return playerRect.bottom > rowTop && playerRect.top < rowBottom;
  }

  bool collidesWith(Rect playerRect) {
    for (final rect in _blockedRects()) {
      if (rect.overlaps(playerRect)) {
        return true;
      }
    }

    return false;
  }

  double? closestBlockedEdgeDistance(Rect playerRect) {
    double? best;

    for (final rect in _blockedRects()) {
      final overlapsY =
          playerRect.bottom > rect.top && playerRect.top < rect.bottom;
      if (!overlapsY) {
        continue;
      }

      if (playerRect.right <= rect.left) {
        final d = rect.left - playerRect.right;
        best = best == null ? d : math.min(best, d);
      } else if (playerRect.left >= rect.right) {
        final d = playerRect.left - rect.right;
        best = best == null ? d : math.min(best, d);
      } else {
        return 0;
      }
    }

    return best;
  }

  List<Rect> _blockedRects() {
    final totalWidth = size.x;
    const sidePadding = 14.0;
    final laneWidth = (totalWidth - (sidePadding * 2)) / laneCount;

    return blockedLanes.map((lane) {
      final x = sidePadding + (lane * laneWidth) + (laneGap / 2);
      final width = laneWidth - laneGap;
      return Rect.fromLTWH(x, y, width, size.y);
    }).toList();
  }
}

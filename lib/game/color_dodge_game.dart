import 'dart:math';

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'game_mode.dart';
import 'components/obstacle.dart';
import 'components/player.dart';

class HudState {
  final double score;
  final double best;
  final int nearMisses;

  const HudState({
    required this.score,
    required this.best,
    required this.nearMisses,
  });
}

class ColorDodgeGame extends FlameGame with DragCallbacks {
  static const String _bestKeySurvival = 'best_survival_seconds';

  final GameMode mode;

  ColorDodgeGame({required this.mode});

  final ValueNotifier<HudState> hud = ValueNotifier(
    const HudState(score: 0, best: 0, nearMisses: 0),
  );

  final Random _rng = Random();

  final List<Obstacle> _obstaclePool = [];
  final List<Obstacle> _activeObstacles = [];

  Player? _player;
  Player? get player => _player;

  double _spawnTimer = 0;
  double _spawnInterval = 1.15;
  double _fallSpeed = 145;
  double _elapsed = 0;

  double _scoreSeconds = 0;
  double _bestSeconds = 0;

  double _hudTimer = 0;

  SharedPreferences? _prefs;

  Vector2 _cameraBase = Vector2.zero();
  double _shakeTimer = 0;
  double _shakeDuration = 0;
  double _shakeIntensity = 0;

  static const int _laneCount = 3;
  static const double _laneGap = 16.0;
  static const double _sidePadding = 18.0;
  static const double _obstacleHeight = 22.0;

  static const int _initialPoolSize = 24;

  // Finger-follow movement
  static const double _followSpeed = 30.0;
  static const double _snapDistance = 0.35;

  bool _isDragging = false;
  double _targetX = 0;
  double _dragPlayerOffsetX = 0;

  int _lastSafeLane = 1;

  // Performance logging
  static const bool _enablePerfLogging = false;
  double _perfWindowSeconds = 0;
  int _perfFrameCount = 0;
  double _perfMaxDt = 0;
  int _perfOver18ms = 0;
  int _perfOver25ms = 0;
  int _perfOver33ms = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _prefs = await SharedPreferences.getInstance();
    _bestSeconds = _prefs?.getDouble(_bestKeySurvival) ?? 0;

    final startX = size.x / 2;
    final player = Player()..position = Vector2(startX, size.y - 80);

    _player = player;
    add(player);

    for (var i = 0; i < _initialPoolSize; i++) {
      _createPooledObstacle();
    }

    _targetX = startX;
    _cameraBase = camera.viewfinder.position.clone();

    _pushHud(force: true);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);

    final player = _player;
    if (player == null) return;

    player.position.y = size.y - 80;
    player.clampToGameSize(size);
    _targetX = player.position.x;

    _cameraBase = camera.viewfinder.position.clone();
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);

    final player = _player;
    if (player == null) return;

    _isDragging = true;

    _dragPlayerOffsetX = player.position.x - event.localPosition.x;
    _targetX = player.position.x;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);

    final player = _player;
    if (player == null || !_isDragging) return;

    final minX = player.radius;
    final maxX = size.x - player.radius;

    final wantedX = event.localEndPosition.x + _dragPlayerOffsetX;
    _targetX = wantedX.clamp(minX, maxX);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _isDragging = false;
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    _isDragging = false;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_enablePerfLogging) {
      _trackPerformance(dt);
    }

    if (mode != GameMode.survival) return;

    final player = _player;
    if (player == null) return;

    _elapsed += dt;
    _scoreSeconds = _elapsed;

    _updatePlayerMovement(player, dt);
    _updateDifficulty();
    _updateObstacles(dt, player);

    _spawnTimer += dt;
    if (_spawnTimer >= _spawnInterval) {
      _spawnTimer = 0;
      _spawnFairPattern();
    }

    _updateShake(dt);

    _hudTimer += dt;
    if (_hudTimer >= 0.10) {
      _hudTimer = 0;
      _pushHud();
    }
  }

  void _updatePlayerMovement(Player player, double dt) {
    final minX = player.radius;
    final maxX = size.x - player.radius;
    _targetX = _targetX.clamp(minX, maxX);

    final dx = _targetX - player.position.x;
    final moveFactor = (_followSpeed * dt).clamp(0.0, 1.0);

    player.position.x += dx * moveFactor;

    if ((_targetX - player.position.x).abs() <= _snapDistance) {
      player.position.x = _targetX;
    }

    player.clampToGameSize(size);
  }

  void _trackPerformance(double dt) {
    _perfWindowSeconds += dt;
    _perfFrameCount++;

    if (dt > _perfMaxDt) {
      _perfMaxDt = dt;
    }

    if (dt > 0.018) {
      _perfOver18ms++;
    }

    if (dt > 0.025) {
      _perfOver25ms++;
    }

    if (dt > 0.0333) {
      _perfOver33ms++;
    }

    if (_perfWindowSeconds < 5.0) {
      return;
    }

    final avgDtMs = (_perfWindowSeconds / _perfFrameCount) * 1000;
    final maxDtMs = _perfMaxDt * 1000;

    debugPrint(
      '[PERF] avg=${avgDtMs.toStringAsFixed(2)}ms '
      'max=${maxDtMs.toStringAsFixed(2)}ms '
      '>18ms=$_perfOver18ms '
      '>25ms=$_perfOver25ms '
      '>33ms=$_perfOver33ms '
      'activeObstacles=${_activeObstacles.length} '
      'poolSize=${_obstaclePool.length}',
    );

    _perfWindowSeconds = 0;
    _perfFrameCount = 0;
    _perfMaxDt = 0;
    _perfOver18ms = 0;
    _perfOver25ms = 0;
    _perfOver33ms = 0;
  }

  void _updateObstacles(double dt, Player player) {
    for (var i = _activeObstacles.length - 1; i >= 0; i--) {
      final obstacle = _activeObstacles[i];
      obstacle.step(dt);

      if (_collides(player, obstacle)) {
        gameOver();
        return;
      }

      if (obstacle.isOffScreen(size.y)) {
        _releaseObstacle(obstacle);
      }
    }
  }

  bool _collides(Player player, Obstacle obstacle) {
    final circleX = player.position.x;
    final circleY = player.position.y;
    final radius = player.radius;

    final rectLeft = obstacle.position.x;
    final rectTop = obstacle.position.y;
    final rectRight = rectLeft + obstacle.size.x;
    final rectBottom = rectTop + obstacle.size.y;

    final closestX = circleX.clamp(rectLeft, rectRight);
    final closestY = circleY.clamp(rectTop, rectBottom);

    final dx = circleX - closestX;
    final dy = circleY - closestY;

    return (dx * dx) + (dy * dy) <= (radius * radius);
  }

  void _pushHud({bool force = false}) {
    final next = HudState(
      score: _scoreSeconds,
      best: _bestSeconds,
      nearMisses: 0,
    );

    if (!force) {
      final current = hud.value;
      if ((current.score - next.score).abs() < 0.01 &&
          (current.best - next.best).abs() < 0.01 &&
          current.nearMisses == next.nearMisses) {
        return;
      }
    }

    hud.value = next;
  }

  void _updateDifficulty() {
    final progress = 1 - exp(-_elapsed / 28.0);

    _spawnInterval = 1.15 - (0.48 * progress);
    _fallSpeed = 145 + (115 * progress);
  }

  void _spawnFairPattern() {
    final safeLane = _chooseNextSafeLane();
    final patternType = _choosePatternType();

    switch (patternType) {
      case 0:
        _spawnTwoBlockedOneSafe(safeLane);
        break;
      case 1:
        _spawnOneBlockedTwoSafe(safeLane);
        break;
      case 2:
        _spawnWideCenterBlockWithSafeLane(safeLane);
        break;
      default:
        _spawnTwoBlockedOneSafe(safeLane);
        break;
    }

    _lastSafeLane = safeLane;
  }

  int _chooseNextSafeLane() {
    final possible = <int>[_lastSafeLane];

    if (_lastSafeLane > 0) {
      possible.add(_lastSafeLane - 1);
    }

    if (_lastSafeLane < _laneCount - 1) {
      possible.add(_lastSafeLane + 1);
    }

    if (_elapsed < 12) {
      return possible[_rng.nextInt(possible.length)];
    }

    final allowBigShiftChance = (0.08 + (_elapsed / 300)).clamp(0.0, 0.22);
    if (_rng.nextDouble() < allowBigShiftChance) {
      return _rng.nextInt(_laneCount);
    }

    return possible[_rng.nextInt(possible.length)];
  }

  int _choosePatternType() {
    final progress = 1 - exp(-_elapsed / 30.0);
    final roll = _rng.nextDouble();

    final oneBlockedChance = (0.55 - (0.30 * progress)).clamp(0.18, 0.55);
    final twoBlockedChance = (0.35 + (0.22 * progress)).clamp(0.35, 0.60);

    if (roll < oneBlockedChance) {
      return 1;
    }

    if (roll < oneBlockedChance + twoBlockedChance) {
      return 0;
    }

    return 2;
  }

  double _laneWidth() {
    final totalGapWidth = (_laneCount - 1) * _laneGap;
    final totalWidth = size.x - (_sidePadding * 2) - totalGapWidth;
    return max(40.0, totalWidth / _laneCount);
  }

  double _laneX(int laneIndex) {
    return _sidePadding + laneIndex * (_laneWidth() + _laneGap);
  }

  Rect _laneRect(int laneIndex) {
    final x = _laneX(laneIndex);
    return Rect.fromLTWH(x, -30, _laneWidth(), _obstacleHeight);
  }

  void _spawnObstacleRect(Rect rect) {
    final obstacle = _acquireObstacle();

    obstacle.activate(
      x: rect.left,
      y: rect.top,
      width: rect.width,
      height: rect.height,
      newFallSpeed: _fallSpeed,
    );

    _activeObstacles.add(obstacle);
  }

  Obstacle _acquireObstacle() {
    for (final obstacle in _obstaclePool) {
      if (!obstacle.isActive) {
        return obstacle;
      }
    }

    return _createPooledObstacle();
  }

  void _releaseObstacle(Obstacle obstacle) {
    obstacle.deactivate();
    _activeObstacles.remove(obstacle);
  }

  Obstacle _createPooledObstacle() {
    final obstacle = Obstacle();
    obstacle.deactivate();
    _obstaclePool.add(obstacle);
    add(obstacle);
    return obstacle;
  }

  void _spawnTwoBlockedOneSafe(int safeLane) {
    for (var lane = 0; lane < _laneCount; lane++) {
      if (lane == safeLane) continue;
      _spawnObstacleRect(_laneRect(lane));
    }
  }

  void _spawnOneBlockedTwoSafe(int preferredSafeLane) {
    final blockedLaneOptions = <int>[0, 1, 2]..remove(preferredSafeLane);
    final blockedLane =
        blockedLaneOptions[_rng.nextInt(blockedLaneOptions.length)];

    _spawnObstacleRect(_laneRect(blockedLane));
  }

  void _spawnWideCenterBlockWithSafeLane(int safeLane) {
    if (safeLane == 0) {
      final left = _laneRect(1);
      final right = _laneRect(2);
      _spawnObstacleRect(
        Rect.fromLTWH(left.left, -30, right.right - left.left, _obstacleHeight),
      );
      return;
    }

    if (safeLane == 2) {
      final left = _laneRect(0);
      final right = _laneRect(1);
      _spawnObstacleRect(
        Rect.fromLTWH(left.left, -30, right.right - left.left, _obstacleHeight),
      );
      return;
    }

    _spawnObstacleRect(_laneRect(0));
    _spawnObstacleRect(_laneRect(2));
  }

  void _updateShake(double dt) {
    if (_shakeTimer <= 0) {
      camera.viewfinder.position = _cameraBase;
      return;
    }

    _shakeTimer -= dt;
    final t = (_shakeTimer / _shakeDuration).clamp(0.0, 1.0);
    final intensity = _shakeIntensity * t;

    final dx = (_rng.nextDouble() * 2 - 1) * intensity;
    final dy = (_rng.nextDouble() * 2 - 1) * intensity;

    camera.viewfinder.position = _cameraBase + Vector2(dx, dy);

    if (_shakeTimer <= 0) {
      camera.viewfinder.position = _cameraBase;
    }
  }

  void shake({double duration = 0.20, double intensity = 10}) {
    _shakeDuration = duration;
    _shakeTimer = duration;
    _shakeIntensity = intensity;
  }

  void gameOver() {
    shake(duration: 0.22, intensity: 14);

    if (_scoreSeconds > _bestSeconds) {
      _bestSeconds = _scoreSeconds;
      _prefs?.setDouble(_bestKeySurvival, _bestSeconds);
    }

    _pushHud(force: true);

    pauseEngine();
    overlays.add('GameOver');
  }

  void resetRun() {
    for (final obstacle in _activeObstacles.toList()) {
      _releaseObstacle(obstacle);
    }

    _spawnTimer = 0;
    _spawnInterval = 1.15;
    _fallSpeed = 145;
    _elapsed = 0;
    _scoreSeconds = 0;
    _hudTimer = 0;
    _lastSafeLane = 1;
    _isDragging = false;
    _dragPlayerOffsetX = 0;

    final player = _player;
    if (player != null) {
      player.position = Vector2(size.x / 2, size.y - 80);
      player.clampToGameSize(size);
      _targetX = player.position.x;
    } else {
      _targetX = size.x / 2;
    }

    camera.viewfinder.position = _cameraBase;
    _shakeTimer = 0;
    _shakeDuration = 0;
    _shakeIntensity = 0;

    _pushHud(force: true);

    overlays.remove('GameOver');
    resumeEngine();
  }

  @override
  void onRemove() {
    hud.dispose();
    super.onRemove();
  }
}

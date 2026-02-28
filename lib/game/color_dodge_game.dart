import 'dart:math';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import '../ui/mode_select_screen.dart';
import 'components/player.dart';
import 'components/obstacle.dart';

class ColorDodgeGame extends FlameGame
    with HasCollisionDetection, DragCallbacks {
  final GameMode mode;

  ColorDodgeGame({required this.mode});

  final _rng = Random();

  late final Player player;

  double _spawnTimer = 0;
  double _spawnInterval = 1.0;
  double _fallSpeed = 150;
  double _elapsed = 0;

  double scoreSeconds = 0;

  bool _isDragging = false;

  // Smooth input
  double _targetX = 0;

  // Feel tweaks
  static const double _dragSensitivity = 1.15; // 1.0 = normal, >1 = faster
  static const double _followSpeed = 18; // higher = snappier follow

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    player = Player()..position = Vector2(size.x / 2, size.y - 80);
    add(player);

    _targetX = player.position.x;
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    _isDragging = true;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);

    if (!_isDragging) return;

    _targetX += event.localDelta.x * _dragSensitivity;

    // Clamp target so we never "chase" outside the screen
    final minX = player.radius;
    final maxX = size.x - player.radius;

    if (_targetX < minX) _targetX = minX;
    if (_targetX > maxX) _targetX = maxX;
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

    if (mode != GameMode.classic) return;

    _elapsed += dt;
    scoreSeconds = _elapsed;

    // Smooth follow towards targetX (stable across frame rates)
    final lerpFactor = 1 - pow(0.001, dt * _followSpeed).toDouble();
    player.position.x += (_targetX - player.position.x) * lerpFactor;

    player.clampToGameSize(size);

    _updateDifficulty();

    _spawnTimer += dt;
    if (_spawnTimer >= _spawnInterval) {
      _spawnObstacle();
      _spawnTimer = 0;
    }
  }

  void _updateDifficulty() {
    if (_elapsed > 40) {
      _fallSpeed = 320;
      _spawnInterval = 0.50;
    } else if (_elapsed > 20) {
      _fallSpeed = 260;
      _spawnInterval = 0.60;
    } else if (_elapsed > 10) {
      _fallSpeed = 200;
      _spawnInterval = 0.80;
    }
  }

  void _spawnObstacle() {
    final width = 80.0 + _rng.nextDouble() * 120.0;
    final x = _rng.nextDouble() * (size.x - width);

    add(
      Obstacle(fallSpeed: _fallSpeed, width: width)..position = Vector2(x, -30),
    );
  }

  void gameOver() {
    pauseEngine();
    overlays.add('GameOver');
  }

  void resetRun() {
    children.whereType<Obstacle>().forEach((o) => o.removeFromParent());

    _spawnTimer = 0;
    _spawnInterval = 1.0;
    _fallSpeed = 150;
    _elapsed = 0;
    scoreSeconds = 0;

    _isDragging = false;

    player.position = Vector2(size.x / 2, size.y - 80);
    _targetX = player.position.x;
  }
}

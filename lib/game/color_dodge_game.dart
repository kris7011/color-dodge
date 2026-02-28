import 'package:flame/game.dart';
import '../ui/mode_select_screen.dart';

class ColorDodgeGame extends FlameGame {
  final GameMode mode;

  ColorDodgeGame({required this.mode});

  @override
  Future<void> onLoad() async {
    // Classic mode implemented next commit
  }
}
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../game/color_dodge_game.dart';
import 'mode_select_screen.dart';

class GameScreen extends StatelessWidget {
  final GameMode mode;

  const GameScreen({super.key, required this.mode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget(
        game: ColorDodgeGame(mode: mode),
      ),
    );
  }
}
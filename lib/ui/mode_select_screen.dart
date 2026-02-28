import 'package:flutter/material.dart';
import 'game_screen.dart';

enum GameMode { classic, colorMatch }

class ModeSelectScreen extends StatelessWidget {
  const ModeSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Mode')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const GameScreen(mode: GameMode.classic),
                  ),
                ),
                child: const Text('Classic (Dodge)'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Coming soon'),
                    content: const Text('Color Match mode is coming in a future update 🚀'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                ),
                child: const Text('Color Match (Coming Soon)'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
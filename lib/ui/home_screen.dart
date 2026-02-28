import 'package:flutter/material.dart';
import 'mode_select_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ModeSelectScreen()),
          ),
          child: const Text('Play'),
        ),
      ),
    );
  }
}
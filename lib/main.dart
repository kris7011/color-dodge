import 'package:flutter/material.dart';
import 'ui/mode_select_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Color Dodge',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const ModeSelectScreen(),
    );
  }
}

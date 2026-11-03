import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'features/preferences/application/game_preferences_cubit.dart';
import 'features/preferences/data/shared_preferences_game_preferences_repository.dart';
import 'ui/mode_select_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<GamePreferencesCubit>(
      create: (_) => GamePreferencesCubit(
        const SharedPreferencesGamePreferencesRepository(),
      )..load(),
      child: MaterialApp(
      title: 'Color Dodge',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
        home: const ModeSelectScreen(),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../application/game_preferences_cubit.dart';

class GamePreferencesScreen extends StatelessWidget {
  const GamePreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accessibility settings')),
      body: BlocBuilder<GamePreferencesCubit, GamePreferencesState>(
        builder: (context, state) {
          if (state is GamePreferencesLoading ||
              state is GamePreferencesInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is GamePreferencesFailure) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Unable to load your preferences.'),
                  TextButton(
                    onPressed: () =>
                        context.read<GamePreferencesCubit>().load(),
                    child: const Text('Try again'),
                  ),
                ],
              ),
            );
          }

          if (state is GamePreferencesReady) {
            return ListView(
              children: [
                SwitchListTile.adaptive(
                  key: const Key('reduce-flashes-switch'),
                  title: const Text('Reduce colour flashes'),
                  subtitle: const Text(
                    'Disables the brief red full-screen flash when a '
                    'colour is missed in Color Match. Gameplay and scoring '
                    'remain unchanged.',
                  ),
                  value: state.preferences.reduceFlashes,
                  onChanged: state.isSaving
                      ? null
                      : (value) => context
                          .read<GamePreferencesCubit>()
                          .setReduceFlashes(value),
                ),
                if (state.saveFailed)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Could not save your setting. Try again.',
                      key: Key('preferences-save-error'),
                    ),
                  ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

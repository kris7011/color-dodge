import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/game_preferences.dart';
import '../domain/game_preferences_repository.dart';

sealed class GamePreferencesState {
  const GamePreferencesState();
}

final class GamePreferencesInitial extends GamePreferencesState {
  const GamePreferencesInitial();
}

final class GamePreferencesLoading extends GamePreferencesState {
  const GamePreferencesLoading();
}

final class GamePreferencesReady extends GamePreferencesState {
  const GamePreferencesReady(
    this.preferences, {
    this.isSaving = false,
    this.saveFailed = false,
  });

  final GamePreferences preferences;
  final bool isSaving;
  final bool saveFailed;
}

final class GamePreferencesFailure extends GamePreferencesState {
  const GamePreferencesFailure();
}

/// Owns UI configuration state, not frame-by-frame Flame gameplay state.
class GamePreferencesCubit extends Cubit<GamePreferencesState> {
  GamePreferencesCubit(this._repository)
      : super(const GamePreferencesInitial());

  final GamePreferencesRepository _repository;
  Future<void>? _pendingLoad;

  Future<void> load() {
    if (isClosed || state is GamePreferencesReady) {
      return Future<void>.value();
    }
    return _pendingLoad ??= _loadOnce().whenComplete(() {
      _pendingLoad = null;
    });
  }

  Future<void> _loadOnce() async {
    emit(const GamePreferencesLoading());
    try {
      final preferences = await _repository.load();
      if (!isClosed) emit(GamePreferencesReady(preferences));
    } catch (_) {
      if (!isClosed) emit(const GamePreferencesFailure());
    }
  }

  Future<void> setReduceFlashes(bool value) async {
    final current = state;
    if (isClosed ||
        current is! GamePreferencesReady ||
        current.isSaving ||
        current.preferences.reduceFlashes == value) {
      return;
    }

    final updated = current.preferences.copyWith(reduceFlashes: value);
    emit(GamePreferencesReady(current.preferences, isSaving: true));
    try {
      await _repository.save(updated);
      if (!isClosed) emit(GamePreferencesReady(updated));
    } catch (_) {
      if (!isClosed) {
        // Keep the last confirmed value if the local save failed.
        emit(GamePreferencesReady(current.preferences, saveFailed: true));
      }
    }
  }
}

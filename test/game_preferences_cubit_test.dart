import 'dart:async';

import 'package:color_dodge/features/preferences/application/game_preferences_cubit.dart';
import 'package:color_dodge/features/preferences/domain/game_preferences.dart';
import 'package:color_dodge/features/preferences/domain/game_preferences_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepository implements GamePreferencesRepository {
  _FakeRepository({this.preferences = const GamePreferences()});

  GamePreferences preferences;
  bool failLoad = false;
  bool failSave = false;
  int saveCalls = 0;
  Completer<void>? pendingSave;

  @override
  Future<GamePreferences> load() async {
    if (failLoad) throw StateError('Storage unavailable');
    return preferences;
  }

  @override
  Future<void> save(GamePreferences newPreferences) async {
    saveCalls++;
    await pendingSave?.future;
    if (failSave) throw StateError('Storage unavailable');
    preferences = newPreferences;
  }
}

void main() {
  test('loads persisted settings and exposes immutable state', () async {
    final repository = _FakeRepository(
      preferences: const GamePreferences(reduceFlashes: true),
    );
    final cubit = GamePreferencesCubit(repository);
    addTearDown(cubit.close);

    final observed = expectLater(
      cubit.stream,
      emitsInOrder([
        isA<GamePreferencesLoading>(),
        isA<GamePreferencesReady>().having(
          (state) => state.preferences.reduceFlashes,
          'reduced flashes',
          isTrue,
        ),
      ]),
    );
    await cubit.load();
    await observed;
  });

  test('persists toggle and exposes confirmed state', () async {
    final repository = _FakeRepository();
    final cubit = GamePreferencesCubit(repository);
    addTearDown(cubit.close);
    await cubit.load();

    final observed = expectLater(
      cubit.stream,
      emitsInOrder([
        isA<GamePreferencesReady>().having(
          (state) => state.isSaving,
          'saving',
          isTrue,
        ),
        isA<GamePreferencesReady>().having(
          (state) => state.preferences.reduceFlashes,
          'confirmed reduced flashes',
          isTrue,
        ),
      ]),
    );
    await cubit.setReduceFlashes(true);
    await observed;

    expect(repository.saveCalls, 1);
    expect(repository.preferences.reduceFlashes, isTrue);
  });

  test('rolls back a failed save and shows an error state', () async {
    final repository = _FakeRepository()..failSave = true;
    final cubit = GamePreferencesCubit(repository);
    addTearDown(cubit.close);
    await cubit.load();

    await cubit.setReduceFlashes(true);
    final state = cubit.state as GamePreferencesReady;
    expect(state.preferences.reduceFlashes, isFalse);
    expect(state.saveFailed, isTrue);
    expect(repository.preferences.reduceFlashes, isFalse);
  });

  test('does not start multiple writes while saving', () async {
    final repository = _FakeRepository()..pendingSave = Completer<void>();
    final cubit = GamePreferencesCubit(repository);
    addTearDown(cubit.close);
    await cubit.load();

    final first = cubit.setReduceFlashes(true);
    await cubit.setReduceFlashes(false);
    expect(repository.saveCalls, 1);

    repository.pendingSave!.complete();
    await first;
    expect((cubit.state as GamePreferencesReady).preferences.reduceFlashes, isTrue);
  });

  test('can retry an initial load failure', () async {
    final repository = _FakeRepository()..failLoad = true;
    final cubit = GamePreferencesCubit(repository);
    addTearDown(cubit.close);

    await cubit.load();
    expect(cubit.state, isA<GamePreferencesFailure>());

    repository.failLoad = false;
    await cubit.load();
    expect(cubit.state, isA<GamePreferencesReady>());
  });
}

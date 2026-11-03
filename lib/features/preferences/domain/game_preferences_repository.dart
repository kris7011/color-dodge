import 'game_preferences.dart';

abstract interface class GamePreferencesRepository {
  Future<GamePreferences> load();
  Future<void> save(GamePreferences preferences);
}

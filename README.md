# Color Dodge

A small arcade game built with **Flutter**, **Dart**, and the **Flame** game engine.

Move between five lanes to avoid incoming obstacles. Survive longer to increase your score, watch your near misses, and reach the 150-second finish.

## Current gameplay

- **Survival:** Playable obstacle-dodging mode with a five-lane arena.
- **Color Match:** Visible in the menu, but deliberately marked *Coming soon*.
- **Touch controls:** Drag left or right to move your player.
- **Changing patterns:** Obstacle rows vary as the run progresses.
- **Live HUD:** Displays score during the run, followed by score, best score, and near misses on the results screen.
- **Replay:** Start another run from the end-of-game overlay.

Best scores are stored locally using SharedPreferences and persist across app launches. Additional game modes are not yet implemented.

## Technology

| Layer | Technology |
| --- | --- |
| UI and navigation | Flutter / Material |
| Gameplay and rendering | Flame |
| Language | Dart (SDK `^3.10.8`) |
| Static analysis | `flutter analyze` |
| Automated tests | Flutter widget tests |
| Continuous integration | GitHub Actions |

## Run locally

Install the [Flutter SDK](https://docs.flutter.dev/get-started/install), then from the repository root:

```bash
flutter pub get
flutter run
```

Select a connected device or simulator as prompted by Flutter.

## Run quality checks

```bash
flutter analyze
flutter test
```

GitHub Actions runs both commands for pushes to `main` and pull requests. The initial widget tests verify that the game mode menu renders and that the Color Match placeholder dialog can be opened and dismissed.

## Project layout

```text
lib/
  main.dart                 # Flutter app entry point
  game/
    color_dodge_game.dart   # Flame game loop and obstacle patterns
    game_mode.dart          # Mode declarations
    components/             # Visual game components
  ui/
    mode_select_screen.dart # Game mode selection
    game_screen.dart        # Game view, HUD and results overlays
test/
  mode_select_screen_test.dart
```

## Current scope and next steps

This is a **portfolio and learning project**, not a published mobile game. Survival is the currently playable mode; Color Match is a future feature.

Potential next steps are unit tests for collision and obstacle-generation rules, persistent best scores, accessibility refinements, and additional playable modes. Keep changes small and covered by automated tests.

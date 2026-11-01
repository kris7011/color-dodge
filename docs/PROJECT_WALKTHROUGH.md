# Color Dodge — project walkthrough

A developer-level guide to the game and, in depth, to the Color Match mode. It describes only what exists in the repository.

## 1. Overview

Color Dodge is a Flutter app using the Flame game engine. A menu (`ui/mode_select_screen.dart`) opens three modes:

| Mode | Game class | Screen |
| --- | --- | --- |
| Survival | `game/color_dodge_game.dart` | `ui/game_screen.dart` |
| Daily Challenge | same class, seeded by the UTC date | `ui/game_screen.dart` |
| Color Match | `game/color_match/color_match_game.dart` | `ui/color_match_screen.dart` |

Scores are stored with SharedPreferences (`storage/`).

## 2. Color Match

### Design

Color Match reverses the dodging idea: instead of avoiding every block, you must pass through the block of your own colour. The mode adds scoring decisions (keep the combo, prepare for the next colour) on top of movement.

### Layers

```text
ColorMatchRules (pure Dart)        scoring, lives, combo, colours, levels, row generation
        ▲ rules.nextRow(), rules.pass(colour)
ColorMatchGame (Flame)             falling rows, player, input, popups, flash, banners
        ▲ hud (ValueNotifier), overlays, onRunFinished
ColorMatchScreen (Flutter)         rules panel, HUD, results; saves progress
        ▲
ColorMatchProgressStore            SharedPreferences: bests and totals
```

The rules have no Flame or Flutter rendering code, so every rule is unit-tested without a game loop. The game class only decides *when* a row reaches the player and *which* lane the player is in; `rules.pass(colour)` decides what that means. Survival's 887-line game class was left untouched; Color Match is a separate class with the same lane geometry.

### Rules (`color_match_rules.dart`)

- Palette: Blue ●, Green ▲, Orange ■, Pink ◆. Every colour has a symbol for colour-blind players.
- `pass(colour)`: a match adds `1 × multiplier` (×1, ×2 from a 3-streak, ×3 from a 6-streak), increases the combo and counts towards the next colour change. A miss costs a life and resets the combo. Passing after the run is over throws.
- Every 6 matches the colour changes to the already announced `nextColor`.
- `level = 1 + matches ÷ 8`. Speed rises 28 px/s per level (capped at 360). A fourth colour joins at level 3; from level 4 only one lane per row matches.
- `nextRow()` puts the player's colour in the required number of lanes, and one of them is **within two lanes of every matching lane of the previous row**. The player may have taken either matching lane, so this guarantees a nearby match either way. A five-lane row always has such a lane. The test for this caught the first version, which only anchored on one of the previous lanes.
- A seed makes the course reproducible (tests and the on-device run).

### Game (`color_match_game.dart`)

- Rows are spawned every 210 px of travel at the current level's speed.
- A row is resolved once, when its centre reaches the player's centre, using the lane under the player at that moment; the other blocks of the row are dimmed.
- Feedback: `NearMissPopup` (reused from Survival) shows "+points" or "-1 ♥", a red flash fades over 0.3 s on a miss, and banners announce a new colour or level.
- Input: drag, tap a lane, arrow keys or A/D (`KeyboardEvents`).
- `approachingRows` and `targetLane` are read-only and marked `@visibleForTesting` for the on-device bot.

### Screen and progression

- The `GameWidget` is built **once**. Rebuilding it re-applies `initialActiveOverlays`, which put the rules panel back over the results; the end-to-end widget test found this (the "Play again" tap hit the rules panel).
- When the run ends, `ColorMatchProgressStore.recordRun` keeps bests (score, level, combo) and adds totals (matches, runs). The results show "New best score!" / "New highest level!".
- The menu reloads progress when you return from the game, and the card shows "Best N · Level L".

## 3. Testing

| Test | What it proves |
| --- | --- |
| `color_match_rules_test.dart` (7) | determinism; every row has the right number of matching lanes, only allowed colours, and a match within two lanes of every previous match (300 rows); multiplier sequence 1,1,1,2,2,2,3; misses; game over; colour change to the announced colour; level-ups and difficulty curves |
| `color_match_progress_store_test.dart` (4) | empty start, bests only rise and totals add up, separate keys, refusal of impossible values |
| `color_match_screen_test.dart` (1) | a seeded run through the **real Flame loop** in a widget test: start, three misses, "Out of lives", rules panel not back, progress saved, "Play again" restores three lives |
| `mode_select_screen_test.dart` (4) | three modes, progress on the card, refresh after returning (this test failed against the arrow-function `setState`), rules panel when opening Color Match |
| `integration_test/color_match_demo_test.dart` | on a device: menu → Color Match → bot plays with key presses to level 3 → run ends → results → menu card updated |

`flutter test`: 29 tests pass; `flutter analyze`: no issues.

## 4. On-device demonstration (1 November 2026)

Windows 11, Flutter 3.44.6, Windows desktop build. `flutter test integration_test/color_match_demo_test.dart -d windows` passed. Result: score 43, level 3, 18 matches in 21 rows, best combo 17. The bot steered until level 3 and then stopped, so the three misses at the end are deliberate. A separate script captured the real window every 0.5 s; the README screenshots are those frames.

The run found a real bug the widget tests had not covered at the time: `setState(() => future = …)` in the menu returned a Future, which asserts in debug builds. It is fixed and now covered by a widget test.

Not verified for this change: Android, iOS, web, macOS and Linux.

## 5. Limitations

- Progress is local to the device; there is no account or online leaderboard.
- The HUD sits over the top of the arena, and rows pass beneath it.
- Rows are spaced by distance, so at high levels the time to react shrinks; speed is capped at 360 px/s.

## 6. Ownership and AI assistance

Implemented with AI assistance (Claude Code) from the owner's requirement to make Color Match a genuinely playable mode with rules, mechanics, local progression, feedback and tests. The owner reviews and merges.

## 7. Interview preparation

**Non-technical:** In Color Match you steer into blocks of your own colour. Streaks multiply your score, wrong colours cost lives, and your colour keeps changing as the game speeds up. The game remembers your best results.

**Developer:** A pure rules class decides scoring and row generation; the Flame class moves rows and resolves each row once at the player; the Flutter screen shows overlays and saves progress through SharedPreferences.

**Senior:** Separating rules from the engine made the game logic testable and deterministic. Fairness is a property of the generator (a reachable match is guaranteed) and is tested over hundreds of rows. Widget and on-device tests run the real game loop and caught two lifecycle bugs that unit tests could not.

**Questions and answers**

1. *Why a separate rules class?* Game rules change often; keeping them free of rendering lets tests check exact scores and fairness quickly and deterministically.
2. *How do you keep the game fair?* Every row has a matching block within two lanes of every matching block of the previous row, the next colour is announced, and speed is capped.
3. *Why do colours also have symbols?* About 1 in 12 men has a colour-vision deficiency; symbols make the mode playable without telling the colours apart.
4. *What did the end-to-end tests find?* That rebuilding a `GameWidget` re-adds its initial overlays, and that a `setState` arrow returning a Future asserts. Both are fixed and covered.
5. *How would you add an online leaderboard?* Keep local progress as is, submit seeded daily runs with their seed and inputs to a server that replays them with the same rules class to verify the score.

**Hands-on exercise:** Add a "shield" pickup: every 10th match grants a shield that absorbs the next miss. Implement it in `ColorMatchRules` with tests first, then show it in the HUD.

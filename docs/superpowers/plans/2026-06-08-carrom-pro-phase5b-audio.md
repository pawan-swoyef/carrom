# Carrom Pro — Phase 5B: Audio (SFX) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans.

**Goal:** Sound effects for strike, pocket, win, lose — gated by the Sound Effects setting, and crash-safe when the audio files are absent (the game stays silent rather than throwing). Engine fires testable sound-trigger callbacks.

**Architecture:** `CarromGame` exposes `onStrike` (fired in `launch`) and `onPocket` (fired in `capture` when a piece is pocketed) callbacks — pure, headless-testable. A crash-safe `AudioService` (flame_audio) plays named clips only if loaded and sound is enabled. `GameScreen` wires the service to the callbacks + win/lose. Required clip files are documented; absence = silent.

**Tech Stack:** Existing + `flame_audio`.

> **ASSET DEPENDENCY:** real sound files are NOT included. Drop `strike.mp3`, `pocket.mp3`, `win.mp3`, `lose.mp3` into `assets/audio/` to hear sound. Until then the game is silent (no crash).

---

## Task 1: Add flame_audio + AudioService + assets

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/services/audio_service.dart`
- Create: `assets/audio/README.md`

- [ ] **Step 1: Add the package + asset dir**

Run: `flutter pub add flame_audio`
Create `assets/audio/README.md`:
```
Drop these clips here (short mp3/ogg) to enable SFX:
- strike.mp3   — striker launch
- pocket.mp3   — a coin/striker drops into a pocket
- win.mp3      — match won
- lose.mp3     — match lost
The game runs silently if any are missing.
```
In `pubspec.yaml` under `flutter:`, add the assets folder:
```yaml
  assets:
    - assets/audio/
```

- [ ] **Step 2: AudioService (crash-safe)**

`lib/services/audio_service.dart`:
```dart
import 'package:flame_audio/flame_audio.dart';
import '../settings/settings_controller.dart';

/// Plays short SFX, gated by the Sound Effects setting. Crash-safe: if the clips
/// are missing it silently no-ops (the game ships without bundled audio).
class AudioService {
  final SettingsController settings;
  bool _ready = false;

  AudioService(this.settings);

  static const _clips = ['strike.mp3', 'pocket.mp3', 'win.mp3', 'lose.mp3'];

  Future<void> init() async {
    try {
      await FlameAudio.audioCache.loadAll(_clips);
      _ready = true;
    } catch (_) {
      _ready = false; // files absent → stay silent
    }
  }

  void _play(String clip) {
    if (!_ready || !settings.settings.soundEffects) return;
    try {
      FlameAudio.play(clip);
    } catch (_) {/* ignore playback errors */}
  }

  void strike() => _play('strike.mp3');
  void pocket() => _play('pocket.mp3');
  void win() => _play('win.mp3');
  void lose() => _play('lose.mp3');
}
```

- [ ] **Step 3: Verify + commit**

Run `flutter analyze` and `flutter test` — clean + green.
```bash
git add pubspec.yaml pubspec.lock lib/services/audio_service.dart assets/audio/README.md
git commit -m "feat: add flame_audio + crash-safe AudioService"
```

---

## Task 2: Engine sound-trigger callbacks (TDD)

**Files:**
- Modify: `lib/game/engine/carrom_game.dart`
- Modify: `test/game/engine/carrom_game_test.dart`

- [ ] **Step 1: Failing test**

Append inside `main()` of `test/game/engine/carrom_game_test.dart`:
```dart
  testWidgets('onStrike fires on launch; onPocket fires on capture',
      (tester) async {
    final game = await _loaded(tester);
    var strikes = 0;
    var pockets = 0;
    game.onStrike = () => strikes++;
    game.onPocket = () => pockets++;

    game.launch(angleRadians: math.pi / 2, power: 0.5);
    expect(strikes, 1);

    // Teleport a coin onto a pocket and step → capture fires onPocket.
    final coin = game.coins.first;
    coin.body.setTransform(game.pockets.first.body.position.clone(), 0);
    for (var i = 0; i < 10; i++) {
      game.update(1 / 60);
    }
    expect(pockets, greaterThanOrEqualTo(1));
  });
```

- [ ] **Step 2: Run — expect failure.**

- [ ] **Step 3: Implement**

In `CarromGame`, add:
```dart
  /// Fired when a strike is launched (for SFX).
  void Function()? onStrike;

  /// Fired when a coin or striker is pocketed (for SFX).
  void Function()? onPocket;
```
In `launch(...)`, after `_strikeInFlight = true;`, add `onStrike?.call();`.
In `capture(BodyComponent body)`, inside each branch where a piece is actually newly captured (after setting `captured = true`), add `onPocket?.call();` (so it fires once per captured piece, not for already-captured).

- [ ] **Step 4: Run — expect pass.** Full suite green, analyze clean. Commit:
```bash
git add lib/game/engine/carrom_game.dart test/game/engine/carrom_game_test.dart
git commit -m "feat: CarromGame onStrike/onPocket sound-trigger callbacks"
```

---

## Task 3: Wire AudioService into GameScreen

**Files:**
- Modify: `lib/game/ui/game_screen.dart`

- [ ] **Step 1: Create + wire the service**

In `_GameScreenState`:
- Add `late final AudioService _audio;` Initialise in `initState` AFTER `_game` is created:
  ```dart
  _audio = AudioService(context.read<SettingsController>());
  _audio.init();
  _game.onStrike = _audio.strike;
  _game.onPocket = _audio.pocket;
  ```
  (Imports: `../../services/audio_service.dart`, `../../settings/settings_controller.dart`, provider.)
- In `_awardIfNeeded` / wherever `session.isOver` is first handled, play win/lose. Simplest: in `_handleStrikeComplete`'s `if (session.isOver)` branch, after `_awardIfNeeded(session)`:
  ```dart
  final humanWon = widget.args.mode == GameMode.vsComputer
      ? session.winner == Player.one
      : true;
  if (humanWon) {
    _audio.win();
  } else {
    _audio.lose();
  }
  ```
  (For twoPlayer, treat it as a win sound — someone won.)
- No teardown needed (FlameAudio manages its players).

- [ ] **Step 2: Verify + commit**

Run `flutter analyze` and `flutter test` — clean + green. (Existing GameScreen widget tests must still pass; the AudioService init is crash-safe and tests have no audio files — it stays silent and must not throw. If `FlameAudio.audioCache.loadAll` throws synchronously in the test environment, the try/catch in `init()` swallows it; confirm tests stay green.)
```bash
git add lib/game/ui/game_screen.dart
git commit -m "feat: play strike/pocket/win/lose SFX in-game (silent without clips)"
```

---

## Phase 5B Done — Definition of Done

- Engine fires `onStrike`/`onPocket`; GameScreen plays SFX for strike, pocket, win, lose, gated by the Sound Effects setting.
- Missing audio files → silent, no crash (tests pass with no clips bundled).
- `flutter test` green; `flutter analyze` clean.
- **Action for the owner:** add real clips to `assets/audio/` to hear sound.
- Next: **Phase 5C** — ads (google_mobile_ads, test IDs).

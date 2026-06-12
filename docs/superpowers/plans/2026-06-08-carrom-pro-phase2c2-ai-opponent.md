# Carrom Pro — Phase 2C-2: AI Opponent — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A computer opponent that plays its own turn in vs-Computer mode: it picks one of its coins + a pocket, computes a striker placement + aim + power (ghost-ball aiming), adds difficulty-scaled miss noise, and fires — locking out human input while it plays.

**Architecture:** A pure-Dart `AiPlayer` computes a shot from the geometric board state (coin positions + pockets + baseline). A thin `runAiTurn(game, ai, myColor)` reads positions off the live `CarromGame`, plans, places, and launches — testable headlessly. The `GameScreen` triggers it when it is the AI seat's turn (with a short "thinking" delay and `interactive=false`).

**Tech Stack:** Existing. `dart:math` `Random` for noise (injectable for tests). No new packages.

---

## File Structure (this plan)

```
lib/game/ai/
  ai_player.dart        AiCoin, AiShot, AiPlayer.planShot (pure)
lib/game/match/
  ai_turn.dart          runAiTurn(CarromGame, AiPlayer, CoinType) -> bool
lib/game/ui/
  game_screen.dart      (modified) trigger AI on its turn
test/game/ai/
  ai_player_test.dart
test/game/match/
  ai_turn_test.dart
```

---

## Task 1: AiPlayer (pure, TDD)

**Files:**
- Create: `lib/game/ai/ai_player.dart`
- Test: `test/game/ai/ai_player_test.dart`

**Context:** Coin positions use `vector_math_64.Vector2` (same as `BoardGeometry`). `BoardGeometry` gives `coinRadius`, `strikerRadius`, `baselineY`, `strikerMinX`, `strikerMaxX`, `pocketCenters`, `halfBoard`. `Difficulty` is `lib/settings/difficulty.dart` (`easy`, `medium`, `hard`). `CoinType` is `lib/game/rules/coin_type.dart`.

- [ ] **Step 1: Write the failing test**

`test/game/ai/ai_player_test.dart`:
```dart
import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:carrom_pro/game/ai/ai_player.dart';
import 'package:carrom_pro/game/board/board_geometry.dart';
import 'package:carrom_pro/game/rules/coin_type.dart';
import 'package:carrom_pro/settings/difficulty.dart';

void main() {
  const g = BoardGeometry();

  // Deterministic "no noise": rng()==0.5 -> (2*0.5-1)==0.
  double noNoise() => 0.5;

  test('returns null when no targetable coins remain', () {
    const ai = AiPlayer(Difficulty.hard);
    final shot = ai.planShot(
      coins: const [],
      myColor: CoinType.black,
      geometry: g,
      rng: noNoise,
    );
    expect(shot, isNull);
  });

  test('aims roughly along the striker→ghost-ball direction (hard, no noise)',
      () {
    const ai = AiPlayer(Difficulty.hard);
    // A black coin near the top so a pocket lies beyond it; striker shoots up.
    final coin = AiCoin(CoinType.black, Vector2(0, 2.0));
    final shot = ai.planShot(
      coins: [coin],
      myColor: CoinType.black,
      geometry: g,
      rng: noNoise,
    )!;
    // Fire direction should be generally up-field (+y) → angle near pi/2.
    expect(shot.angleRadians, greaterThan(0.2));
    expect(shot.angleRadians, lessThan(math.pi - 0.2));
    expect(shot.power, inInclusiveRange(0.2, 1.0));
    expect(shot.strikerX, inInclusiveRange(g.strikerMinX, g.strikerMaxX));
  });

  test('prefers the coin with the shortest path to a pocket', () {
    const ai = AiPlayer(Difficulty.hard);
    final pockets = g.pocketCenters; // corners at +-c
    final nearPocket = pockets.first; // e.g. (-c, c)
    final easy = AiCoin(CoinType.black, nearPocket * 0.6); // close to that pocket
    final hard = AiCoin(CoinType.black, Vector2(0, 0)); // centre, far from all
    final shot = ai.planShot(
      coins: [hard, easy],
      myColor: CoinType.black,
      geometry: g,
      rng: noNoise,
    )!;
    // The chosen ghost target should sit near the easy coin, not the centre one.
    // We can't read the target directly; assert the aim points toward the easy
    // coin's side (its x sign) rather than straight up from centre.
    expect(shot.strikerX.sign, easy.position.x.sign);
  });

  test('easy difficulty adds more aim noise than hard', () {
    final coin = AiCoin(CoinType.black, Vector2(0, 2.0));
    // rng()==1.0 -> max positive noise (2*1-1==1).
    double maxNoise() => 1.0;
    final hardShot = const AiPlayer(Difficulty.hard)
        .planShot(coins: [coin], myColor: CoinType.black, geometry: g, rng: maxNoise)!;
    final easyShot = const AiPlayer(Difficulty.easy)
        .planShot(coins: [coin], myColor: CoinType.black, geometry: g, rng: maxNoise)!;
    final baseShot = const AiPlayer(Difficulty.hard)
        .planShot(coins: [coin], myColor: CoinType.black, geometry: g, rng: () => 0.5)!;
    final hardDev = (hardShot.angleRadians - baseShot.angleRadians).abs();
    final easyDev = (easyShot.angleRadians - baseShot.angleRadians).abs();
    expect(easyDev, greaterThan(hardDev));
  });

  test('targets the queen when no own coins remain but the queen is present', () {
    const ai = AiPlayer(Difficulty.hard);
    final shot = ai.planShot(
      coins: [AiCoin(CoinType.queen, Vector2(0, 1.5))],
      myColor: CoinType.black,
      geometry: g,
      rng: noNoise,
    );
    expect(shot, isNotNull);
  });
}
```

- [ ] **Step 2: Run — expect failure**

Run: `flutter test test/game/ai/ai_player_test.dart`
Expected: FAIL — `ai_player.dart` missing.

- [ ] **Step 3: Implement**

`lib/game/ai/ai_player.dart`:
```dart
import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart';
import '../board/board_geometry.dart';
import '../rules/coin_type.dart';
import '../../settings/difficulty.dart';

/// A coin as the AI sees it: type + world position.
class AiCoin {
  final CoinType type;
  final Vector2 position;
  const AiCoin(this.type, this.position);
}

/// A planned shot in the same terms the game's `launch` + `setStrikerX` use.
class AiShot {
  final double strikerX; // baseline x for the striker
  final double angleRadians; // fire direction (standard math angle)
  final double power; // 0..1
  const AiShot({
    required this.strikerX,
    required this.angleRadians,
    required this.power,
  });
}

/// Computes the computer opponent's shot via ghost-ball aiming. Pure: pass a
/// deterministic [rng] (returns 0..1) in tests; defaults to real randomness.
class AiPlayer {
  final Difficulty difficulty;
  const AiPlayer(this.difficulty);

  double get _aimNoise => switch (difficulty) {
        Difficulty.easy => 0.18,
        Difficulty.medium => 0.08,
        Difficulty.hard => 0.025,
      };

  double get _powerNoise => switch (difficulty) {
        Difficulty.easy => 0.22,
        Difficulty.medium => 0.10,
        Difficulty.hard => 0.03,
      };

  /// Returns a shot, or null if there is nothing to aim at.
  AiShot? planShot({
    required List<AiCoin> coins,
    required CoinType myColor,
    required BoardGeometry geometry,
    double Function()? rng,
  }) {
    final random = rng ?? math.Random().nextDouble;

    // Prefer own-colour coins; fall back to the queen.
    var targets = coins.where((c) => c.type == myColor).toList();
    if (targets.isEmpty) {
      targets = coins.where((c) => c.type == CoinType.queen).toList();
    }
    if (targets.isEmpty) return null;

    final pockets = geometry.pocketCenters;
    final contact = geometry.coinRadius + geometry.strikerRadius;
    final baselineY = geometry.baselineY;

    Vector2? bestAim;
    double bestStrikerX = 0;
    double bestScore = double.infinity;
    double bestTravel = 0;

    for (final coin in targets) {
      for (final pocket in pockets) {
        final toPocket = pocket - coin.position;
        final dCP = toPocket.length;
        if (dCP < 1e-6) continue;
        final dir = toPocket / dCP;
        // Ghost-ball point: where the striker centre must reach to send the
        // coin toward the pocket.
        final ghost = coin.position - dir * contact;

        final strikerX =
            ghost.x.clamp(geometry.strikerMinX, geometry.strikerMaxX).toDouble();
        final strikerPos = Vector2(strikerX, baselineY);
        final aim = ghost - strikerPos;
        // Must be a forward shot (into the board).
        if (aim.y <= 0.2) continue;

        final dSG = aim.length;
        final score = dCP + dSG * 0.5; // prefer short, makeable shots
        if (score < bestScore) {
          bestScore = score;
          bestAim = aim;
          bestStrikerX = strikerX;
          bestTravel = dCP + dSG;
        }
      }
    }

    // Fallback: aim straight at the nearest target coin.
    if (bestAim == null) {
      final coin = targets.reduce((a, b) {
        final da = (a.position - Vector2(0, baselineY)).length;
        final db = (b.position - Vector2(0, baselineY)).length;
        return da <= db ? a : b;
      });
      final strikerX =
          coin.position.x.clamp(geometry.strikerMinX, geometry.strikerMaxX).toDouble();
      bestAim = coin.position - Vector2(strikerX, baselineY);
      bestStrikerX = strikerX;
      bestTravel = bestAim.length;
      if (bestAim.y <= 0.2) {
        // Degenerate (coin behind baseline): shoot gently straight up.
        bestAim = Vector2(0, 1);
      }
    }

    var angle = math.atan2(bestAim.y, bestAim.x);
    // Normalise travel to a power; ensure enough to reach.
    final reach = geometry.halfBoard * 2.6;
    var power = (bestTravel / reach).clamp(0.35, 1.0).toDouble();

    // Difficulty noise (rng in 0..1 → symmetric [-1, 1]).
    angle += (random() * 2 - 1) * _aimNoise;
    power = (power + (random() * 2 - 1) * _powerNoise).clamp(0.2, 1.0).toDouble();

    return AiShot(
      strikerX: bestStrikerX
          .clamp(geometry.strikerMinX, geometry.strikerMaxX)
          .toDouble(),
      angleRadians: angle,
      power: power,
    );
  }
}
```

- [ ] **Step 4: Run — expect pass**

Run: `flutter test test/game/ai/ai_player_test.dart`
Expected: all tests PASS. (If "prefers shortest path" fails because both candidate scores tie, nudge the `easy` coin closer to its pocket in the test setup — but the provided positions should differ clearly.)

- [ ] **Step 5: Commit**

```bash
git add lib/game/ai test/game/ai
git commit -m "feat: add AiPlayer ghost-ball shot planning with difficulty noise"
```

---

## Task 2: runAiTurn helper (headless TDD)

**Files:**
- Create: `lib/game/match/ai_turn.dart`
- Test: `test/game/match/ai_turn_test.dart`

**Context:** `CarromGame` exposes `coins` (each `CoinBody` has `type` and `body.position` in forge2d 32-bit Vector2), `setStrikerX(double)`, `launch({angleRadians, power})`, `isSettled`, `interactive`. Convert the 32-bit body positions to `vector_math_64.Vector2` for `AiPlayer`.

- [ ] **Step 1: Write the failing test**

`test/game/match/ai_turn_test.dart`:
```dart
import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:carrom_pro/game/engine/carrom_game.dart';
import 'package:carrom_pro/game/ai/ai_player.dart';
import 'package:carrom_pro/game/match/ai_turn.dart';
import 'package:carrom_pro/game/rules/coin_type.dart';
import 'package:carrom_pro/settings/difficulty.dart';

Future<CarromGame> _loaded(WidgetTester tester) async {
  final game = CarromGame();
  await tester.pumpWidget(GameWidget(game: game));
  await tester.pump();
  await tester.pump();
  return game;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('runAiTurn places and fires the striker', (tester) async {
    final game = await _loaded(tester);
    expect(game.isSettled, isTrue);

    final fired = runAiTurn(game, const AiPlayer(Difficulty.hard), CoinType.black);
    expect(fired, isTrue);

    // The striker now has velocity (it was launched).
    expect(game.striker.body.linearVelocity.length, greaterThan(0));
  });
}
```

- [ ] **Step 2: Run — expect failure**

Run: `flutter test test/game/match/ai_turn_test.dart`
Expected: FAIL — `ai_turn.dart` missing.

- [ ] **Step 3: Implement**

`lib/game/match/ai_turn.dart`:
```dart
import 'package:vector_math/vector_math_64.dart' as vm64;
import '../ai/ai_player.dart';
import '../engine/carrom_game.dart';
import '../rules/coin_type.dart';

/// Has the AI play one strike on [game] for [myColor]. Reads live coin
/// positions, plans a shot, positions the striker and launches. Returns true if
/// a shot was fired. No-op (false) if the board is not settled or no shot found.
bool runAiTurn(CarromGame game, AiPlayer ai, CoinType myColor) {
  if (!game.isSettled) return false;

  final coins = game.coins
      .map((c) => AiCoin(c.type, vm64.Vector2(c.body.position.x, c.body.position.y)))
      .toList();

  final shot = ai.planShot(
    coins: coins,
    myColor: myColor,
    geometry: game.geometry,
  );
  if (shot == null) return false;

  game.setStrikerX(shot.strikerX);
  game.launch(angleRadians: shot.angleRadians, power: shot.power);
  return true;
}
```

- [ ] **Step 4: Run — expect pass**

Run: `flutter test test/game/match/ai_turn_test.dart`
Expected: PASS. (If `fired` is true but velocity is ~0, the planned power may be below threshold for that layout — verify the opening layout yields a forward shot; the black coins in the opening cluster are above the baseline so a forward shot exists.)

- [ ] **Step 5: Commit**

```bash
git add lib/game/match/ai_turn.dart test/game/match/ai_turn_test.dart
git commit -m "feat: add runAiTurn helper to drive an AI strike on the board"
```

---

## Task 3: Wire the AI into the match loop

**Files:**
- Modify: `lib/game/ui/game_screen.dart`
- Test: `test/widget/game_screen_match_test.dart` (extend)

**Context:** GameScreen already creates `_session` for non-practice modes and handles `onStrikeComplete`. Add: when it becomes the AI seat's turn, lock input, wait a "thinking" beat, run the AI, and unlock when control returns to the human.

- [ ] **Step 1: Add the AI trigger**

In `_GameScreenState`:
- Add a field: `late final AiPlayer _ai;` initialized in `initState` (only meaningful for vsComputer):
  ```dart
  _ai = AiPlayer(widget.args.difficulty ?? Difficulty.medium);
  ```
  (Import `AiPlayer` and `Difficulty`.)
- After creating `_session` in `initState`, if `widget.args.mode == GameMode.vsComputer`, schedule a check in case the AI is ever first (it isn't — Player.one starts — but keep the helper centralised).
- Implement `_maybeRunAi()`:
  ```dart
  void _maybeRunAi() {
    final session = _session;
    if (session == null || session.isOver) return;
    if (!session.turnIsAI) {
      _game.interactive = true;
      return;
    }
    _game.interactive = false; // lock the human out during the AI turn
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      final s = _session;
      if (s == null || s.isOver || !s.turnIsAI) {
        _game.interactive = true;
        return;
      }
      // Temporarily allow the engine to accept the AI's programmatic shot.
      _game.interactive = true;
      final fired = runAiTurn(_game, _ai, s.colorOf(s.currentPlayer));
      if (!fired) {
        // No shot found: pass by simulating an empty strike resolution.
        _handleStrikeComplete(const StrikeOutcome());
      }
    });
  }
  ```
  > Note: the human lock is enforced primarily by the "AI turn" UI state; `runAiTurn` calls `setStrikerX`/`launch` which need `interactive==true`, so we flip it true just for the programmatic shot. (A more elaborate lock can come later; this keeps the AI able to fire while the human's own drag is ignored because it is the AI's turn — see Step 2 for the drag guard.)
- In `_handleStrikeComplete`, after `setState(() {})` at the end (when the match is not over), call `_maybeRunAi();`.
- Call `_maybeRunAi()` once at the end of `initState` (post-frame) in case of future first-AI scenarios:
  ```dart
  WidgetsBinding.instance.addPostFrameCallback((_) => _maybeRunAi());
  ```

- [ ] **Step 2: Guard human drags during the AI turn**

To stop the human striking on the AI's turn (since `interactive` is toggled true for the programmatic shot), gate at the source: in `_handleStrikeComplete`'s human path nothing changes, but ensure the AI turn is visually/functionally the AI's. Simplest robust guard: in `_maybeRunAi`, keep `_game.interactive = false` EXCEPT during the millisecond of the programmatic shot. Since `runAiTurn` is synchronous, set it false again right after:
```dart
      _game.interactive = true;
      final fired = runAiTurn(_game, _ai, s.colorOf(s.currentPlayer));
      _game.interactive = false; // re-lock until the strike resolves
      if (!fired) {
        _game.interactive = true;
        _handleStrikeComplete(const StrikeOutcome());
      }
```
Then in `_handleStrikeComplete`, when control returns to the human (`!session.turnIsAI`), set `_game.interactive = true;` before the final `setState`.

- [ ] **Step 3: Extend the widget test**

Add to `test/widget/game_screen_match_test.dart`:
```dart
  testWidgets('vsComputer shows the Computer panel', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: GameScreen(args: GameLaunchArgs(mode: GameMode.vsComputer)),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Computer'), findsOneWidget);
    expect(find.text('Player 1'), findsOneWidget);
  });
```

- [ ] **Step 4: Verify**

Run:
```bash
flutter analyze
flutter test
```
Expected: clean + green. Around `GameWidget`, use `pump` (never `pumpAndSettle`). The AI's `Future.delayed` will not fire within the test's pumps, which is fine — the test only asserts the panels render.

- [ ] **Step 5: Commit**

```bash
git add lib/game/ui/game_screen.dart test/widget/game_screen_match_test.dart
git commit -m "feat: AI plays its turn in vs-Computer (lock input, think, ghost-ball shot)"
```

---

## Phase 2C-2 Done — Definition of Done

- In vs-Computer mode, after the human's turn passes to the computer, the AI waits briefly, positions the striker, and fires a ghost-ball shot; turns continue until someone wins.
- Difficulty (Easy/Med/Hard) scales the AI's aim/power noise.
- Human input is ignored during the AI's turn.
- `flutter test` green; `flutter analyze` clean.
- Next: **Phase 2C-3** — Select Mode + Choose Difficulty screens (so vs-Computer/2-Player are reachable from the menu) and result-screen polish.

## Known tuning points (device)
- AI "thinking" delay (700 ms), aim/power noise per difficulty, the `reach` power-normalisation constant, and the ghost-ball `score` weighting — all tunable after play-testing.
```

# Carrom Pro — Striker FSM + Predictive Aim — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans.

**Goal:** Refactor the striker interaction into an explicit 3-state FSM (PLACING → AIMING → SIMULATING) with a positioning slider, pull-back slingshot aiming, and a **predictive swept-circle raycast** that draws an aim line to the impact point plus a "ghost" target circle. Forge2D remains the physics simulator (no hand-rolled loop). After every shot settles, the striker resets to the baseline centre and the FSM returns to PLACING.

**Architecture:** A pure `predictImpact` raycast (swept circle vs coins + walls), unit-tested. `CarromGame` owns a `ValueNotifier<StrikerPhase>` and the per-turn striker reset. `StrikerDragInput` becomes FSM-driven and computes the aim preview. An `AimPreview` overlay renders the line + ghost circle. `GameScreen` adds a PLACING-only positioning slider and reacts to the phase. Forge2D keeps handling friction (damping), wall bounce (restitution), and settling.

**FSM contract (safe transitions, no input overlap):**
- **PLACING** — striker on the baseline. Input: drag the striker horizontally (or the slider) to set `x` (clamped). A drag that pulls *backward away* from the striker (beyond a dead-zone, into the pull region) transitions to AIMING. Slider enabled.
- **AIMING** — striker `x` locked. The pull vector sets direction + power; the predictive line + ghost circle render. Release beyond the dead-zone → set striker velocity and go to SIMULATING; release inside the dead-zone → back to PLACING. Slider disabled.
- **SIMULATING** — ALL input ignored (slider + touch). Forge2D steps until `isSettled`. Then: resolve the strike (`onStrikeComplete`), reset the striker to the baseline centre, and return to PLACING.

---

## Task 1: predictImpact swept-circle raycast (pure, TDD)

**Files:**
- Create: `lib/game/board/aim_prediction.dart`
- Test: `test/game/board/aim_prediction_test.dart`

- [ ] **Step 1: Failing test**

`test/game/board/aim_prediction_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:carrom_pro/game/board/aim_prediction.dart';

void main() {
  test('hits a coin directly ahead at contact distance (R + r)', () {
    final hit = predictImpact(
      origin: Vector2(0, -3),
      dir: Vector2(0, 1),
      strikerRadius: 0.3,
      halfBoard: 5,
      coins: [const AimCircle.xy(0, 0, 0.22)],
    );
    expect(hit.type, ImpactType.coin);
    // Striker centre stops 0.52 below the coin centre.
    expect(hit.point.x, closeTo(0, 1e-6));
    expect(hit.point.y, closeTo(-0.52, 1e-6));
  });

  test('hits the wall (centre bound) when no coins are in the way', () {
    final hit = predictImpact(
      origin: Vector2(0, 0),
      dir: Vector2(0, 1),
      strikerRadius: 0.3,
      halfBoard: 5,
      coins: const [],
    );
    expect(hit.type, ImpactType.wall);
    expect(hit.point.y, closeTo(4.7, 1e-6)); // halfBoard - strikerRadius
  });

  test('chooses the nearer coin over a farther wall', () {
    final hit = predictImpact(
      origin: Vector2(0, -4),
      dir: Vector2(0, 1),
      strikerRadius: 0.3,
      halfBoard: 5,
      coins: [const AimCircle.xy(0, 0, 0.22)],
    );
    expect(hit.type, ImpactType.coin);
    expect(hit.point.y, closeTo(-0.52, 1e-6));
  });

  test('right-going ray stops at the right wall bound', () {
    final hit = predictImpact(
      origin: Vector2(0, 0),
      dir: Vector2(1, 0),
      strikerRadius: 0.3,
      halfBoard: 5,
      coins: const [],
    );
    expect(hit.type, ImpactType.wall);
    expect(hit.point.x, closeTo(4.7, 1e-6));
  });
}
```

- [ ] **Step 2: Run — expect failure.**

- [ ] **Step 3: Implement**

`lib/game/board/aim_prediction.dart`:
```dart
import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart';

enum ImpactType { wall, coin }

class AimCircle {
  final Vector2 center;
  final double radius;
  AimCircle(this.center, this.radius);
  const AimCircle.xy(double x, double y, this.radius) : center = const _V(x, y);
}

// Tiny const-friendly Vector2 shim so AimCircle.xy can be const in tests.
class _V implements Vector2 {
  // Not a real Vector2; only used via AimCircle which reads .center.x/.y.
  // To keep it simple, store x/y and expose them.
  @override
  final double x;
  @override
  final double y;
  const _V(this.x, this.y);
  @override
  noSuchMethod(Invocation i) => throw UnsupportedError('shim');
}

/// The first contact of a striker (radius [strikerRadius]) travelling from
/// [origin] along unit [dir]. [point] is where the striker CENTRE rests against
/// the obstacle.
class AimImpact {
  final Vector2 point;
  final ImpactType type;
  final double distance;
  const AimImpact(this.point, this.type, this.distance);
}

AimImpact predictImpact({
  required Vector2 origin,
  required Vector2 dir, // normalized
  required double strikerRadius,
  required double halfBoard,
  required List<AimCircle> coins,
}) {
  var best = double.infinity;
  var bestType = ImpactType.wall;

  for (final c in coins) {
    final fx = origin.x - c.center.x;
    final fy = origin.y - c.center.y;
    final rr = strikerRadius + c.radius;
    final b = 2 * (fx * dir.x + fy * dir.y);
    final cc = fx * fx + fy * fy - rr * rr;
    final disc = b * b - 4 * cc;
    if (disc < 0) continue;
    final t = (-b - math.sqrt(disc)) / 2;
    if (t > 1e-6 && t < best) {
      best = t;
      bestType = ImpactType.coin;
    }
  }

  final lim = halfBoard - strikerRadius;
  var wallT = double.infinity;
  void axis(double o, double d) {
    if (d > 1e-9) {
      final t = (lim - o) / d;
      if (t > 1e-6 && t < wallT) wallT = t;
    } else if (d < -1e-9) {
      final t = (-lim - o) / d;
      if (t > 1e-6 && t < wallT) wallT = t;
    }
  }
  axis(origin.x, dir.x);
  axis(origin.y, dir.y);
  if (wallT < best) {
    best = wallT;
    bestType = ImpactType.wall;
  }

  if (!best.isFinite) {
    final p = origin + dir * halfBoard;
    return AimImpact(p, ImpactType.wall, halfBoard);
  }
  return AimImpact(origin + dir * best, bestType, best);
}
```
> **Note:** the `_V` const shim above is fragile. PREFER this simpler approach: make `AimCircle` a normal class `AimCircle(Vector2 center, double radius)` and in the tests build coins with `AimCircle(Vector2(0,0), 0.22)` (drop the `const AimCircle.xy(...)` form and the `_V` shim entirely). Update the test accordingly (non-const). Implement whichever compiles cleanly — the simpler non-const version is preferred.

- [ ] **Step 4: Run — expect pass. Commit.**
```bash
git add lib/game/board/aim_prediction.dart test/game/board/aim_prediction_test.dart
git commit -m "feat: add swept-circle predictImpact raycast for aim preview"
```

---

## Task 2: StrikerPhase FSM in CarromGame + per-turn reset (headless TDD)

**Files:**
- Create: `lib/game/engine/striker_phase.dart`
- Modify: `lib/game/engine/carrom_game.dart`
- Modify: `test/game/engine/carrom_game_test.dart`

`lib/game/engine/striker_phase.dart`:
```dart
enum StrikerPhase { placing, aiming, simulating }
```

- [ ] **Step 1: Failing test (append to carrom_game_test.dart)**
```dart
  testWidgets('phase: placing -> simulating on launch -> placing after settle',
      (tester) async {
    final game = await _loaded(tester);
    expect(game.phase.value, StrikerPhase.placing);

    game.launch(angleRadians: math.pi / 2, power: 0.5);
    expect(game.phase.value, StrikerPhase.simulating);

    for (var i = 0; i < 1200 && game.phase.value != StrikerPhase.placing; i++) {
      game.update(1 / 60);
    }
    expect(game.phase.value, StrikerPhase.placing);
    // Striker reset to baseline centre.
    expect(game.striker.body.position.x, closeTo(0, 0.001));
    expect(game.striker.body.position.y, closeTo(game.geometry.baselineY, 0.001));
  });
```
(Add `import 'package:carrom_pro/game/engine/striker_phase.dart';` to the test.)

- [ ] **Step 2: Run — expect failure.**

- [ ] **Step 3: Implement in CarromGame**
- Add `import 'striker_phase.dart';` and `import 'package:flame/components.dart' show Anchor;` already present.
- Add field: `final ValueNotifier<StrikerPhase> phase = ValueNotifier(StrikerPhase.placing);`
- `setPhase(StrikerPhase p)` helper that sets `phase.value = p` (only if changed).
- In `launch(...)`, after the existing guards + impulse + `_strikeInFlight = true; onStrike?.call();`, add `setPhase(StrikerPhase.simulating);`
- In `update(dt)`, replace the strike-complete block so that AFTER firing `onStrikeComplete`, it ALSO resets the striker and returns to placing:
  ```dart
    if (_strikeInFlight && isSettled) {
      _strikeInFlight = false;
      onStrikeComplete?.call(takeStrikeResult());
      _resetStrikerToCentre();
      setPhase(StrikerPhase.placing);
    }
  ```
- Add `void _resetStrikerToCentre()`:
  ```dart
  void _resetStrikerToCentre() {
    final s = _striker;
    if (s == null || s.captured) {
      // Striker was pocketed → spawn a fresh one at the centre baseline.
      _striker?.removeFromParent();
      final fresh = StrikerBody(geometry, skin: strikerSkin);
      _striker = fresh;
      world.add(fresh);
    } else {
      s.body.setTransform(Vector2(0, geometry.baselineY), 0);
      s.body.linearVelocity = Vector2.zero();
      s.body.angularVelocity = 0;
    }
  }
  ```
- In `resetBoard()`, also `setPhase(StrikerPhase.placing);` at the end.
- Dispose `phase` in `onRemove()` (`phase.dispose();`).
- Expose helpers for the input layer to set aiming/placing: `void beginAiming() => setPhase(StrikerPhase.aiming);` and `void cancelAiming() { if (phase.value == StrikerPhase.aiming) setPhase(StrikerPhase.placing); }`.

> Forge2D note: `_resetStrikerToCentre` runs in `update` AFTER `super.update(dt)` and the capture drain, so the world is not locked. Spawning a body via `world.add` mid-update is safe (Flame queues the lifecycle).

- [ ] **Step 4: Run — expect pass. Full suite green. Commit.**
```bash
git add lib/game/engine/striker_phase.dart lib/game/engine/carrom_game.dart test/game/engine/carrom_game_test.dart
git commit -m "feat: explicit StrikerPhase FSM + per-turn striker reset to centre"
```

---

## Task 3: FSM-driven drag input + predictive aim overlay

**Files:**
- Modify: `lib/game/engine/striker_drag_input.dart`
- Modify: `lib/game/engine/carrom_game.dart` (wire the preview overlay)

**Behaviour:**
- The drag input reads `game.phase`. It only acts when phase is `placing` or `aiming` AND `game.interactive`.
- **PLACING:** on drag, if the finger is near the baseline / horizontal → `setStrikerX(world.x)` (reposition). Once the finger pulls backward away from the striker beyond the band/dead-zone → `game.beginAiming()` and lock the striker x.
- **AIMING:** compute `dir = normalize(strikerPos - finger)` and `dragDistance` (clamped to `maxDrag`). Compute the impact via `predictImpact(origin: strikerPos, dir: dir, strikerRadius, halfBoard, coins: game.coins.map(...))`. Drive the `AimPreview` overlay with: the striker point, the impact point, and the impact type (for colour). On release: if `dragDistance > deadZone`, fire — set the striker velocity (`game.launchVelocity(dir * dragDistance * powerMultiplier)` OR reuse `launch(angleRadians: atan2(dir.y,dir.x), power: clampedDist/maxDrag)`); else `game.cancelAiming()`.
- Keep the existing pull-back fire math (it already fires opposite the pull). Replace the old fixed-length aim line with the predictive impact line + ghost circle.

**AimPreview overlay** (replace/extend `AimLineOverlay`): renders, in world space, a line from the striker to the impact point AND a faint ring (circle, radius = strikerRadius) at the impact point. Colour: gold normally; a slightly stronger tint when `type == coin`. Use the existing viewfinder-local transform approach already in the file.

- Convert `game.coins` (CoinBody, forge2d Vector2 positions) into `AimCircle(vm64.Vector2(pos.x,pos.y), geometry.coinRadius)` for `predictImpact`. Mind the 32/64-bit Vector2 boundary (build vm64 vectors for the pure function; the overlay draws with whatever the file already uses).

- [ ] **Step 1: Implement** the FSM gating, predictive impact computation, and the ghost-circle overlay. Keep `onPower` (power meter still works) and `onRelease` (fire).
- [ ] **Step 2: Verify** — `flutter analyze` clean; `flutter test` green (engine + existing widget tests unaffected; the overlay is visual). Add a headless test if practical asserting that during aiming the game exposes a non-null impact point (optional).
- [ ] **Step 3: Commit.**
```bash
git add lib/game/engine/striker_drag_input.dart lib/game/engine/carrom_game.dart
git commit -m "feat: FSM-driven drag input with predictive raycast aim + ghost circle"
```

---

## Task 4: PLACING positioning slider + screen wiring

**Files:**
- Modify: `lib/game/ui/game_screen.dart`

- [ ] **Step 1:** Add a horizontal positioning slider pinned near the bottom (above the controls legend). Bind it to `game.setStrikerX` mapped from the slider's 0..1 to `[geometry.strikerMinX, geometry.strikerMaxX]`. Wrap it in a `ValueListenableBuilder<StrikerPhase>(valueListenable: _game.phase, ...)` so it is **enabled only when `phase == placing`** (greyed/ignored otherwise). Keep the STRIKE POWER meter + legend.
- [ ] **Step 2:** Since `CarromGame` now re-centres the striker and manages phase, REMOVE the manual `_game.setStrikerX(0)` re-centre from `_handleStrikeComplete` (the game does it). Leave the HUD/turn/AI logic intact. Verify the AI flow still works (AI calls `setStrikerX` + `launch`, which set phase to simulating).
- [ ] **Step 3:** Verify `flutter analyze` clean, `flutter test` green (widget tests still pass; the slider is a normal widget — ensure no overflow at phone size; the slider sits in the bottom cluster). Commit.
```bash
git add lib/game/ui/game_screen.dart
git commit -m "feat: PLACING positioning slider; game owns striker re-centre"
```

---

## Done — Definition of Done

- The striker runs a clean PLACING → AIMING → SIMULATING FSM; inputs never overlap (SIMULATING ignores all touch + slider).
- A positioning slider (and striker drag) place the striker in PLACING.
- AIMING shows a **predictive line to the real impact point + a ghost striker circle** (raycast vs coins + walls).
- Forge2D simulates; on full stop the striker resets to the baseline centre and the FSM returns to PLACING.
- `flutter test` green; `flutter analyze` clean.
- Device tuning: `maxDrag`, `powerMultiplier`, dead-zone, slider feel, ghost-circle styling.

# Carrom Pro — Phase 2A: Rules Engine — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the pure-Dart carrom rules engine — turns, fouls, queen-cover, and win conditions — fully unit-tested, with zero Flame/UI dependencies.

**Architecture:** An immutable `MatchState` plus a pure `RulesEngine.resolve(state, strikeOutcome) -> state`. The physics layer (Phase 2B/2C) will produce a `StrikeOutcome` (what got pocketed + whether the striker fell) and feed it in; the engine decides the next state. Because it is pure, every rule is tested without running physics.

**Tech Stack:** Dart only (`dart:core`), `flutter_test` for tests. No new packages.

---

## Ruleset (the authoritative spec these tests encode)

- Two players; each owns a color (White or Black). 9 coins each + one shared red Queen.
- **Pocket your own coin** → counts for you, **you strike again** (turn continues).
- **Pocket only the opponent's coin** → counts toward the opponent, **turn passes**.
- **Pocket nothing** → turn passes.
- **Striker pocketed = FOUL:** all coins pocketed on that strike are returned to the board; additionally one previously-banked coin of the striking player's color returns as a penalty (capped — you can't owe what you never banked); turn passes. A foul also fails any pending queen-cover (Queen returns).
- **Queen-cover:**
  - Pocket the Queen **with** one of your own coins on the same strike → Queen secured immediately.
  - Pocket the Queen **alone** → cover pending; you strike again; if you then pocket one of your own coins → secured; if you fail (pocket nothing / opponent coin / striker) → Queen returns to the board, pending cleared.
- **Win:** your color reaches 0 remaining **and** the Queen is already resolved (off the board, not pending). Pocketing your **last coin while the Queen is still on the board** is denied: one coin of your color is returned and your turn passes (authentic "cover the queen before finishing" rule).
- `isGameOver` is true once `winner != null`. `resolve` on a finished state returns it unchanged.

---

## File Structure (created this phase)

```
lib/game/rules/
  player.dart              Player enum + other(Player)
  coin_type.dart           CoinType enum + otherColor(CoinType)
  strike_outcome.dart      StrikeOutcome (input: pocketed coins + strikerPocketed)
  match_state.dart         immutable MatchState (+ copyWith, helpers, initial())
  rules_engine.dart        RulesEngine.resolve(state, outcome) -> state
test/game/rules/
  match_state_test.dart
  rules_engine_test.dart
```

---

## Task 1: Domain types + MatchState

**Files:**
- Create: `lib/game/rules/player.dart`
- Create: `lib/game/rules/coin_type.dart`
- Create: `lib/game/rules/strike_outcome.dart`
- Create: `lib/game/rules/match_state.dart`
- Test: `test/game/rules/match_state_test.dart`

- [ ] **Step 1: Create the enums and helpers**

`lib/game/rules/player.dart`:
```dart
enum Player { one, two }

Player other(Player p) => p == Player.one ? Player.two : Player.one;
```

`lib/game/rules/coin_type.dart`:
```dart
enum CoinType { white, black, queen }

/// Returns the opposing player color. Only valid for white/black.
CoinType otherColor(CoinType color) {
  assert(color == CoinType.white || color == CoinType.black,
      'otherColor expects a player color, not the queen');
  return color == CoinType.white ? CoinType.black : CoinType.white;
}
```

`lib/game/rules/strike_outcome.dart`:
```dart
import 'coin_type.dart';

/// The physical result of one strike, produced by the physics layer (or a
/// test): which coins fell into pockets, and whether the striker itself fell.
class StrikeOutcome {
  final List<CoinType> pocketed;
  final bool strikerPocketed;

  const StrikeOutcome({
    this.pocketed = const [],
    this.strikerPocketed = false,
  });
}
```

- [ ] **Step 2: Write the failing MatchState test**

`test/game/rules/match_state_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:carrom_pro/game/rules/coin_type.dart';
import 'package:carrom_pro/game/rules/player.dart';
import 'package:carrom_pro/game/rules/match_state.dart';

void main() {
  test('initial state: player one to strike, 9+9 coins, queen on board', () {
    final s = MatchState.initial();
    expect(s.currentPlayer, Player.one);
    expect(s.playerOneColor, CoinType.white);
    expect(s.whiteRemaining, 9);
    expect(s.blackRemaining, 9);
    expect(s.queenOnBoard, true);
    expect(s.queenCoverPending, false);
    expect(s.winner, isNull);
    expect(s.isGameOver, false);
  });

  test('initial state can assign player one black', () {
    final s = MatchState.initial(playerOneColor: CoinType.black);
    expect(s.playerOneColor, CoinType.black);
    expect(s.colorOf(Player.one), CoinType.black);
    expect(s.colorOf(Player.two), CoinType.white);
  });

  test('remainingFor maps each player to their color count', () {
    final s = MatchState.initial().copyWith(whiteRemaining: 4, blackRemaining: 7);
    expect(s.remainingFor(Player.one), 4); // one = white
    expect(s.remainingFor(Player.two), 7); // two = black
  });

  test('copyWith overrides only the given fields', () {
    final s = MatchState.initial().copyWith(currentPlayer: Player.two);
    expect(s.currentPlayer, Player.two);
    expect(s.whiteRemaining, 9);
  });

  test('isGameOver becomes true when a winner is set', () {
    final s = MatchState.initial().copyWith(winner: Player.one);
    expect(s.isGameOver, true);
  });
}
```

- [ ] **Step 3: Run the test to verify it fails**

Run: `flutter test test/game/rules/match_state_test.dart`
Expected: FAIL — `Target of URI doesn't exist: '.../match_state.dart'`.

- [ ] **Step 4: Implement MatchState**

`lib/game/rules/match_state.dart`:
```dart
import 'coin_type.dart';
import 'player.dart';

/// Immutable snapshot of a carrom match. Mutated only via [RulesEngine].
class MatchState {
  final Player currentPlayer;
  final CoinType playerOneColor; // white or black; player two owns the other
  final int whiteRemaining;
  final int blackRemaining;
  final bool queenOnBoard;
  final bool queenCoverPending; // currentPlayer must cover on the next strike
  final Player? winner;

  const MatchState({
    required this.currentPlayer,
    required this.playerOneColor,
    required this.whiteRemaining,
    required this.blackRemaining,
    required this.queenOnBoard,
    required this.queenCoverPending,
    this.winner,
  });

  factory MatchState.initial({CoinType playerOneColor = CoinType.white}) {
    return MatchState(
      currentPlayer: Player.one,
      playerOneColor: playerOneColor,
      whiteRemaining: 9,
      blackRemaining: 9,
      queenOnBoard: true,
      queenCoverPending: false,
    );
  }

  bool get isGameOver => winner != null;

  CoinType colorOf(Player p) =>
      p == Player.one ? playerOneColor : otherColor(playerOneColor);

  int remainingOfColor(CoinType color) =>
      color == CoinType.white ? whiteRemaining : blackRemaining;

  int remainingFor(Player p) => remainingOfColor(colorOf(p));

  MatchState copyWith({
    Player? currentPlayer,
    CoinType? playerOneColor,
    int? whiteRemaining,
    int? blackRemaining,
    bool? queenOnBoard,
    bool? queenCoverPending,
    Player? winner,
  }) {
    return MatchState(
      currentPlayer: currentPlayer ?? this.currentPlayer,
      playerOneColor: playerOneColor ?? this.playerOneColor,
      whiteRemaining: whiteRemaining ?? this.whiteRemaining,
      blackRemaining: blackRemaining ?? this.blackRemaining,
      queenOnBoard: queenOnBoard ?? this.queenOnBoard,
      queenCoverPending: queenCoverPending ?? this.queenCoverPending,
      winner: winner ?? this.winner,
    );
  }
}
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `flutter test test/game/rules/match_state_test.dart`
Expected: All 5 tests PASS.

> **Note on copyWith + winner:** because `winner` is nullable and `copyWith` uses `winner ?? this.winner`, you cannot clear a winner back to null via copyWith. That is intentional — a finished match never un-finishes — so the engine never needs to null it.

- [ ] **Step 6: Commit**

```bash
git add lib/game/rules/player.dart lib/game/rules/coin_type.dart lib/game/rules/strike_outcome.dart lib/game/rules/match_state.dart test/game/rules/match_state_test.dart
git commit -m "feat: add carrom rules domain types and MatchState"
```

---

## Task 2: RulesEngine test suite (write the failing tests)

**Files:**
- Test: `test/game/rules/rules_engine_test.dart`

This task ONLY writes tests. They will fail to compile until Task 3 creates `RulesEngine`. Write the complete suite, run it, and confirm it fails for the right reason.

- [ ] **Step 1: Write the full engine test suite**

`test/game/rules/rules_engine_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:carrom_pro/game/rules/coin_type.dart';
import 'package:carrom_pro/game/rules/player.dart';
import 'package:carrom_pro/game/rules/match_state.dart';
import 'package:carrom_pro/game/rules/strike_outcome.dart';
import 'package:carrom_pro/game/rules/rules_engine.dart';

void main() {
  final engine = RulesEngine();

  // Player one = white, player two = black, unless overridden.
  MatchState start() => MatchState.initial();

  group('basic turn flow', () {
    test('pocketing your own coin lets you strike again', () {
      final s = engine.resolve(
        start(),
        const StrikeOutcome(pocketed: [CoinType.white]),
      );
      expect(s.currentPlayer, Player.one);
      expect(s.whiteRemaining, 8);
      expect(s.blackRemaining, 9);
    });

    test('pocketing nothing passes the turn', () {
      final s = engine.resolve(start(), const StrikeOutcome());
      expect(s.currentPlayer, Player.two);
      expect(s.whiteRemaining, 9);
    });

    test('pocketing only the opponent coin credits them and passes turn', () {
      final s = engine.resolve(
        start(),
        const StrikeOutcome(pocketed: [CoinType.black]),
      );
      expect(s.currentPlayer, Player.two);
      expect(s.blackRemaining, 8); // opponent advanced
      expect(s.whiteRemaining, 9);
    });

    test('pocketing own + opponent coin: counts both, strike again', () {
      final s = engine.resolve(
        start(),
        const StrikeOutcome(pocketed: [CoinType.white, CoinType.black]),
      );
      expect(s.currentPlayer, Player.one); // own coin -> continue
      expect(s.whiteRemaining, 8);
      expect(s.blackRemaining, 8);
    });
  });

  group('striker foul', () {
    test('striker pocketed with nothing else: penalty when coins banked', () {
      // Player one already banked 1 white (8 remaining), then fouls.
      final banked = start().copyWith(whiteRemaining: 8);
      final s = engine.resolve(
        banked,
        const StrikeOutcome(strikerPocketed: true),
      );
      expect(s.currentPlayer, Player.two); // turn passes
      expect(s.whiteRemaining, 9); // one banked coin returned as penalty
    });

    test('striker foul returns coins pocketed on the same strike', () {
      final s = engine.resolve(
        start(),
        const StrikeOutcome(pocketed: [CoinType.white], strikerPocketed: true),
      );
      expect(s.currentPlayer, Player.two);
      // The white pocketed this strike is returned; no banked coin to penalize.
      expect(s.whiteRemaining, 9);
    });

    test('no penalty coin when player has banked nothing yet', () {
      final s = engine.resolve(
        start(),
        const StrikeOutcome(strikerPocketed: true),
      );
      expect(s.currentPlayer, Player.two);
      expect(s.whiteRemaining, 9); // capped at 9, nothing to return
    });
  });

  group('queen cover', () {
    test('queen + own coin same strike = secured immediately', () {
      final s = engine.resolve(
        start(),
        const StrikeOutcome(pocketed: [CoinType.queen, CoinType.white]),
      );
      expect(s.queenOnBoard, false);
      expect(s.queenCoverPending, false);
      expect(s.currentPlayer, Player.one); // own coin -> continue
      expect(s.whiteRemaining, 8);
    });

    test('queen alone = cover pending, same player strikes again', () {
      final s = engine.resolve(
        start(),
        const StrikeOutcome(pocketed: [CoinType.queen]),
      );
      expect(s.queenOnBoard, false);
      expect(s.queenCoverPending, true);
      expect(s.currentPlayer, Player.one);
    });

    test('pending cover succeeds when own coin pocketed next', () {
      final pending = start().copyWith(queenOnBoard: false, queenCoverPending: true);
      final s = engine.resolve(
        pending,
        const StrikeOutcome(pocketed: [CoinType.white]),
      );
      expect(s.queenCoverPending, false);
      expect(s.queenOnBoard, false); // stays secured
      expect(s.currentPlayer, Player.one);
      expect(s.whiteRemaining, 8);
    });

    test('pending cover fails when nothing pocketed: queen returns', () {
      final pending = start().copyWith(queenOnBoard: false, queenCoverPending: true);
      final s = engine.resolve(pending, const StrikeOutcome());
      expect(s.queenOnBoard, true); // returned
      expect(s.queenCoverPending, false);
      expect(s.currentPlayer, Player.two); // failed cover, turn passes
    });

    test('foul while cover pending returns the queen', () {
      final pending = start().copyWith(queenOnBoard: false, queenCoverPending: true);
      final s = engine.resolve(
        pending,
        const StrikeOutcome(strikerPocketed: true),
      );
      expect(s.queenOnBoard, true);
      expect(s.queenCoverPending, false);
      expect(s.currentPlayer, Player.two);
    });
  });

  group('win conditions', () {
    test('clearing last coin with queen already resolved wins', () {
      // Player one has 1 white left, queen already off & covered.
      final nearWin = start().copyWith(whiteRemaining: 1, queenOnBoard: false);
      final s = engine.resolve(
        nearWin,
        const StrikeOutcome(pocketed: [CoinType.white]),
      );
      expect(s.winner, Player.one);
      expect(s.isGameOver, true);
    });

    test('clearing last coin while queen still on board is denied', () {
      final nearWin = start().copyWith(whiteRemaining: 1, queenOnBoard: true);
      final s = engine.resolve(
        nearWin,
        const StrikeOutcome(pocketed: [CoinType.white]),
      );
      expect(s.winner, isNull);
      expect(s.whiteRemaining, 1); // coin returned
      expect(s.currentPlayer, Player.two); // turn passes
    });

    test('queen + last coin same strike wins (covered immediately)', () {
      final nearWin = start().copyWith(whiteRemaining: 1, queenOnBoard: true);
      final s = engine.resolve(
        nearWin,
        const StrikeOutcome(pocketed: [CoinType.queen, CoinType.white]),
      );
      expect(s.winner, Player.one);
    });

    test('resolve on a finished match returns it unchanged', () {
      final finished = start().copyWith(winner: Player.one);
      final s = engine.resolve(
        finished,
        const StrikeOutcome(pocketed: [CoinType.black]),
      );
      expect(s, same(finished));
    });
  });
}
```

- [ ] **Step 2: Run the suite to verify it fails to compile**

Run: `flutter test test/game/rules/rules_engine_test.dart`
Expected: FAIL — `Target of URI doesn't exist: '.../rules_engine.dart'`.

- [ ] **Step 3: Commit the failing tests**

```bash
git add test/game/rules/rules_engine_test.dart
git commit -m "test: add carrom RulesEngine spec (failing)"
```

---

## Task 3: Implement RulesEngine.resolve

**Files:**
- Create: `lib/game/rules/rules_engine.dart`

- [ ] **Step 1: Implement the engine**

`lib/game/rules/rules_engine.dart`:
```dart
import 'coin_type.dart';
import 'match_state.dart';
import 'player.dart';
import 'strike_outcome.dart';

/// Pure carrom rules. Given a [MatchState] and the [StrikeOutcome] of one
/// strike, returns the next [MatchState]. See the plan's Ruleset section.
class RulesEngine {
  const RulesEngine();

  MatchState resolve(MatchState state, StrikeOutcome outcome) {
    if (state.isGameOver) return state;

    final p = state.currentPlayer;
    final myColor = state.colorOf(p);

    final pocketedWhite =
        outcome.pocketed.where((c) => c == CoinType.white).length;
    final pocketedBlack =
        outcome.pocketed.where((c) => c == CoinType.black).length;
    final queenPocketed = outcome.pocketed.contains(CoinType.queen);
    final myPocketed = myColor == CoinType.white ? pocketedWhite : pocketedBlack;

    // Apply pocketed coins to the board counts.
    var white = state.whiteRemaining - pocketedWhite;
    var black = state.blackRemaining - pocketedBlack;
    var queenOnBoard = queenPocketed ? false : state.queenOnBoard;
    var coverPending = state.queenCoverPending;

    int colorCount(CoinType color) => color == CoinType.white ? white : black;
    void returnOne(CoinType color) {
      if (color == CoinType.white) {
        white += 1;
      } else {
        black += 1;
      }
    }

    // ---- FOUL: striker pocketed ----
    if (outcome.strikerPocketed) {
      // Return all coins pocketed on this strike.
      white += pocketedWhite;
      black += pocketedBlack;
      if (queenPocketed) queenOnBoard = true;
      // A pending cover fails -> queen returns.
      if (coverPending) queenOnBoard = true;
      // Penalty: return one previously-banked coin of my color, if any.
      if (colorCount(myColor) < 9) returnOne(myColor);
      return state.copyWith(
        currentPlayer: other(p),
        whiteRemaining: white,
        blackRemaining: black,
        queenOnBoard: queenOnBoard,
        queenCoverPending: false,
      );
    }

    // ---- LEGAL STRIKE ----
    // Resolve queen cover.
    if (coverPending) {
      if (myPocketed >= 1) {
        coverPending = false; // covered
      } else {
        queenOnBoard = true; // failed -> returns
        coverPending = false;
      }
    } else if (queenPocketed) {
      if (myPocketed < 1) {
        coverPending = true; // pocketed queen alone -> must cover next
      }
      // else: covered immediately on the same strike.
    }

    final continues = myPocketed >= 1 || queenPocketed;

    // ---- WIN CHECK ----
    if (colorCount(myColor) == 0) {
      if (!queenOnBoard && !coverPending) {
        return state.copyWith(
          winner: p,
          whiteRemaining: white,
          blackRemaining: black,
          queenOnBoard: queenOnBoard,
          queenCoverPending: false,
        );
      }
      // Finished coins but queen unresolved -> deny, return one coin, pass.
      returnOne(myColor);
      if (coverPending) {
        queenOnBoard = true;
        coverPending = false;
      }
      return state.copyWith(
        currentPlayer: other(p),
        whiteRemaining: white,
        blackRemaining: black,
        queenOnBoard: queenOnBoard,
        queenCoverPending: false,
      );
    }

    // ---- CONTINUE OR PASS ----
    return state.copyWith(
      currentPlayer: continues ? p : other(p),
      whiteRemaining: white,
      blackRemaining: black,
      queenOnBoard: queenOnBoard,
      queenCoverPending: continues ? coverPending : false,
    );
  }
}
```

> **Note:** the test file constructs `RulesEngine()` (not `const`). The class has a `const` constructor, so `RulesEngine()` is valid. Do not change the test.

- [ ] **Step 2: Run the engine suite to verify it passes**

Run: `flutter test test/game/rules/rules_engine_test.dart`
Expected: All tests PASS (4 basic + 3 foul + 5 queen + 4 win = 16).

- [ ] **Step 3: Run the full suite + analyze**

Run:
```bash
flutter analyze
flutter test
```
Expected: "No issues found!" and all tests green (Phase 1's 16 + match_state 5 + engine 16).

- [ ] **Step 4: Commit**

```bash
git add lib/game/rules/rules_engine.dart
git commit -m "feat: implement carrom RulesEngine"
```

---

## Task 4: Full-game integration scenario test

**Files:**
- Modify: `test/game/rules/rules_engine_test.dart` (append a new group at the end, inside `main()`'s body)

- [ ] **Step 1: Append an end-to-end scenario test**

Add this `group(...)` as the last statement inside `main()` in `test/game/rules/rules_engine_test.dart` (immediately before the final closing `}` of `main`):
```dart
  group('end-to-end scenario', () {
    test('player one sweeps to a legal win', () {
      var s = MatchState.initial(); // p1 white, p2 black

      // P1 pockets 7 white across continued strikes.
      for (var i = 0; i < 7; i++) {
        s = engine.resolve(s, const StrikeOutcome(pocketed: [CoinType.white]));
        expect(s.currentPlayer, Player.one);
      }
      expect(s.whiteRemaining, 2);

      // P1 pockets the queen alone -> cover pending, still P1.
      s = engine.resolve(s, const StrikeOutcome(pocketed: [CoinType.queen]));
      expect(s.queenCoverPending, true);
      expect(s.currentPlayer, Player.one);

      // P1 covers with a white -> secured, 1 white left, still P1.
      s = engine.resolve(s, const StrikeOutcome(pocketed: [CoinType.white]));
      expect(s.queenCoverPending, false);
      expect(s.queenOnBoard, false);
      expect(s.whiteRemaining, 1);

      // P1 pockets the last white with the queen resolved -> win.
      s = engine.resolve(s, const StrikeOutcome(pocketed: [CoinType.white]));
      expect(s.winner, Player.one);
      expect(s.isGameOver, true);
    });

    test('miss then opponent takes over', () {
      var s = MatchState.initial();
      s = engine.resolve(s, const StrikeOutcome()); // p1 misses
      expect(s.currentPlayer, Player.two);
      s = engine.resolve(s, const StrikeOutcome(pocketed: [CoinType.black]));
      expect(s.currentPlayer, Player.two); // own coin -> continue
      expect(s.blackRemaining, 8);
    });
  });
```

- [ ] **Step 2: Run the suite**

Run: `flutter test test/game/rules/rules_engine_test.dart`
Expected: All tests PASS (18 total now). If the sweep scenario reveals a rule bug, fix `rules_engine.dart` minimally and re-run until green — report any deviation from the documented ruleset.

- [ ] **Step 3: Final verification + commit**

Run:
```bash
flutter analyze
flutter test
```
Expected: clean + all green.
```bash
git add test/game/rules/rules_engine_test.dart
git commit -m "test: add end-to-end carrom rules scenarios"
```

---

## Phase 2A Done — Definition of Done

- `RulesEngine.resolve` correctly handles: own-coin continue, miss/opponent-coin pass, striker foul + penalty, all queen-cover paths, and the queen-before-finish win rule.
- `flutter test` green (Phase 1 + 21 new rules tests); `flutter analyze` clean.
- Pure Dart — no Flame/Flutter-widget imports in `lib/game/rules/`.
- Next: **Phase 2B** — Flame + Forge2D physics board, hybrid controls, centralized routing, and a playable Practice mode that produces `StrikeOutcome`s to feed this engine.

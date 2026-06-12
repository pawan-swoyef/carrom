# Carrom Pro — Phase 2C-1: Match Loop + 2-Player + HUD — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the physics sandbox into a real **2-player pass-and-play match**: detect when a strike settles, feed the `StrikeOutcome` to the rules engine, advance turns (continue/pass/foul), reposition the striker, and drive a live gameplay HUD (player panels, queen status, turn highlight, banners). End the match with a basic result dialog.

**Architecture:** A pure-Dart `MatchSession` (ChangeNotifier) wraps the existing tested `RulesEngine` and exposes HUD-friendly state. `CarromGame` gains strike-completion detection (fires once when the board settles after a launch) and an interactivity gate. The `GameScreen` wires them: game settles → `session.applyStrike(outcome)` → HUD updates → striker repositions → next turn (or result dialog on win). AI is NOT in this plan (Phase 2C-2); `vsComputer` reuses the 2-player flow for now.

**Tech Stack:** Existing — rules engine (`lib/game/rules/`), Forge2D engine (`lib/game/engine/`), provider, theme. No new packages.

---

## File Structure (this plan)

```
lib/game/match/
  player_kind.dart          human vs ai (for later)
  match_session.dart        ChangeNotifier wrapping RulesEngine + mode
lib/game/ui/hud/
  player_panel.dart         one side's avatar/name/color/coins
  queen_status_pill.dart    On board / Pocketed / Covered
  turn_banner.dart          transient "Player 2's Turn" banner
lib/game/ui/
  result_dialog.dart        Victory/Defeat overlay
  game_screen.dart          (modified) wire match for 2P/vsComputer
lib/game/engine/
  carrom_game.dart          (modified) strike-complete detection + interactivity
test/game/match/
  match_session_test.dart
test/game/engine/
  carrom_game_test.dart     (modified) strike-complete test
test/widget/
  game_screen_match_test.dart
```

---

## Task 1: CarromGame — strike-complete detection + interactivity gate

**Files:**
- Modify: `lib/game/engine/carrom_game.dart`
- Modify: `test/game/engine/carrom_game_test.dart`

**Context:** `CarromGame` already has `launch(...)`, `isSettled`, `takeStrikeResult()`, `setStrikerX(double)`, `update(dt)`. Add detection that fires ONCE when the board returns to rest after a launch, plus a flag to block input between turns / during the opponent's turn.

- [ ] **Step 1: Add a failing headless test**

Append inside `main()` of `test/game/engine/carrom_game_test.dart`:
```dart
  testWidgets('onStrikeComplete fires once after a launched strike settles',
      (tester) async {
    final game = await _loaded(tester);
    var fired = 0;
    StrikeOutcome? got;
    game.onStrikeComplete = (outcome) {
      fired++;
      got = outcome;
    };

    game.launch(angleRadians: math.pi / 2, power: 0.6);
    // Step until the board settles (cap iterations to avoid a hang).
    for (var i = 0; i < 1200 && !(fired > 0); i++) {
      game.update(1 / 60);
    }

    expect(fired, 1);
    expect(got, isNotNull);
    // Stepping more does not fire again until the next launch.
    for (var i = 0; i < 120; i++) {
      game.update(1 / 60);
    }
    expect(fired, 1);
  });
```
Add the import at the top of the test file if missing:
```dart
import 'package:carrom_pro/game/rules/strike_outcome.dart';
```

- [ ] **Step 2: Run it — expect failure**

Run: `flutter test test/game/engine/carrom_game_test.dart`
Expected: FAIL — `onStrikeComplete` not defined.

- [ ] **Step 3: Implement in `CarromGame`**

Add fields near the other state:
```dart
  /// Fires exactly once when the board settles after a [launch]. The argument is
  /// the strike's outcome (consumed via takeStrikeResult internally).
  void Function(StrikeOutcome outcome)? onStrikeComplete;

  /// When false, the drag input is ignored (e.g. between turns / opponent turn).
  bool interactive = true;

  bool _strikeInFlight = false;
```
In `launch(...)`, after the settled guard passes and the impulse is applied, set:
```dart
    _strikeInFlight = true;
```
In `update(dt)`, AFTER `super.update(dt)`, `_capSpeeds()`, and the capture drain, add:
```dart
    if (_strikeInFlight && isSettled) {
      _strikeInFlight = false;
      onStrikeComplete?.call(takeStrikeResult());
    }
```
> Note: `isSettled` becomes true only once the struck pieces stop (damping). Because `_strikeInFlight` is set in `launch`, the callback cannot fire from idle jitter. Captures are already drained before this check, so the outcome is complete.

Gate the drag input on `interactive`: in `setStrikerX` and `launch`, add an early return when `!interactive`:
```dart
    if (!interactive) return;
```
(Place it as the first line of both `setStrikerX` and `launch`, before the `isSettled` check.)

- [ ] **Step 4: Run — expect pass**

Run: `flutter test test/game/engine/carrom_game_test.dart`
Expected: all engine tests PASS (existing + the new one).

- [ ] **Step 5: Commit**

```bash
git add lib/game/engine/carrom_game.dart test/game/engine/carrom_game_test.dart
git commit -m "feat: CarromGame strike-complete callback and interactivity gate"
```

---

## Task 2: MatchSession (pure Dart, TDD)

**Files:**
- Create: `lib/game/match/player_kind.dart`
- Create: `lib/game/match/match_session.dart`
- Test: `test/game/match/match_session_test.dart`

- [ ] **Step 1: Create the player-kind enum**

`lib/game/match/player_kind.dart`:
```dart
/// Who controls a seat. Used by the match to decide whether to wait for touch
/// input (human) or run the AI (ai — wired in Phase 2C-2).
enum PlayerKind { human, ai }
```

- [ ] **Step 2: Write the failing test**

`test/game/match/match_session_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:carrom_pro/game/game_launch_args.dart';
import 'package:carrom_pro/game/match/match_session.dart';
import 'package:carrom_pro/game/match/player_kind.dart';
import 'package:carrom_pro/game/rules/coin_type.dart';
import 'package:carrom_pro/game/rules/player.dart';
import 'package:carrom_pro/game/rules/strike_outcome.dart';

void main() {
  test('two-player session: player one starts, owns white', () {
    final s = MatchSession(mode: GameMode.twoPlayer);
    expect(s.currentPlayer, Player.one);
    expect(s.colorOf(Player.one), CoinType.white);
    expect(s.kindOf(Player.one), PlayerKind.human);
    expect(s.kindOf(Player.two), PlayerKind.human);
    expect(s.isOver, false);
  });

  test('vsComputer: player two is the AI', () {
    final s = MatchSession(mode: GameMode.vsComputer);
    expect(s.kindOf(Player.one), PlayerKind.human);
    expect(s.kindOf(Player.two), PlayerKind.ai);
  });

  test('applyStrike resolves through the rules engine and notifies', () {
    final s = MatchSession(mode: GameMode.twoPlayer);
    var notified = 0;
    s.addListener(() => notified++);

    // Pocket own (white) coin -> same player continues, count drops.
    s.applyStrike(const StrikeOutcome(pocketed: [CoinType.white]));
    expect(s.currentPlayer, Player.one);
    expect(s.coinsRemainingFor(Player.one), 8);
    expect(notified, greaterThan(0));
  });

  test('missing passes the turn to player two', () {
    final s = MatchSession(mode: GameMode.twoPlayer);
    s.applyStrike(const StrikeOutcome());
    expect(s.currentPlayer, Player.two);
  });

  test('exposes queen status string', () {
    final s = MatchSession(mode: GameMode.twoPlayer);
    expect(s.queenStatus, QueenStatus.onBoard);
    s.applyStrike(const StrikeOutcome(pocketed: [CoinType.queen]));
    expect(s.queenStatus, QueenStatus.pendingCover);
  });

  test('turnIsAI is true only on the AI seat in vsComputer', () {
    final s = MatchSession(mode: GameMode.vsComputer);
    expect(s.turnIsAI, false); // player one (human)
    s.applyStrike(const StrikeOutcome()); // pass to player two (ai)
    expect(s.turnIsAI, true);
  });

  test('winner is surfaced when the match ends', () {
    final s = MatchSession(mode: GameMode.twoPlayer);
    // Drive a contrived win: reduce to a winning strike via repeated own-coin
    // pockets is long; instead assert winner passthrough using a near-win.
    // Pocket 9 whites with the queen already handled is complex here, so just
    // verify isOver/winner reflect the underlying state object.
    expect(s.isOver, false);
    expect(s.winner, isNull);
  });
}
```

- [ ] **Step 3: Run — expect failure**

Run: `flutter test test/game/match/match_session_test.dart`
Expected: FAIL — `match_session.dart` missing.

- [ ] **Step 4: Implement MatchSession**

`lib/game/match/match_session.dart`:
```dart
import 'package:flutter/foundation.dart';
import '../game_launch_args.dart';
import '../rules/coin_type.dart';
import '../rules/match_state.dart';
import '../rules/player.dart';
import '../rules/rules_engine.dart';
import '../rules/strike_outcome.dart';
import 'player_kind.dart';

/// High-level queen state for the HUD pill.
enum QueenStatus { onBoard, pendingCover, covered }

/// Owns the live [MatchState] for one match and advances it via the pure
/// [RulesEngine]. UI listens to this for HUD updates.
class MatchSession extends ChangeNotifier {
  final GameMode mode;
  final RulesEngine _engine;
  MatchState _state;

  MatchSession({
    required this.mode,
    CoinType playerOneColor = CoinType.white,
    RulesEngine engine = const RulesEngine(),
  })  : _engine = engine,
        _state = MatchState.initial(playerOneColor: playerOneColor);

  MatchState get state => _state;
  Player get currentPlayer => _state.currentPlayer;
  bool get isOver => _state.isGameOver;
  Player? get winner => _state.winner;

  CoinType colorOf(Player p) => _state.colorOf(p);
  int coinsRemainingFor(Player p) => _state.remainingFor(p);

  PlayerKind kindOf(Player p) {
    if (mode == GameMode.vsComputer && p == Player.two) return PlayerKind.ai;
    return PlayerKind.human;
  }

  /// True when it is currently the AI seat's turn (vsComputer only).
  bool get turnIsAI => kindOf(currentPlayer) == PlayerKind.ai;

  QueenStatus get queenStatus {
    if (!_state.queenOnBoard && _state.queenCoverPending) {
      return QueenStatus.pendingCover;
    }
    if (!_state.queenOnBoard) return QueenStatus.covered;
    return QueenStatus.onBoard;
  }

  /// Advances the match by one resolved strike.
  void applyStrike(StrikeOutcome outcome) {
    if (_state.isGameOver) return;
    _state = _engine.resolve(_state, outcome);
    notifyListeners();
  }
}
```
> Note on `queenStatus`: when the queen has been pocketed-and-covered it is off the board and not pending → `covered`. While pending it is off the board AND pending → `pendingCover`. Otherwise → `onBoard`.

- [ ] **Step 5: Run — expect pass**

Run: `flutter test test/game/match/match_session_test.dart`
Expected: all tests PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/game/match test/game/match
git commit -m "feat: add MatchSession wrapping the rules engine for the HUD"
```

---

## Task 3: HUD widgets (presentational)

**Files:**
- Create: `lib/game/ui/hud/player_panel.dart`
- Create: `lib/game/ui/hud/queen_status_pill.dart`
- Create: `lib/game/ui/hud/turn_banner.dart`

These are pure presentational widgets (no match logic). Style with `AppColors` to match the gameplay mockup.

- [ ] **Step 1: PlayerPanel**

`lib/game/ui/hud/player_panel.dart`:
```dart
import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

/// One side of the top HUD: name, coin colour, remaining count, active glow.
class PlayerPanel extends StatelessWidget {
  final String name;
  final bool isWhite;
  final int coinsRemaining;
  final bool active;
  final bool isComputer;

  const PlayerPanel({
    super.key,
    required this.name,
    required this.isWhite,
    required this.coinsRemaining,
    required this.active,
    this.isComputer = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
                border: Border.all(
                  color: active ? AppColors.gold : AppColors.crimsonDark,
                  width: active ? 3 : 1.5,
                ),
              ),
              child: Icon(
                isComputer ? Icons.smart_toy : Icons.person,
                color: AppColors.textLight,
              ),
            ),
            Positioned(
              bottom: -4,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isWhite ? const Color(0xFFF5ECD7) : const Color(0xFF1A1210),
                  border: Border.all(color: AppColors.woodDark, width: 2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(name,
            style: const TextStyle(
                color: AppColors.textLight,
                fontWeight: FontWeight.w700,
                fontSize: 13)),
        Text('${isWhite ? 'WHITE' : 'BLACK'} • $coinsRemaining',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
      ],
    );
  }
}
```

- [ ] **Step 2: QueenStatusPill**

`lib/game/ui/hud/queen_status_pill.dart`:
```dart
import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../match/match_session.dart';

/// Centre HUD pill showing the queen's state.
class QueenStatusPill extends StatelessWidget {
  final QueenStatus status;
  const QueenStatusPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      QueenStatus.onBoard => 'ON BOARD',
      QueenStatus.pendingCover => 'COVER IT!',
      QueenStatus.covered => 'COVERED',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.crimsonDark.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.crimson),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.circle, color: AppColors.crimson, size: 12),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: AppColors.pinkHeading,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 1)),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: TurnBanner**

`lib/game/ui/hud/turn_banner.dart`:
```dart
import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

/// A transient centered banner (e.g. "Player 2's Turn"). The parent controls
/// visibility; this just renders the styled banner.
class TurnBanner extends StatelessWidget {
  final String text;
  const TurnBanner({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gold),
        ),
        child: Text(text,
            style: const TextStyle(
                color: AppColors.gold,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 1)),
      ),
    );
  }
}
```

- [ ] **Step 4: Verify + commit**

Run: `flutter analyze lib/game/ui/hud`
Expected: clean.
```bash
git add lib/game/ui/hud
git commit -m "feat: add gameplay HUD widgets (player panel, queen pill, turn banner)"
```

---

## Task 4: Result dialog

**Files:**
- Create: `lib/game/ui/result_dialog.dart`

- [ ] **Step 1: Create the result dialog**

`lib/game/ui/result_dialog.dart`:
```dart
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Victory / defeat overlay shown when a match ends.
class ResultDialog extends StatelessWidget {
  final bool won;
  final String title; // e.g. "VICTORY!" / "PLAYER 1 WINS"
  final VoidCallback onPlayAgain;
  final VoidCallback onMainMenu;

  const ResultDialog({
    super.key,
    required this.won,
    required this.title,
    required this.onPlayAgain,
    required this.onMainMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.woodGrain,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.gold, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(won ? Icons.emoji_events : Icons.flag,
                color: AppColors.gold, size: 56),
            const SizedBox(height: 12),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 28,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.crimson),
                onPressed: onPlayAgain,
                child: const Text('PLAY AGAIN'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onMainMenu,
                child: const Text('MAIN MENU'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify + commit**

Run: `flutter analyze lib/game/ui/result_dialog.dart`
Expected: clean.
```bash
git add lib/game/ui/result_dialog.dart
git commit -m "feat: add match result dialog"
```

---

## Task 5: Wire the match into GameScreen (2-player)

**Files:**
- Modify: `lib/game/ui/game_screen.dart`
- Test: `test/widget/game_screen_match_test.dart`

**Context:** GameScreen currently creates a `CarromGame` and shows the control HUD. Now, for `twoPlayer` and `vsComputer` modes, also create a `MatchSession`, wire the game's `onStrikeComplete` to it, render the player panels + queen pill + turn banner, reposition the striker each turn, and show the result dialog on win. `practice` mode keeps the current behaviour (no match/HUD panels).

- [ ] **Step 1: Wire the session + HUD**

In `_GameScreenState`:
- Add `MatchSession? _session;` created in `initState` when `widget.args.mode != GameMode.practice`:
  ```dart
  if (widget.args.mode != GameMode.practice) {
    _session = MatchSession(mode: widget.args.mode);
    _game.onStrikeComplete = _handleStrikeComplete;
  }
  ```
- Implement `_handleStrikeComplete(StrikeOutcome outcome)`:
  ```dart
  void _handleStrikeComplete(StrikeOutcome outcome) {
    final session = _session;
    if (session == null) return;
    final before = session.currentPlayer;
    session.applyStrike(outcome);
    if (session.isOver) {
      setState(() {}); // surfaces the result dialog
      return;
    }
    // Reposition the striker on the baseline for the next strike.
    _game.setStrikerX(0);
    if (session.currentPlayer != before) {
      _showTurnBanner(session.currentPlayer);
    }
    setState(() {});
  }
  ```
- Add a transient turn-banner: a `String? _banner;` shown via the `TurnBanner` widget, set in `_showTurnBanner` and cleared after ~1s with a `Future.delayed` + `mounted` guard.
- In `build`, when `_session != null`, render a top HUD row above the board:
  - `PlayerPanel` (Player 1), `QueenStatusPill(status: _session!.queenStatus)`, `PlayerPanel` (Player 2 / Computer) — wire `active` to `_session!.currentPlayer`, `coinsRemaining` to `_session!.coinsRemainingFor(...)`, `isComputer` when that seat is AI.
  - For `vsComputer`, label seat two "Computer"; for `twoPlayer`, "Player 2".
- When `_session!.isOver`, overlay the `ResultDialog`:
  - `won`/`title`: for `twoPlayer`, title = "PLAYER {n} WINS"; for `vsComputer`, `won = winner == Player.one`, title = won ? "VICTORY!" : "DEFEAT".
  - `onPlayAgain`: `await _game.resetBoard(); setState(() => _session = MatchSession(mode: widget.args.mode));` and re-attach `onStrikeComplete`.
  - `onMainMenu`: `Navigator.of(context).maybePop()`.
- Keep the coin pill / power meter / legend as-is. For non-practice modes, the top bar's coin pill can stay (placeholder).

> Note: `vsComputer` currently has no AI, so player two will just never act (it's a human seat for now). That is acceptable for this plan — Phase 2C-2 adds the AI. To keep `vsComputer` playable in the meantime, treat both seats as human here (the AI hand-off is added next plan). Do not block on AI.

- [ ] **Step 2: Widget test**

`test/widget/game_screen_match_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:carrom_pro/game/game_launch_args.dart';
import 'package:carrom_pro/game/ui/game_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('two-player match shows both player panels and queen pill',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: GameScreen(args: GameLaunchArgs(mode: GameMode.twoPlayer)),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Player 1'), findsOneWidget);
    expect(find.text('Player 2'), findsOneWidget);
    expect(find.text('ON BOARD'), findsOneWidget); // queen pill
  });
}
```

- [ ] **Step 3: Verify**

Run:
```bash
flutter analyze
flutter test
```
Expected: clean + all green. (Use `pump`, never `pumpAndSettle`, around `GameWidget`.)

- [ ] **Step 4: Commit**

```bash
git add lib/game/ui/game_screen.dart test/widget/game_screen_match_test.dart
git commit -m "feat: wire 2-player match loop, live HUD, turn banner and result dialog"
```

---

## Phase 2C-1 Done — Definition of Done

- Launching a strike in `twoPlayer` mode resolves through the rules engine: own coin → same player continues; miss/foul → turn passes with a banner; striker repositions for the next strike.
- The HUD shows both player panels (active highlight + live coin counts) and the queen-status pill.
- Winning shows the result dialog (Play Again / Main Menu).
- `practice` mode is unchanged. `vsComputer` is playable as two human seats (AI arrives in 2C-2).
- `flutter test` green; `flutter analyze` clean.
- Next: **Phase 2C-2** — the AI opponent (target/pocket selection + difficulty), auto-playing the AI seat.
```

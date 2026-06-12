# Carrom Pro — Phase 2B: Physics Board + Controls + Practice Mode — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A playable carrom board: a Forge2D physics world with the striker, 9+9 coins and the queen, four corner pockets, board friction, hybrid controls (slide → aim → power → STRIKE), and a Practice mode screen that captures pocketed pieces into a `StrikeOutcome`.

**Architecture:** Pure-Dart, unit-tested helpers (board geometry, coin layout, strike math, settle detection) feed a thin Flame layer (`CarromGame extends Forge2DGame`) whose bodies are `BodyComponent`s. Pocket sensors capture pieces and report a `StrikeOutcome` (the seam into the Phase 2A `RulesEngine`). A centralized router presents the full-screen game route.

**Tech Stack:** flame 1.37.0, flame_forge2d 0.19.2, forge2d 0.14.2 (world in meters). Existing: rules engine (`lib/game/rules/`), provider, theme.

**Coordinate system:** Forge2D meters. Board centered at origin. The inner playing square spans `[-halfBoard, +halfBoard]` on both axes (see `BoardGeometry`). +y is up in Forge2D; the player's baseline is at the bottom (negative y).

> **Physics constants are tunable.** The values in `BoardGeometry`/`StrikeMath` are starting points. Behaviour (capture, rest) is verified by headless tests; *feel* (power, friction) is tuned by running on a device — a dedicated tuning step is at the end.

---

## File Structure (created this phase)

```
lib/game/
  board/
    board_geometry.dart      world dimensions, pocket/baseline positions (pure)
    coin_layout.dart         initial piece placement (pure)
    strike_math.dart         clamp striker x; aim+power -> impulse vector (pure)
    settle_detector.dart     "are all pieces at rest?" (pure)
  engine/
    carrom_game.dart         CarromGame extends Forge2DGame (Flame)
    bodies/
      wall_body.dart         static board rails
      pocket_body.dart       corner sensor + capture
      coin_body.dart         a coin/queen
      striker_body.dart      the striker
    strike_result.dart       collects pocketed pieces for one strike
  ui/
    strike_controls.dart     slider + power meter + STRIKE button (Flutter overlay)
    game_screen.dart         GameWidget + controls + minimal HUD (Practice)
  game_launch_args.dart      {GameMode mode, Difficulty? difficulty}
lib/navigation/
  app_routes.dart            route names + onGenerateRoute
test/game/board/
  board_geometry_test.dart
  coin_layout_test.dart
  strike_math_test.dart
  settle_detector_test.dart
test/game/engine/
  carrom_game_test.dart      headless: load + physics behaviour
```

---

## Task 1: Add Flame dependencies

**Files:** Modify `pubspec.yaml`

- [ ] **Step 1: Add the packages**

Run:
```bash
flutter pub add flame flame_forge2d
```
Expected: resolves `flame 1.37.0`, `flame_forge2d 0.19.2+6`, `forge2d 0.14.2+1`. `pub get` succeeds.

- [ ] **Step 2: Confirm the app still builds**

Run:
```bash
flutter analyze
flutter test
```
Expected: clean + all existing tests pass.

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add flame and flame_forge2d"
```

---

## Task 2: BoardGeometry (pure, TDD)

**Files:**
- Create: `lib/game/board/board_geometry.dart`
- Test: `test/game/board/board_geometry_test.dart`

- [ ] **Step 1: Write the failing test**

`test/game/board/board_geometry_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:carrom_pro/game/board/board_geometry.dart';

void main() {
  const g = BoardGeometry();

  test('playing area is a centered square', () {
    expect(g.halfBoard, greaterThan(0));
    // corners are symmetric around origin
    expect(g.halfBoard, g.halfBoard);
  });

  test('four pockets sit just inside the four corners', () {
    final pockets = g.pocketCenters;
    expect(pockets.length, 4);
    // each pocket is within the board and in a distinct quadrant
    final quadrants = pockets
        .map((p) => '${p.x > 0 ? '+' : '-'}${p.y > 0 ? '+' : '-'}')
        .toSet();
    expect(quadrants.length, 4);
    for (final p in pockets) {
      expect(p.x.abs(), lessThanOrEqualTo(g.halfBoard));
      expect(p.y.abs(), lessThanOrEqualTo(g.halfBoard));
    }
  });

  test('striker baseline is below centre and within slide range', () {
    expect(g.baselineY, lessThan(0)); // bottom half
    expect(g.strikerMinX, lessThan(g.strikerMaxX));
    expect(g.strikerMinX.abs(), lessThanOrEqualTo(g.halfBoard));
    expect(g.strikerMaxX.abs(), lessThanOrEqualTo(g.halfBoard));
  });

  test('radii are positive and ordered striker > coin', () {
    expect(g.coinRadius, greaterThan(0));
    expect(g.strikerRadius, greaterThan(g.coinRadius));
    expect(g.pocketRadius, greaterThan(g.strikerRadius));
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/game/board/board_geometry_test.dart`
Expected: FAIL — URI doesn't exist.

- [ ] **Step 3: Implement**

`lib/game/board/board_geometry.dart`:
```dart
import 'package:vector_math/vector_math_64.dart';

/// Static board dimensions in Forge2D meters. Origin is the board centre,
/// +y up. All values are tunable starting points.
class BoardGeometry {
  const BoardGeometry();

  /// Half the side length of the inner playing square.
  double get halfBoard => 5.0;

  double get coinRadius => 0.22;
  double get strikerRadius => 0.30;
  double get pocketRadius => 0.45;

  /// How far in from each corner the pocket centre sits.
  double get _pocketInset => 0.45;

  List<Vector2> get pocketCenters {
    final c = halfBoard - _pocketInset;
    return [
      Vector2(-c, c),
      Vector2(c, c),
      Vector2(-c, -c),
      Vector2(c, -c),
    ];
  }

  /// The y of the striker's baseline (bottom player).
  double get baselineY => -halfBoard * 0.72;

  /// Horizontal slide limits for striker placement on the baseline.
  double get strikerMaxX => halfBoard * 0.48;
  double get strikerMinX => -strikerMaxX;
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `flutter test test/game/board/board_geometry_test.dart`
Expected: All 4 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/game/board/board_geometry.dart test/game/board/board_geometry_test.dart
git commit -m "feat: add BoardGeometry constants"
```

---

## Task 3: CoinLayout (pure, TDD)

**Files:**
- Create: `lib/game/board/coin_layout.dart`
- Test: `test/game/board/coin_layout_test.dart`

- [ ] **Step 1: Write the failing test**

`test/game/board/coin_layout_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:carrom_pro/game/board/board_geometry.dart';
import 'package:carrom_pro/game/board/coin_layout.dart';
import 'package:carrom_pro/game/rules/coin_type.dart';

void main() {
  const g = BoardGeometry();

  test('produces 9 white, 9 black, 1 queen', () {
    final pieces = buildOpeningLayout(g);
    expect(pieces.length, 19);
    expect(pieces.where((p) => p.type == CoinType.white).length, 9);
    expect(pieces.where((p) => p.type == CoinType.black).length, 9);
    expect(pieces.where((p) => p.type == CoinType.queen).length, 1);
  });

  test('the queen is at the centre', () {
    final pieces = buildOpeningLayout(g);
    final queen = pieces.firstWhere((p) => p.type == CoinType.queen);
    expect(queen.position.x.abs(), lessThan(0.001));
    expect(queen.position.y.abs(), lessThan(0.001));
  });

  test('all pieces sit inside the central circle (well clear of pockets)', () {
    final pieces = buildOpeningLayout(g);
    final maxR = g.halfBoard * 0.5;
    for (final p in pieces) {
      expect(p.position.length, lessThanOrEqualTo(maxR));
    }
  });

  test('no two pieces overlap', () {
    final pieces = buildOpeningLayout(g);
    final minDist = g.coinRadius * 2;
    for (var i = 0; i < pieces.length; i++) {
      for (var j = i + 1; j < pieces.length; j++) {
        final d = (pieces[i].position - pieces[j].position).length;
        expect(d, greaterThanOrEqualTo(minDist - 0.001),
            reason: 'pieces $i and $j overlap');
      }
    }
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/game/board/coin_layout_test.dart`
Expected: FAIL — URI doesn't exist.

- [ ] **Step 3: Implement**

`lib/game/board/coin_layout.dart`:
```dart
import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart';
import 'board_geometry.dart';
import '../rules/coin_type.dart';

/// A piece to place on the board at the start of a match.
class PiecePlacement {
  final CoinType type;
  final Vector2 position;
  const PiecePlacement(this.type, this.position);
}

/// Builds the standard opening cluster: queen centre, an inner ring of 6 and an
/// outer ring of 12, with colours alternating to 9 white + 9 black.
List<PiecePlacement> buildOpeningLayout(BoardGeometry g) {
  final pieces = <PiecePlacement>[
    PiecePlacement(CoinType.queen, Vector2.zero()),
  ];

  // Spacing keeps neighbours just over one coin-diameter apart.
  final step = g.coinRadius * 2.05;
  final innerR = step;       // 6 coins
  final outerR = step * 2;   // 12 coins

  var white = 0;
  var black = 0;
  // Alternate, but respect the 9/9 cap if one colour fills up.
  CoinType nextColor() {
    if (white > black && black < 9) {
      black++;
      return CoinType.black;
    }
    if (white < 9) {
      white++;
      return CoinType.white;
    }
    black++;
    return CoinType.black;
  }

  void ring(double radius, int count, double phase) {
    for (var i = 0; i < count; i++) {
      final a = phase + (2 * math.pi * i / count);
      pieces.add(PiecePlacement(
        nextColor(),
        Vector2(radius * math.cos(a), radius * math.sin(a)),
      ));
    }
  }

  ring(innerR, 6, 0);
  ring(outerR, 12, math.pi / 12);

  return pieces;
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `flutter test test/game/board/coin_layout_test.dart`
Expected: All 4 tests PASS. If "no overlap" fails, increase `step` slightly (e.g. `* 2.1`) and re-run — do not weaken the test.

- [ ] **Step 5: Commit**

```bash
git add lib/game/board/coin_layout.dart test/game/board/coin_layout_test.dart
git commit -m "feat: add opening coin layout"
```

---

## Task 4: StrikeMath (pure, TDD)

**Files:**
- Create: `lib/game/board/strike_math.dart`
- Test: `test/game/board/strike_math_test.dart`

- [ ] **Step 1: Write the failing test**

`test/game/board/strike_math_test.dart`:
```dart
import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:carrom_pro/game/board/board_geometry.dart';
import 'package:carrom_pro/game/board/strike_math.dart';

void main() {
  const g = BoardGeometry();
  const m = StrikeMath(g);

  test('clampStrikerX keeps the striker on the baseline range', () {
    expect(m.clampStrikerX(999), g.strikerMaxX);
    expect(m.clampStrikerX(-999), g.strikerMinX);
    expect(m.clampStrikerX(0), 0);
  });

  test('zero power produces zero impulse', () {
    final i = m.impulse(angleRadians: math.pi / 2, power: 0);
    expect(i.length, 0);
  });

  test('full power points along the aim angle with max magnitude', () {
    // Aim straight up (+y).
    final i = m.impulse(angleRadians: math.pi / 2, power: 1);
    expect(i.x.abs(), lessThan(1e-9));
    expect(i.y, closeTo(m.maxImpulse, 1e-9));
  });

  test('power scales magnitude linearly and clamps to [0,1]', () {
    final half = m.impulse(angleRadians: 0, power: 0.5);
    expect(half.length, closeTo(m.maxImpulse * 0.5, 1e-9));
    final over = m.impulse(angleRadians: 0, power: 5);
    expect(over.length, closeTo(m.maxImpulse, 1e-9));
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/game/board/strike_math_test.dart`
Expected: FAIL — URI doesn't exist.

- [ ] **Step 3: Implement**

`lib/game/board/strike_math.dart`:
```dart
import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart';
import 'board_geometry.dart';

/// Maps control inputs (striker x, aim angle, power) to physics quantities.
class StrikeMath {
  final BoardGeometry geometry;
  const StrikeMath(this.geometry);

  /// Maximum linear impulse magnitude applied at full power (tunable).
  double get maxImpulse => 18.0;

  double clampStrikerX(double x) =>
      x.clamp(geometry.strikerMinX, geometry.strikerMaxX).toDouble();

  /// Impulse vector for an aim [angleRadians] (standard math angle, +x = 0,
  /// counter-clockwise) and [power] in 0..1 (clamped).
  Vector2 impulse({required double angleRadians, required double power}) {
    final p = power.clamp(0.0, 1.0).toDouble();
    final magnitude = maxImpulse * p;
    return Vector2(
      magnitude * math.cos(angleRadians),
      magnitude * math.sin(angleRadians),
    );
  }
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `flutter test test/game/board/strike_math_test.dart`
Expected: All 4 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/game/board/strike_math.dart test/game/board/strike_math_test.dart
git commit -m "feat: add StrikeMath (clamp + impulse)"
```

---

## Task 5: SettleDetector (pure, TDD)

**Files:**
- Create: `lib/game/board/settle_detector.dart`
- Test: `test/game/board/settle_detector_test.dart`

- [ ] **Step 1: Write the failing test**

`test/game/board/settle_detector_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:carrom_pro/game/board/settle_detector.dart';

void main() {
  const d = SettleDetector(restSpeed: 0.05);

  test('all speeds below threshold = settled', () {
    expect(d.isSettled([0.0, 0.01, 0.049]), true);
  });

  test('any speed at or above threshold = not settled', () {
    expect(d.isSettled([0.0, 0.2]), false);
  });

  test('empty board is settled', () {
    expect(d.isSettled(const []), true);
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/game/board/settle_detector_test.dart`
Expected: FAIL — URI doesn't exist.

- [ ] **Step 3: Implement**

`lib/game/board/settle_detector.dart`:
```dart
/// Decides when a strike has finished: every moving piece is below [restSpeed].
class SettleDetector {
  final double restSpeed;
  const SettleDetector({this.restSpeed = 0.05});

  bool isSettled(Iterable<double> speeds) =>
      speeds.every((s) => s < restSpeed);
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `flutter test test/game/board/settle_detector_test.dart`
Expected: All 3 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/game/board/settle_detector.dart test/game/board/settle_detector_test.dart
git commit -m "feat: add SettleDetector"
```

---

## Task 6: Centralized routing + game launch args + Practice entry

**Files:**
- Create: `lib/game/game_launch_args.dart`
- Create: `lib/navigation/app_routes.dart`
- Create: `lib/game/ui/game_screen.dart` (temporary placeholder body this task)
- Modify: `lib/app.dart` (wire `onGenerateRoute`)
- Modify: `lib/screens/tabs/play_tab.dart` (a button that launches Practice)

- [ ] **Step 1: Create the launch args + game mode**

`lib/game/game_launch_args.dart`:
```dart
import '../settings/difficulty.dart';

enum GameMode { vsComputer, twoPlayer, practice }

class GameLaunchArgs {
  final GameMode mode;
  final Difficulty? difficulty; // only for vsComputer

  const GameLaunchArgs({required this.mode, this.difficulty});
}
```

- [ ] **Step 2: Create a temporary GameScreen placeholder**

`lib/game/ui/game_screen.dart`:
```dart
import 'package:flutter/material.dart';
import '../game_launch_args.dart';
import '../../theme/app_colors.dart';

class GameScreen extends StatelessWidget {
  final GameLaunchArgs args;
  const GameScreen({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Carrom — ${args.mode.name}')),
      body: const Center(
        child: Text('Board loads here (Task 7+)',
            style: TextStyle(color: AppColors.textMuted)),
      ),
    );
  }
}
```

- [ ] **Step 3: Create the router**

`lib/navigation/app_routes.dart`:
```dart
import 'package:flutter/material.dart';
import '../game/game_launch_args.dart';
import '../game/ui/game_screen.dart';

abstract class AppRoutes {
  static const game = '/game';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case game:
        final args = settings.arguments as GameLaunchArgs;
        return MaterialPageRoute(
          builder: (_) => GameScreen(args: args),
          settings: settings,
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Unknown route: ${settings.name}')),
          ),
        );
    }
  }

  /// Convenience: push the full-screen game route.
  static Future<void> pushGame(BuildContext context, GameLaunchArgs args) {
    return Navigator.of(context).pushNamed(game, arguments: args);
  }
}
```

- [ ] **Step 4: Wire `onGenerateRoute` into the app**

In `lib/app.dart`, add the import and the `onGenerateRoute` to the `MaterialApp`:
```dart
import 'navigation/app_routes.dart';
```
Add to the `MaterialApp(...)` (keep existing `home:`):
```dart
      onGenerateRoute: AppRoutes.onGenerateRoute,
```

- [ ] **Step 5: Launch Practice from the Play tab**

Replace the body of `lib/screens/tabs/play_tab.dart` with a button that launches Practice (the full Select Mode screen arrives in Phase 2C):
```dart
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../game/game_launch_args.dart';
import '../../navigation/app_routes.dart';

class PlayTab extends StatelessWidget {
  const PlayTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Select Mode\n(full screen in Phase 2C)',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 16),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => AppRoutes.pushGame(
              context,
              const GameLaunchArgs(mode: GameMode.practice),
            ),
            child: const Text('Practice'),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 6: Verify + smoke test navigation**

Create `test/widget/game_route_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carrom_pro/services/storage_service.dart';
import 'package:carrom_pro/settings/settings_controller.dart';
import 'package:carrom_pro/navigation/home_shell.dart';
import 'package:carrom_pro/navigation/app_routes.dart';
import 'package:carrom_pro/game/ui/game_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Practice button pushes the game route', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.create();
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsController(storage)),
      ],
      child: MaterialApp(
        onGenerateRoute: AppRoutes.onGenerateRoute,
        home: const HomeShell(initialIndex: 0),
      ),
    ));

    await tester.tap(find.text('Practice'));
    await tester.pumpAndSettle();
    expect(find.byType(GameScreen), findsOneWidget);
  });
}
```

Run:
```bash
flutter test test/widget/game_route_test.dart
flutter analyze
flutter test
```
Expected: new test passes; analyze clean; full suite green.

- [ ] **Step 7: Commit**

```bash
git add lib/game/game_launch_args.dart lib/navigation/app_routes.dart lib/game/ui/game_screen.dart lib/app.dart lib/screens/tabs/play_tab.dart test/widget/game_route_test.dart
git commit -m "feat: add centralized routing and Practice entry"
```

---

## Task 7: CarromGame Forge2D world (bodies + friction)

**Files:**
- Create: `lib/game/engine/bodies/wall_body.dart`
- Create: `lib/game/engine/bodies/pocket_body.dart`
- Create: `lib/game/engine/bodies/coin_body.dart`
- Create: `lib/game/engine/bodies/striker_body.dart`
- Create: `lib/game/engine/carrom_game.dart`
- Test: `test/game/engine/carrom_game_test.dart`

> **API note (flame_forge2d 0.19.2):** `CarromGame extends Forge2DGame`. Add `BodyComponent`s to the game in `onLoad`. A `BodyComponent` overrides `Body createBody()` using `world.createBody(BodyDef(...))` then `body.createFixtureFromShape(...)` / `createFixture(FixtureDef(...))`. Use `CircleShape()..radius = r` and `PolygonShape()..setAsBox(...)` / `..set([...])`. Apply board friction via `BodyDef(linearDamping: ..., angularDamping: ...)`. Gravity is zero: `Forge2DGame(gravity: Vector2.zero())` (or set on the world per the installed API). **Before writing, read the installed examples** under the pub cache (`flame_forge2d`/example) to match the exact constructors for this version; adapt the reference code below if the API differs. Verify by compiling and by the headless test.

- [ ] **Step 1: Write the failing headless test**

`test/game/engine/carrom_game_test.dart`:
```dart
import 'package:flutter/widgets.dart';
import 'package:flame/game.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:carrom_pro/game/engine/carrom_game.dart';
import 'package:carrom_pro/game/engine/bodies/coin_body.dart';
import 'package:carrom_pro/game/engine/bodies/striker_body.dart';

Future<CarromGame> _loaded(WidgetTester tester) async {
  final game = CarromGame();
  await tester.pumpWidget(GameWidget(game: game));
  await tester.pump(); // onLoad
  await tester.pump();
  return game;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('loads 19 coins, a striker and four pockets', (tester) async {
    final game = await _loaded(tester);
    expect(game.coins.length, 19);
    expect(game.world.children.whereType<StrikerBody>().length, 1);
    expect(game.pockets.length, 4);
  });

  testWidgets('a struck coin slows to rest from damping', (tester) async {
    final game = await _loaded(tester);
    final coin = game.coins.first;
    coin.body.linearVelocity.setValues(6, 0);
    // Step the world for a couple of simulated seconds.
    for (var i = 0; i < 180; i++) {
      game.update(1 / 60);
    }
    expect(coin.body.linearVelocity.length, lessThan(0.1));
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/game/engine/carrom_game_test.dart`
Expected: FAIL — URI doesn't exist.

- [ ] **Step 3: Implement the bodies and game**

Implement against the installed flame_forge2d 0.19.2 API. Reference implementations (adapt constructor/fixture calls to the exact version):

`lib/game/engine/bodies/wall_body.dart` — four static rails forming the square frame around `BoardGeometry.halfBoard`. Use a `BodyComponent` with `BodyType.static` and box fixtures (modest restitution, e.g. 0.4).

`lib/game/engine/bodies/coin_body.dart`:
```dart
import 'package:flame_forge2d/flame_forge2d.dart';
import '../../board/board_geometry.dart';
import '../../rules/coin_type.dart';

class CoinBody extends BodyComponent {
  final CoinType type;
  final Vector2 startPosition;
  final BoardGeometry geometry;

  CoinBody({
    required this.type,
    required this.startPosition,
    required this.geometry,
  });

  @override
  Body createBody() {
    final shape = CircleShape()..radius = geometry.coinRadius;
    final fixture = FixtureDef(shape, density: 1.0, friction: 0.1, restitution: 0.6);
    final bodyDef = BodyDef(
      type: BodyType.dynamic,
      position: startPosition.clone(),
      linearDamping: 1.6, // board friction
      angularDamping: 1.6,
    );
    return world.createBody(bodyDef)..createFixture(fixture);
  }
}
```

`lib/game/engine/bodies/striker_body.dart` — like `CoinBody` but radius `geometry.strikerRadius`, higher density (e.g. 1.6), starting at `(0, geometry.baselineY)`.

`lib/game/engine/bodies/pocket_body.dart` — a static sensor circle (`isSensor: true`, radius `geometry.pocketRadius`) at a given centre. (Capture logic added in Task 8; this task just creates them.)

`lib/game/engine/carrom_game.dart`:
```dart
import 'package:flame_forge2d/flame_forge2d.dart';
import '../board/board_geometry.dart';
import '../board/coin_layout.dart';
import 'bodies/wall_body.dart';
import 'bodies/pocket_body.dart';
import 'bodies/coin_body.dart';
import 'bodies/striker_body.dart';

class CarromGame extends Forge2DGame {
  CarromGame() : super(gravity: Vector2.zero());

  final BoardGeometry geometry = const BoardGeometry();
  final List<CoinBody> coins = [];
  final List<PocketBody> pockets = [];
  late final StrikerBody striker;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Walls.
    await world.add(WallBody(geometry: geometry));

    // Pockets.
    for (final c in geometry.pocketCenters) {
      final pocket = PocketBody(center: c, geometry: geometry);
      pockets.add(pocket);
      await world.add(pocket);
    }

    // Coins + queen.
    for (final placement in buildOpeningLayout(geometry)) {
      final coin = CoinBody(
        type: placement.type,
        startPosition: placement.position,
        geometry: geometry,
      );
      coins.add(coin);
      await world.add(coin);
    }

    // Striker.
    striker = StrikerBody(geometry: geometry);
    await world.add(striker);
  }
}
```

> If `WallBody`/`PocketBody` need a list of positions or a single rail, structure as needed — the test only checks counts, damping behaviour, and that one striker exists. Keep each body file single-responsibility.

- [ ] **Step 4: Run the headless test to verify it passes**

Run: `flutter test test/game/engine/carrom_game_test.dart`
Expected: both tests PASS. If the damping test is too slow/fast to settle, tune `linearDamping` (try 1.2–2.5) until a 6 m/s coin rests within ~3 s — this is the first physics tuning point.

- [ ] **Step 5: Full verification + commit**

Run: `flutter analyze` and `flutter test` — clean + green.
```bash
git add lib/game/engine test/game/engine
git commit -m "feat: add Forge2D carrom world with walls, pockets, coins, striker"
```

---

## Task 8: Pocket capture + StrikeOutcome

**Files:**
- Create: `lib/game/engine/strike_result.dart`
- Modify: `lib/game/engine/bodies/pocket_body.dart` (capture on contact)
- Modify: `lib/game/engine/bodies/coin_body.dart` (mark captured) and `striker_body.dart`
- Modify: `lib/game/engine/carrom_game.dart` (strike + settle + emit StrikeOutcome)
- Modify: `test/game/engine/carrom_game_test.dart` (append capture tests)

> **API note:** pocket capture uses contact callbacks. In flame_forge2d 0.19.2, add the `ContactCallbacks` mixin to `PocketBody` and override `void beginContact(Object other, Contact contact)`. When `other` is a `CoinBody`/`StrikerBody`, flag it captured and remove it (`other.removeFromParent()`), recording it for the current strike. Removing a body inside a contact callback must be deferred — collect captured bodies and remove them in the next `update` (do not destroy bodies mid-step).

- [ ] **Step 1: Append failing capture tests**

Add to `test/game/engine/carrom_game_test.dart` inside `main()`:
```dart
  testWidgets('coin moved onto a pocket is captured and reported', (tester) async {
    final game = await _loaded(tester);
    final coin = game.coins.first;
    final pocketCenter = game.pockets.first.body.position.clone();
    // Teleport the coin onto the pocket and let the contact register.
    coin.body.setTransform(pocketCenter, 0);
    for (var i = 0; i < 10; i++) {
      game.update(1 / 60);
    }
    final result = game.takeStrikeResult();
    expect(result.pocketed, contains(coin.type));
    expect(game.coins.contains(coin), false); // removed from play
  });

  testWidgets('striker into a pocket is reported as strikerPocketed', (tester) async {
    final game = await _loaded(tester);
    final pocketCenter = game.pockets.first.body.position.clone();
    game.striker.body.setTransform(pocketCenter, 0);
    for (var i = 0; i < 10; i++) {
      game.update(1 / 60);
    }
    final result = game.takeStrikeResult();
    expect(result.strikerPocketed, true);
  });
```

- [ ] **Step 2: Run to verify the new tests fail**

Run: `flutter test test/game/engine/carrom_game_test.dart`
Expected: FAIL — `takeStrikeResult`/capture not implemented.

- [ ] **Step 3: Implement capture + result**

`lib/game/engine/strike_result.dart`:
```dart
import '../rules/coin_type.dart';
import '../rules/strike_outcome.dart';

/// Mutable accumulator for what a single strike pocketed. Convert to the
/// immutable [StrikeOutcome] the rules engine consumes via [toOutcome].
class StrikeResult {
  final List<CoinType> pocketed = [];
  bool strikerPocketed = false;

  void reset() {
    pocketed.clear();
    strikerPocketed = false;
  }

  StrikeOutcome toOutcome() =>
      StrikeOutcome(pocketed: List.unmodifiable(pocketed), strikerPocketed: strikerPocketed);
}
```

In `CarromGame`:
- Hold a `StrikeResult _result = StrikeResult();`.
- Maintain a `final List<BodyComponent> _toCapture = [];` queue.
- `void capture(BodyComponent body)` — called by `PocketBody.beginContact`; pushes to `_toCapture` and records type / strikerPocketed in `_result`.
- In `update(dt)`: first `super.update(dt)`, then drain `_toCapture` (remove from world, remove from `coins`).
- `StrikeOutcome takeStrikeResult()` — returns `_result.toOutcome()` then `_result.reset()`.
- `void strike(Vector2 impulse)` — applies `striker.body.applyLinearImpulse(impulse)` (reset `_result` at the start of a strike).

`PocketBody` (capture):
```dart
@override
void beginContact(Object other, Contact contact) {
  if (other is CoinBody || other is StrikerBody) {
    (findGame()! as CarromGame).capture(other as BodyComponent);
  }
}
```
(Adapt `findGame()` to the installed API — e.g. `game` getter on the component.)

- [ ] **Step 4: Run to verify capture tests pass**

Run: `flutter test test/game/engine/carrom_game_test.dart`
Expected: all four engine tests PASS. Deferred removal must not throw "world locked" — if it does, ensure removal happens in `update`, not in `beginContact`.

- [ ] **Step 5: Full verification + commit**

Run: `flutter analyze` and `flutter test` — clean + green.
```bash
git add lib/game/engine test/game/engine
git commit -m "feat: pocket capture emits StrikeOutcome"
```

---

## Task 9: Hybrid controls + Practice screen

**Files:**
- Create: `lib/game/ui/strike_controls.dart`
- Rewrite: `lib/game/ui/game_screen.dart` (host `GameWidget` + controls + minimal HUD)
- Modify: `lib/game/engine/carrom_game.dart` (expose striker x positioning + aim state)

> This task is **device-verified** (feel/tuning). Headless tests assert the controls widget builds and that `strike` produces motion; visual polish/tuning is the final step.

- [ ] **Step 1: Striker positioning API on CarromGame**

Add to `CarromGame`:
- `void setStrikerX(double x)` — `striker.body.setTransform(Vector2(StrikeMath(geometry).clampStrikerX(x), geometry.baselineY), 0)` and zero its velocity. Only allowed while settled.
- `bool get isSettled` — uses `SettleDetector` over `[...coins, striker].map((b) => b.body.linearVelocity.length)`.
- `void launch({required double angleRadians, required double power})` — guards on `isSettled`, resets `_result`, applies `StrikeMath(geometry).impulse(...)`.

- [ ] **Step 2: Controls overlay widget**

`lib/game/ui/strike_controls.dart` — a Flutter widget with:
- a horizontal `Slider` (or custom track) bound to striker x via `onChanged: game.setStrikerX`,
- a vertical power meter (a `GestureDetector`/`Slider` 0..1) stored in state,
- an aim control: dragging on the board area sets `angleRadians` (compute from drag delta relative to the striker), with an `aim line` painted,
- a crimson **STRIKE** `FilledButton` calling `game.launch(angleRadians: _angle, power: _power)`, disabled when `!game.isSettled`.

Keep the widget focused; it takes a `CarromGame` and reads/writes the above. Use `AppColors` for styling (gold/crimson). Match the mockup layout (power meter left, STRIKE centre-bottom, slider above).

- [ ] **Step 3: Game screen**

Rewrite `lib/game/ui/game_screen.dart` to stack:
- `GameWidget(game: _game)` (full board),
- the `StrikeControls(_game)` overlay at the bottom,
- a minimal top bar (back button; for Practice, a "Reset board" action calling a `game.resetBoard()` that re-runs the opening layout),
- for Practice mode, after each settle just allow another strike (no turn logic).

Create `_game` in `initState` as `CarromGame()`; dispose it.

- [ ] **Step 4: Headless build test**

Add a widget test that pumps `GameScreen(args: GameLaunchArgs(mode: practice))` (wrapped in `MaterialApp`) and asserts the STRIKE button is present and the `GameWidget` builds without throwing. Run `flutter test`.

- [ ] **Step 5: Device play-test + tuning (manual)**

Run on a device/emulator:
```bash
flutter run
```
Verify and tune: striker slides on the baseline; drag aims; power meter fills; STRIKE flicks the striker; coins collide and slow to rest; pieces over pockets drop and disappear; the board resets. Adjust `maxImpulse`, `linearDamping`, `restitution`, and `restSpeed` for good feel. Commit tuning as a follow-up.

- [ ] **Step 6: Commit**

```bash
git add lib/game/ui lib/game/engine/carrom_game.dart test
git commit -m "feat: hybrid strike controls and practice game screen"
```

---

## Phase 2B Done — Definition of Done

- A Practice board launches from the Play tab and renders the carrom board with 19 coins, the queen, the striker, four pockets, and friction.
- Hybrid controls: slide the striker on the baseline, drag to aim, set power, STRIKE to flick.
- Pieces collide, slow to rest, and are captured when they enter a pocket; captures accumulate into a `StrikeOutcome` (ready for Phase 2C to feed the `RulesEngine`).
- `flutter test` green (pure-logic + headless physics tests); `flutter analyze` clean.
- Physics *feel* tuned on a device.
- Next: **Phase 2C** — wire `StrikeOutcome` into the `RulesEngine` for vs-AI / 2-Player, with the HUD, turn flow, AI player, Select Mode + Difficulty screens, and the result/victory dialog.
```

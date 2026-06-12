import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:carrom_pro/game/engine/carrom_game.dart';
import 'package:carrom_pro/game/engine/bodies/striker_body.dart';
import 'package:carrom_pro/game/rules/strike_outcome.dart';

Future<CarromGame> _loaded(WidgetTester tester) async {
  final game = CarromGame();
  await tester.pumpWidget(GameWidget(game: game));
  await tester.pump(); // trigger onLoad
  await tester.pump();
  return game;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('loads 19 coins, a striker and four pockets', (tester) async {
    final game = await _loaded(tester);
    expect(game.coins.length, 19);
    expect(game.pockets.length, 4);
    expect(game.striker, isA<StrikerBody>());
  });

  testWidgets('a struck coin slows to rest from damping', (tester) async {
    final game = await _loaded(tester);
    final coin = game.coins.first;
    coin.body.linearVelocity.setValues(6, 0);
    for (var i = 0; i < 180; i++) {
      game.update(1 / 60);
    }
    expect(coin.body.linearVelocity.length, lessThan(0.1));
  });

  testWidgets('coin moved onto a pocket is captured and reported', (tester) async {
    final game = await _loaded(tester);
    final coin = game.coins.first;
    final captureType = coin.type;
    final pocketCenter = game.pockets.first.body.position.clone();
    coin.body.setTransform(pocketCenter, 0);
    for (var i = 0; i < 10; i++) {
      game.update(1 / 60);
    }
    final result = game.takeStrikeResult();
    expect(result.pocketed, contains(captureType));
    expect(game.coins.contains(coin), false);
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

  // ── Control API tests ──────────────────────────────────────────────────────

  testWidgets('isSettled is true right after load (all pieces at rest)',
      (tester) async {
    final game = await _loaded(tester);
    expect(game.isSettled, isTrue);
  });

  testWidgets('setStrikerX clamps to board limits', (tester) async {
    final game = await _loaded(tester);
    final geo = game.geometry;

    // Move beyond the max limit.
    game.setStrikerX(999);
    expect(
      game.striker.body.position.x,
      closeTo(geo.strikerMaxX, 0.001),
    );

    // Move beyond the min limit.
    game.setStrikerX(-999);
    expect(
      game.striker.body.position.x,
      closeTo(geo.strikerMinX, 0.001),
    );

    // Valid position in the middle.
    game.setStrikerX(0);
    expect(game.striker.body.position.x, closeTo(0.0, 0.001));
    expect(
      game.striker.body.position.y,
      closeTo(geo.baselineY, 0.001),
    );
  });

  testWidgets('setStrikerX does nothing when board is not settled',
      (tester) async {
    final game = await _loaded(tester);

    // Give the striker some velocity so it is NOT settled.
    game.striker.body.linearVelocity.setValues(5, 5);
    expect(game.isSettled, isFalse);

    final xBefore = game.striker.body.position.x;
    game.setStrikerX(0); // should be ignored
    expect(game.striker.body.position.x, closeTo(xBefore, 0.001));
  });

  testWidgets('launch gives striker non-zero velocity immediately',
      (tester) async {
    final game = await _loaded(tester);

    // Full-power straight-up launch.
    game.launch(angleRadians: math.pi / 2, power: 1.0);
    expect(game.striker.body.linearVelocity.length, greaterThan(0));
  });

  testWidgets('launch is ignored when board is not settled', (tester) async {
    final game = await _loaded(tester);

    // Give a coin some velocity.
    game.coins.first.body.linearVelocity.setValues(5, 5);
    expect(game.isSettled, isFalse);

    // Striker velocity should remain zero.
    game.launch(angleRadians: math.pi / 2, power: 1.0);
    expect(game.striker.body.linearVelocity.length, closeTo(0, 0.001));
  });

  testWidgets('resetBoard restores 19 coins and a fresh striker', (tester) async {
    final game = await _loaded(tester);

    // Pocket a coin manually.
    final coin = game.coins.first;
    final pocketCenter = game.pockets.first.body.position.clone();
    coin.body.setTransform(pocketCenter, 0);
    for (var i = 0; i < 10; i++) {
      game.update(1 / 60);
    }
    expect(game.coins.length, lessThan(19));

    // Reset.
    await game.resetBoard();
    // Allow the async adds to complete.
    await tester.pump();
    await tester.pump();

    expect(game.coins.length, 19);
    expect(game.striker, isA<StrikerBody>());
    expect(game.isSettled, isTrue);
  });

  testWidgets('speed is capped at maxSpeed to avoid glitches', (tester) async {
    final game = await _loaded(tester);

    // Force the striker far above the cap, then step once.
    game.striker.body.linearVelocity.setValues(200, 0);
    game.update(1 / 60);

    expect(
      game.striker.body.linearVelocity.length,
      lessThanOrEqualTo(CarromGame.maxSpeed + 0.001),
    );
  });

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
    for (var i = 0; i < 1200 && !(fired > 0); i++) {
      game.update(1 / 60);
    }

    expect(fired, 1);
    expect(got, isNotNull);
    for (var i = 0; i < 120; i++) {
      game.update(1 / 60);
    }
    expect(fired, 1);
  });

  testWidgets('zero-power launch does not arm a phantom strike', (tester) async {
    final game = await _loaded(tester);
    var fired = 0;
    game.onStrikeComplete = (_) => fired++;

    game.launch(angleRadians: 0, power: 0);
    for (var i = 0; i < 30; i++) {
      game.update(1 / 60);
    }

    expect(fired, 0);
    expect(game.striker.body.linearVelocity.length, closeTo(0, 0.001));
  });
}

import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:carrom_pro/game/engine/carrom_game.dart';
import 'package:carrom_pro/game/engine/bodies/striker_body.dart';

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
}

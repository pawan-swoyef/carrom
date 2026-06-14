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
  for (var i = 0; i < 60 && game.coins.length < 19; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
  return game;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('runAiTurn places and fires the striker', (tester) async {
    final game = await _loaded(tester);
    expect(game.isSettled, isTrue);

    final fired = runAiTurn(game, const AiPlayer(Difficulty.hard), CoinType.black);
    expect(fired, isTrue);

    expect(game.striker.body.linearVelocity.length, greaterThan(0));
  });
}

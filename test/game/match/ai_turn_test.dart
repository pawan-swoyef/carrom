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

    expect(game.striker.body.linearVelocity.length, greaterThan(0));
  });
}

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

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
  final double strikerX;
  final double angleRadians;
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

  AiShot? planShot({
    required List<AiCoin> coins,
    required CoinType myColor,
    required BoardGeometry geometry,
    double Function()? rng,
  }) {
    final random = rng ?? math.Random().nextDouble;

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
        final ghost = coin.position - dir * contact;

        final strikerX =
            ghost.x.clamp(geometry.strikerMinX, geometry.strikerMaxX).toDouble();
        final strikerPos = Vector2(strikerX, baselineY);
        final aim = ghost - strikerPos;
        if (aim.y <= 0.2) continue;

        final dSG = aim.length;
        final score = dCP + dSG * 0.5;
        if (score < bestScore) {
          bestScore = score;
          bestAim = aim;
          bestStrikerX = strikerX;
          bestTravel = dCP + dSG;
        }
      }
    }

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
        bestAim = Vector2(0, 1);
      }
    }

    var angle = math.atan2(bestAim.y, bestAim.x);
    final reach = geometry.halfBoard * 2.6;
    var power = (bestTravel / reach).clamp(0.35, 1.0).toDouble();

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

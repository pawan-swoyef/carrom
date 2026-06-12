import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:carrom_pro/game/ai/ai_player.dart';
import 'package:carrom_pro/game/board/board_geometry.dart';
import 'package:carrom_pro/game/rules/coin_type.dart';
import 'package:carrom_pro/settings/difficulty.dart';

void main() {
  const g = BoardGeometry();

  double noNoise() => 0.5;

  test('returns null when no targetable coins remain', () {
    const ai = AiPlayer(Difficulty.hard);
    final shot = ai.planShot(
      coins: const [],
      myColor: CoinType.black,
      geometry: g,
      rng: noNoise,
    );
    expect(shot, isNull);
  });

  test('aims roughly along the striker→ghost-ball direction (hard, no noise)',
      () {
    const ai = AiPlayer(Difficulty.hard);
    final coin = AiCoin(CoinType.black, Vector2(0, 2.0));
    final shot = ai.planShot(
      coins: [coin],
      myColor: CoinType.black,
      geometry: g,
      rng: noNoise,
    )!;
    expect(shot.angleRadians, greaterThan(0.2));
    expect(shot.angleRadians, lessThan(math.pi - 0.2));
    expect(shot.power, inInclusiveRange(0.2, 1.0));
    expect(shot.strikerX, inInclusiveRange(g.strikerMinX, g.strikerMaxX));
  });

  test('prefers the coin with the shortest path to a pocket', () {
    const ai = AiPlayer(Difficulty.hard);
    final pockets = g.pocketCenters;
    final nearPocket = pockets.first;
    final easy = AiCoin(CoinType.black, nearPocket * 0.6);
    final hard = AiCoin(CoinType.black, Vector2(0, 0));
    final shot = ai.planShot(
      coins: [hard, easy],
      myColor: CoinType.black,
      geometry: g,
      rng: noNoise,
    )!;
    expect(shot.strikerX.sign, easy.position.x.sign);
  });

  test('easy difficulty adds more aim noise than hard', () {
    final coin = AiCoin(CoinType.black, Vector2(0, 2.0));
    double maxNoise() => 1.0;
    final hardShot = const AiPlayer(Difficulty.hard)
        .planShot(coins: [coin], myColor: CoinType.black, geometry: g, rng: maxNoise)!;
    final easyShot = const AiPlayer(Difficulty.easy)
        .planShot(coins: [coin], myColor: CoinType.black, geometry: g, rng: maxNoise)!;
    final baseShot = const AiPlayer(Difficulty.hard)
        .planShot(coins: [coin], myColor: CoinType.black, geometry: g, rng: () => 0.5)!;
    final hardDev = (hardShot.angleRadians - baseShot.angleRadians).abs();
    final easyDev = (easyShot.angleRadians - baseShot.angleRadians).abs();
    expect(easyDev, greaterThan(hardDev));
  });

  test('targets the queen when no own coins remain but the queen is present', () {
    const ai = AiPlayer(Difficulty.hard);
    final shot = ai.planShot(
      coins: [AiCoin(CoinType.queen, Vector2(0, 1.5))],
      myColor: CoinType.black,
      geometry: g,
      rng: noNoise,
    );
    expect(shot, isNotNull);
  });
}

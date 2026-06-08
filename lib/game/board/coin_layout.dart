import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart';
import 'board_geometry.dart';
import '../rules/coin_type.dart';

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

  final step = g.coinRadius * 2.05;
  final innerR = step;
  final outerR = step * 2;

  var white = 0;
  var black = 0;
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

import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
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

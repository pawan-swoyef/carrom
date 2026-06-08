import 'package:flutter_test/flutter_test.dart';
import 'package:carrom_pro/game/board/board_geometry.dart';

void main() {
  const g = BoardGeometry();

  test('playing area is a centered square', () {
    expect(g.halfBoard, greaterThan(0));
    expect(g.halfBoard, g.halfBoard);
  });

  test('four pockets sit just inside the four corners', () {
    final pockets = g.pocketCenters;
    expect(pockets.length, 4);
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
    expect(g.baselineY, lessThan(0));
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

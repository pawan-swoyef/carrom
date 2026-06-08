import 'package:flutter_test/flutter_test.dart';
import 'package:carrom_pro/game/board/board_geometry.dart';
import 'package:carrom_pro/game/board/coin_layout.dart';
import 'package:carrom_pro/game/rules/coin_type.dart';

void main() {
  const g = BoardGeometry();

  test('produces 9 white, 9 black, 1 queen', () {
    final pieces = buildOpeningLayout(g);
    expect(pieces.length, 19);
    expect(pieces.where((p) => p.type == CoinType.white).length, 9);
    expect(pieces.where((p) => p.type == CoinType.black).length, 9);
    expect(pieces.where((p) => p.type == CoinType.queen).length, 1);
  });

  test('the queen is at the centre', () {
    final pieces = buildOpeningLayout(g);
    final queen = pieces.firstWhere((p) => p.type == CoinType.queen);
    expect(queen.position.x.abs(), lessThan(0.001));
    expect(queen.position.y.abs(), lessThan(0.001));
  });

  test('all pieces sit inside the central circle (well clear of pockets)', () {
    final pieces = buildOpeningLayout(g);
    final maxR = g.halfBoard * 0.5;
    for (final p in pieces) {
      expect(p.position.length, lessThanOrEqualTo(maxR));
    }
  });

  test('no two pieces overlap', () {
    final pieces = buildOpeningLayout(g);
    final minDist = g.coinRadius * 2;
    for (var i = 0; i < pieces.length; i++) {
      for (var j = i + 1; j < pieces.length; j++) {
        final d = (pieces[i].position - pieces[j].position).length;
        expect(d, greaterThanOrEqualTo(minDist - 0.001),
            reason: 'pieces $i and $j overlap');
      }
    }
  });
}

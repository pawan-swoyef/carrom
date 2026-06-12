import 'package:flutter_test/flutter_test.dart';
import 'package:carrom_pro/game/profile/rank.dart';

void main() {
  test('zero xp is the first tier', () {
    final r = rankForXp(0);
    expect(r.name, kRankTiers.first.name);
    expect(r.progress, inInclusiveRange(0.0, 1.0));
  });

  test('higher xp gives a later tier', () {
    final low = rankForXp(50);
    final high = rankForXp(5000);
    expect(high.tierIndex, greaterThan(low.tierIndex));
  });

  test('max tier reports full progress', () {
    final r = rankForXp(999999);
    expect(r.progress, 1.0);
    expect(r.name, kRankTiers.last.name);
  });

  test('progress is fractional within a tier', () {
    final mid = (kRankTiers[1].minXp) ~/ 2;
    final r = rankForXp(mid);
    expect(r.tierIndex, 0);
    expect(r.progress, closeTo(0.5, 0.2));
  });
}

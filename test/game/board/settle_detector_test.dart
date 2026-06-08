import 'package:flutter_test/flutter_test.dart';
import 'package:carrom_pro/game/board/settle_detector.dart';

void main() {
  const d = SettleDetector(restSpeed: 0.05);

  test('all speeds below threshold = settled', () {
    expect(d.isSettled([0.0, 0.01, 0.049]), true);
  });

  test('any speed at or above threshold = not settled', () {
    expect(d.isSettled([0.0, 0.2]), false);
  });

  test('empty board is settled', () {
    expect(d.isSettled(const []), true);
  });
}

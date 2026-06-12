import 'dart:math' as math;

import 'package:carrom_pro/game/board/aim.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  const maxDrag = 4.0;

  group('aimFromPullback', () {
    test('finger pulled straight DOWN below striker → fires straight UP (+π/2)',
        () {
      final aim = aimFromPullback(
        strikerPos: Vector2(0, 0),
        fingerPos: Vector2(0, -2), // pull down
        maxDrag: maxDrag,
      );
      expect(aim.angleRadians, closeTo(math.pi / 2, 1e-9));
      expect(aim.power, closeTo(2.0 / maxDrag, 1e-9)); // 0.5
    });

    test('finger pulled straight UP → fires straight DOWN (-π/2)', () {
      final aim = aimFromPullback(
        strikerPos: Vector2(0, 0),
        fingerPos: Vector2(0, 2), // pull up
        maxDrag: maxDrag,
      );
      expect(aim.angleRadians, closeTo(-math.pi / 2, 1e-9));
    });

    test('finger pulled down-left → fires up-right', () {
      final aim = aimFromPullback(
        strikerPos: Vector2(0, 0),
        fingerPos: Vector2(-1, -1), // pull down-left
        maxDrag: maxDrag,
      );
      // Fire vector = (1, 1) → angle = π/4.
      expect(aim.angleRadians, closeTo(math.pi / 4, 1e-9));
    });

    test('pull distance 2 with maxDrag 4 → power 0.5', () {
      final aim = aimFromPullback(
        strikerPos: Vector2(0, 0),
        fingerPos: Vector2(2, 0),
        maxDrag: maxDrag,
      );
      expect(aim.power, closeTo(0.5, 1e-9));
    });

    test('pull distance 99 → power clamps to 1.0', () {
      final aim = aimFromPullback(
        strikerPos: Vector2(0, 0),
        fingerPos: Vector2(99, 0),
        maxDrag: maxDrag,
      );
      expect(aim.power, closeTo(1.0, 1e-9));
    });

    test('zero pull → power 0', () {
      final aim = aimFromPullback(
        strikerPos: Vector2(1, 1),
        fingerPos: Vector2(1, 1),
        maxDrag: maxDrag,
      );
      expect(aim.power, closeTo(0.0, 1e-9));
    });

    test('offset striker position works correctly', () {
      // striker at (1, 1), finger at (1, -1) → pull down 2 → fires up (+π/2).
      final aim = aimFromPullback(
        strikerPos: Vector2(1, 1),
        fingerPos: Vector2(1, -1),
        maxDrag: maxDrag,
      );
      expect(aim.angleRadians, closeTo(math.pi / 2, 1e-9));
      expect(aim.power, closeTo(2.0 / maxDrag, 1e-9));
    });
  });
}

import 'dart:math' as math;

import 'package:carrom_pro/game/board/aim.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  const maxDrag = 4.0;
  const minDrag = 0.2;

  group('aimFromDrag', () {
    test('finger directly above striker → angle ≈ π/2, power = dist/maxDrag',
        () {
      final aim = aimFromDrag(
        striker: Vector2(0, 0),
        finger: Vector2(0, 2),
        maxDrag: maxDrag,
        minDrag: minDrag,
      );
      expect(aim, isNotNull);
      expect(aim!.angleRadians, closeTo(math.pi / 2, 1e-9));
      expect(aim.power, closeTo(2.0 / maxDrag, 1e-9)); // 0.5
    });

    test('distance ≥ maxDrag → power clamps to 1.0', () {
      final aim = aimFromDrag(
        striker: Vector2(0, 0),
        finger: Vector2(0, 6), // dist = 6, maxDrag = 4 → would be 1.5, clamped
        maxDrag: maxDrag,
        minDrag: minDrag,
      );
      expect(aim, isNotNull);
      expect(aim!.power, closeTo(1.0, 1e-9));
    });

    test('distance < minDrag → returns null', () {
      final aim = aimFromDrag(
        striker: Vector2(0, 0),
        finger: Vector2(0, 0.1), // dist = 0.1 < 0.2
        maxDrag: maxDrag,
        minDrag: minDrag,
      );
      expect(aim, isNull);
    });

    test('finger to the right → angle ≈ 0', () {
      final aim = aimFromDrag(
        striker: Vector2(0, 0),
        finger: Vector2(3, 0),
        maxDrag: maxDrag,
        minDrag: minDrag,
      );
      expect(aim, isNotNull);
      expect(aim!.angleRadians, closeTo(0.0, 1e-9));
      expect(aim.power, closeTo(3.0 / maxDrag, 1e-9)); // 0.75
    });

    test('distance exactly equal to minDrag → returns non-null', () {
      final aim = aimFromDrag(
        striker: Vector2(0, 0),
        finger: Vector2(minDrag, 0),
        maxDrag: maxDrag,
        minDrag: minDrag,
      );
      // dist == minDrag is NOT < minDrag, so it returns a ShotAim
      expect(aim, isNotNull);
      expect(aim!.power, closeTo(minDrag / maxDrag, 1e-9));
    });

    test('finger below striker → angle ≈ -π/2', () {
      final aim = aimFromDrag(
        striker: Vector2(0, 0),
        finger: Vector2(0, -2),
        maxDrag: maxDrag,
        minDrag: minDrag,
      );
      expect(aim, isNotNull);
      expect(aim!.angleRadians, closeTo(-math.pi / 2, 1e-9));
    });

    test('offset striker position works correctly', () {
      // striker at (1, 1), finger at (1, 3) → delta = (0, 2), angle = π/2
      final aim = aimFromDrag(
        striker: Vector2(1, 1),
        finger: Vector2(1, 3),
        maxDrag: maxDrag,
        minDrag: minDrag,
      );
      expect(aim, isNotNull);
      expect(aim!.angleRadians, closeTo(math.pi / 2, 1e-9));
      expect(aim.power, closeTo(2.0 / maxDrag, 1e-9));
    });
  });
}

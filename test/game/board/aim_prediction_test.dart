import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:carrom_pro/game/board/aim_prediction.dart';

void main() {
  test('hits a coin directly ahead at contact distance (R + r)', () {
    final hit = predictImpact(
      origin: Vector2(0, -3),
      dir: Vector2(0, 1),
      strikerRadius: 0.3,
      halfBoard: 5,
      coins: [AimCircle(Vector2(0, 0), 0.22)],
    );
    expect(hit.type, ImpactType.coin);
    expect(hit.point.x, closeTo(0, 1e-6));
    expect(hit.point.y, closeTo(-0.52, 1e-6)); // 0 - (0.3 + 0.22)
  });

  test('hits the wall (centre bound) when no coins are in the way', () {
    final hit = predictImpact(
      origin: Vector2(0, 0),
      dir: Vector2(0, 1),
      strikerRadius: 0.3,
      halfBoard: 5,
      coins: const [],
    );
    expect(hit.type, ImpactType.wall);
    expect(hit.point.y, closeTo(4.7, 1e-6)); // 5 - 0.3
  });

  test('chooses the nearer coin over a farther wall', () {
    final hit = predictImpact(
      origin: Vector2(0, -4),
      dir: Vector2(0, 1),
      strikerRadius: 0.3,
      halfBoard: 5,
      coins: [AimCircle(Vector2(0, 0), 0.22)],
    );
    expect(hit.type, ImpactType.coin);
    expect(hit.point.y, closeTo(-0.52, 1e-6));
  });

  test('right-going ray stops at the right wall bound', () {
    final hit = predictImpact(
      origin: Vector2(0, 0),
      dir: Vector2(1, 0),
      strikerRadius: 0.3,
      halfBoard: 5,
      coins: const [],
    );
    expect(hit.type, ImpactType.wall);
    expect(hit.point.x, closeTo(4.7, 1e-6));
  });

  test('ignores a coin that is behind the origin', () {
    final hit = predictImpact(
      origin: Vector2(0, 0),
      dir: Vector2(0, 1),
      strikerRadius: 0.3,
      halfBoard: 5,
      coins: [AimCircle(Vector2(0, -2), 0.22)], // behind
    );
    expect(hit.type, ImpactType.wall); // coin behind is skipped
  });
}

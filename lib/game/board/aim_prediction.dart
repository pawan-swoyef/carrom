import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart';

enum ImpactType { wall, coin }

/// A coin as the raycast sees it: world centre + radius.
class AimCircle {
  final Vector2 center;
  final double radius;
  const AimCircle(this.center, this.radius);
}

/// First contact of a striker (radius [strikerRadius]) travelling from [origin]
/// along unit [dir]. [point] is where the striker CENTRE rests against the hit.
class AimImpact {
  final Vector2 point;
  final ImpactType type;
  final double distance;
  const AimImpact(this.point, this.type, this.distance);
}

AimImpact predictImpact({
  required Vector2 origin,
  required Vector2 dir, // assumed normalized
  required double strikerRadius,
  required double halfBoard,
  required List<AimCircle> coins,
}) {
  var best = double.infinity;
  var bestType = ImpactType.wall;

  // Coins: Minkowski-inflate by strikerRadius, ray-vs-circle (near root).
  for (final c in coins) {
    final fx = origin.x - c.center.x;
    final fy = origin.y - c.center.y;
    final rr = strikerRadius + c.radius;
    final b = 2 * (fx * dir.x + fy * dir.y);
    final cc = fx * fx + fy * fy - rr * rr;
    final disc = b * b - 4 * cc;
    if (disc < 0) continue;
    final t = (-b - math.sqrt(disc)) / 2;
    if (t > 1e-6 && t < best) {
      best = t;
      bestType = ImpactType.coin;
    }
  }

  // Walls: striker centre bounded to ±(halfBoard - strikerRadius); first exit.
  final lim = halfBoard - strikerRadius;
  var wallT = double.infinity;
  void axis(double o, double d) {
    if (d > 1e-9) {
      final t = (lim - o) / d;
      if (t > 1e-6 && t < wallT) wallT = t;
    } else if (d < -1e-9) {
      final t = (-lim - o) / d;
      if (t > 1e-6 && t < wallT) wallT = t;
    }
  }

  axis(origin.x, dir.x);
  axis(origin.y, dir.y);
  if (wallT < best) {
    best = wallT;
    bestType = ImpactType.wall;
  }

  if (!best.isFinite) {
    return AimImpact(origin + dir * halfBoard, ImpactType.wall, halfBoard);
  }
  return AimImpact(origin + dir * best, bestType, best);
}

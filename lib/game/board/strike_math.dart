import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart';
import 'board_geometry.dart';

/// Maps control inputs (striker x, aim angle, power) to physics quantities.
class StrikeMath {
  final BoardGeometry geometry;
  const StrikeMath(this.geometry);

  double get maxImpulse => 18.0;

  double clampStrikerX(double x) =>
      x.clamp(geometry.strikerMinX, geometry.strikerMaxX).toDouble();

  Vector2 impulse({required double angleRadians, required double power}) {
    final p = power.clamp(0.0, 1.0).toDouble();
    final magnitude = maxImpulse * p;
    return Vector2(
      magnitude * math.cos(angleRadians),
      magnitude * math.sin(angleRadians),
    );
  }
}

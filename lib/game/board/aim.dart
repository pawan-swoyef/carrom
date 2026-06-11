import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart';

/// A computed shot: aim angle (standard math convention, +x=0, CCW) and
/// power in [0, 1].
class ShotAim {
  final double angleRadians;
  final double power;
  const ShotAim(this.angleRadians, this.power);
}

/// Drag-forward aim: the striker shoots TOWARD [finger]. Power scales with the
/// drag distance, saturating at [maxDrag]. Returns null if the drag is too
/// small to be a shot (treated as positioning only).
///
/// Coordinate convention: world space (+y up). The angle is the standard math
/// angle (atan2(dy, dx)), so straight up-field is π/2.
ShotAim? aimFromDrag({
  required Vector2 striker,
  required Vector2 finger,
  required double maxDrag,
  double minDrag = 0.2,
}) {
  final delta = finger - striker;
  final dist = delta.length;
  if (dist < minDrag) return null;
  final power = (dist / maxDrag).clamp(0.0, 1.0).toDouble();
  final angle = math.atan2(delta.y, delta.x);
  return ShotAim(angle, power);
}

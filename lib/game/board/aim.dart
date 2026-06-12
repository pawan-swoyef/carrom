import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart';

/// A computed shot: aim angle (standard math convention, +x=0, CCW) and
/// power in [0, 1].
class ShotAim {
  final double angleRadians;
  final double power;
  const ShotAim(this.angleRadians, this.power);
}

/// Pull-back slingshot: the striker fires in the direction OPPOSITE the drag —
/// i.e. along the vector from [fingerPos] back to [strikerPos]. The further the
/// finger is pulled away from the striker, the more power, saturating at
/// [maxDrag]. A zero pull yields zero power (and an arbitrary 0 angle).
///
/// Coordinate convention: world space (+y up). The angle is the standard math
/// angle (atan2(dy, dx)) of the FIRE vector, so a straight-up shot is π/2.
ShotAim aimFromPullback({
  required Vector2 strikerPos,
  required Vector2 fingerPos,
  required double maxDrag,
}) {
  // Pull vector: finger relative to striker. Fire is the opposite direction.
  final fire = strikerPos - fingerPos;
  final dist = fire.length;
  if (dist == 0) return const ShotAim(0, 0);
  final power = (dist / maxDrag).clamp(0.0, 1.0).toDouble();
  final angle = math.atan2(fire.y, fire.x);
  return ShotAim(angle, power);
}

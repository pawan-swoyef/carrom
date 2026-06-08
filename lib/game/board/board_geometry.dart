import 'package:vector_math/vector_math_64.dart';

/// Static board dimensions in Forge2D meters. Origin is the board centre,
/// +y up. All values are tunable starting points.
class BoardGeometry {
  const BoardGeometry();

  double get halfBoard => 5.0;

  double get coinRadius => 0.22;
  double get strikerRadius => 0.30;
  double get pocketRadius => 0.45;

  double get _pocketInset => 0.45;

  List<Vector2> get pocketCenters {
    final c = halfBoard - _pocketInset;
    return [
      Vector2(-c, c),
      Vector2(c, c),
      Vector2(-c, -c),
      Vector2(c, -c),
    ];
  }

  double get baselineY => -halfBoard * 0.72;

  double get strikerMaxX => halfBoard * 0.48;
  double get strikerMinX => -strikerMaxX;
}

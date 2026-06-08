import 'package:flame_forge2d/flame_forge2d.dart';

import '../../board/board_geometry.dart';

/// The four static rails forming the square frame of the board. Implemented as
/// a single static body carrying four box fixtures just outside [halfBoard].
class WallBody extends BodyComponent {
  WallBody(this.geometry);

  final BoardGeometry geometry;

  static const double _thickness = 0.5;
  static const double _restitution = 0.4;
  static const double _friction = 0.2;

  @override
  Body createBody() {
    final h = geometry.halfBoard;
    final t = _thickness;
    final body = world.createBody(BodyDef(type: BodyType.static));

    // Each entry: half-extents and centre offset of one rail.
    void rail(double halfW, double halfH, double cx, double cy) {
      final shape = PolygonShape()..setAsBox(halfW, halfH, Vector2(cx, cy), 0);
      body.createFixture(
        FixtureDef(shape, restitution: _restitution, friction: _friction),
      );
    }

    // Top and bottom rails span the full width (plus the corners).
    rail(h + t, t, 0, h + t); // top
    rail(h + t, t, 0, -(h + t)); // bottom
    // Left and right rails span the full height.
    rail(t, h + t, -(h + t), 0); // left
    rail(t, h + t, h + t, 0); // right

    return body;
  }
}

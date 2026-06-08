import 'package:flame_forge2d/flame_forge2d.dart';

import '../../board/board_geometry.dart';

/// The dynamic striker. Heavier than coins; starts on the baseline. Its body's
/// `userData` is set to this component so pocket sensors can identify it.
class StrikerBody extends BodyComponent {
  StrikerBody(this.geometry);

  final BoardGeometry geometry;

  /// Set once the striker has been pocketed; guards against double-capture.
  bool captured = false;

  @override
  Body createBody() {
    final shape = CircleShape()..radius = geometry.strikerRadius;
    final fixtureDef = FixtureDef(
      shape,
      density: 1.6,
      friction: 0.1,
      restitution: 0.6,
    );
    final bodyDef = BodyDef(
      type: BodyType.dynamic,
      position: Vector2(0, geometry.baselineY),
      linearDamping: 1.8,
      angularDamping: 1.8,
      userData: this,
    );
    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }
}

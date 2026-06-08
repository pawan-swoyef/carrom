import 'package:flame_forge2d/flame_forge2d.dart';

import '../../board/board_geometry.dart';
import '../../rules/coin_type.dart';

/// A dynamic carrom coin (or the queen). Its body's `userData` is set to this
/// component so pocket sensors can identify it on contact.
class CoinBody extends BodyComponent {
  CoinBody({
    required this.geometry,
    required this.type,
    required this.startPosition,
  });

  final BoardGeometry geometry;
  final CoinType type;
  final Vector2 startPosition;

  /// Set once this coin has been pocketed; guards against double-capture.
  bool captured = false;

  @override
  Body createBody() {
    final shape = CircleShape()..radius = geometry.coinRadius;
    final fixtureDef = FixtureDef(
      shape,
      density: 1.0,
      friction: 0.1,
      restitution: 0.6,
    );
    final bodyDef = BodyDef(
      type: BodyType.dynamic,
      position: startPosition.clone(),
      linearDamping: 1.8,
      angularDamping: 1.8,
      userData: this,
    );
    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }
}

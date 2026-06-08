import 'dart:ui';

import 'package:flame_forge2d/flame_forge2d.dart';

import '../../board/board_geometry.dart';
import '../carrom_game.dart';
import 'coin_body.dart';
import 'striker_body.dart';

/// A static sensor circle at a corner pocket. When a coin or striker overlaps
/// it, it asks the game to capture that body. Removal is deferred by the game.
class PocketBody extends BodyComponent<CarromGame> with ContactCallbacks {
  PocketBody({required this.geometry, required this.pocketCenter});

  final BoardGeometry geometry;
  final Vector2 pocketCenter;

  static const _pocketColor = Color(0xFF0D0A08); // near-black hole

  @override
  Body createBody() {
    final shape = CircleShape()..radius = geometry.pocketRadius;
    final fixtureDef = FixtureDef(shape, isSensor: true);
    final bodyDef = BodyDef(
      type: BodyType.static,
      position: pocketCenter.clone(),
      userData: this,
    );
    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(
      Offset.zero,
      geometry.pocketRadius,
      Paint()..color = _pocketColor,
    );
  }

  @override
  void beginContact(Object other, Contact contact) {
    if (other is CoinBody || other is StrikerBody) {
      game.capture(other as BodyComponent);
    }
    super.beginContact(other, contact);
  }
}

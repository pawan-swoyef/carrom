import 'dart:ui';

import 'package:flame_forge2d/flame_forge2d.dart';

import '../../board/board_geometry.dart';
import '../../strikers/striker_skin.dart';

/// The dynamic striker. Heavier than coins; starts on the baseline. Its body's
/// `userData` is set to this component so pocket sensors can identify it.
class StrikerBody extends BodyComponent {
  StrikerBody(this.geometry, {StrikerSkin? skin, this.spriteOf})
      : skin = skin ?? skinById(kDefaultStrikerId);

  final BoardGeometry geometry;
  final StrikerSkin skin;

  /// Resolves the current top-down striker art (null until loaded). Falls back
  /// to the drawn disc when null.
  final Image? Function()? spriteOf;

  /// Set once the striker has been pocketed; guards against double-capture.
  bool captured = false;

  @override
  Body createBody() {
    final shape = CircleShape()..radius = geometry.strikerRadius;
    final fixtureDef = FixtureDef(
      shape,
      density: 1.6, // heavier than coins (1.0) for proper momentum transfer
      friction: 0.05,
      restitution: 0.6,
    );
    final bodyDef = BodyDef(
      type: BodyType.dynamic,
      position: Vector2(0, geometry.baselineY),
      linearDamping: 1.8,
      angularDamping: 1.8,
      userData: this,
    );
    // Continuous collision detection: the striker can move fast at high power,
    // so treat it as a "bullet" to stop it tunnelling through the thin walls.
    bodyDef.bullet = true;
    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }

  @override
  void render(Canvas canvas) {
    final r = geometry.strikerRadius;

    final s = spriteOf?.call();
    if (s != null) {
      final width = 2 * r * 1.2;
      final height = width * (s.height / s.width);
      final dst =
          Rect.fromCenter(center: Offset.zero, width: width, height: height);
      final src = Rect.fromLTWH(0, 0, s.width.toDouble(), s.height.toDouble());
      canvas.drawImageRect(
        s,
        src,
        dst,
        Paint()
          ..isAntiAlias = true
          ..filterQuality = FilterQuality.medium,
      );
      return;
    }

    // Outer filled circle.
    canvas.drawCircle(Offset.zero, r, Paint()..color = Color(skin.fill));

    // Decorative ring.
    canvas.drawCircle(
      Offset.zero,
      r * 0.75,
      Paint()
        ..color = Color(skin.ring)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.15,
    );

    // Inner highlight dot.
    canvas.drawCircle(Offset.zero, r * 0.28, Paint()..color = Color(skin.accent));
  }
}

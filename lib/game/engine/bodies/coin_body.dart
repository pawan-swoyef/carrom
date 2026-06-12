import 'dart:ui';

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

  // Coin fill colours.
  static const _colorWhite = Color(0xFFF5ECD7); // cream/ivory
  static const _colorBlack = Color(0xFF1A1210); // near-black
  static const _colorQueen = Color(0xFFB03048); // crimson red

  // Outline strokes for coins.
  static const _outlineWhite = Color(0xFFCCBFA8);
  static const _outlineBlack = Color(0xFF444040);
  static const _outlineQueen = Color(0xFF7A1F30);

  @override
  Body createBody() {
    final shape = CircleShape()..radius = geometry.coinRadius;
    final fixtureDef = FixtureDef(
      shape,
      density: 1.0,
      friction: 0.05,
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

  @override
  void render(Canvas canvas) {
    final r = geometry.coinRadius;
    final fillColor = switch (type) {
      CoinType.white => _colorWhite,
      CoinType.black => _colorBlack,
      CoinType.queen => _colorQueen,
    };
    final outlineColor = switch (type) {
      CoinType.white => _outlineWhite,
      CoinType.black => _outlineBlack,
      CoinType.queen => _outlineQueen,
    };

    // Filled circle.
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()..color = fillColor,
    );

    // Thin outline.
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..color = outlineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.12,
    );

    // Small inner dot for the queen so it's instantly recognisable.
    if (type == CoinType.queen) {
      canvas.drawCircle(
        Offset.zero,
        r * 0.3,
        Paint()..color = const Color(0xFFF2D27E), // gold dot
      );
    }
  }
}

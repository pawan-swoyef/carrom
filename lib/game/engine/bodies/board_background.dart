import 'dart:ui';

import 'package:flame/components.dart';

import '../../board/board_geometry.dart';

/// The carrom board art, rendered in world space behind all physics bodies:
/// a wooden brown frame, a tan playing surface, corner pocket holes, the centre
/// double-circle, diagonal corner arrow lines and the two baseline lines with
/// their small baseline circles. Pixel-perfect art is not required; the goal is
/// that the structure reads like a real carrom board.
class BoardBackground extends Component {
  BoardBackground(this.geometry);

  final BoardGeometry geometry;

  // Wooden frame + playing surface.
  static const _frameOuter = Color(0xFF6B4A2B); // outer wood brown
  static const _frameInner = Color(0xFF8B5E3C); // lighter wood bevel
  static const _surface = Color(0xFFE3C58C); // tan playing surface
  static const _surfaceEdge = Color(0xFFCBA968); // surface inner border

  // Line / pocket colours.
  static const _line = Color(0xFF9C7A3C); // brown guide lines
  static const _baseLine = Color(0xFF7A1F30); // crimson baseline
  static const _pocketHole = Color(0xFF120D0A); // dark pocket hole
  static const _pocketRing = Color(0xFF3A2A1C); // pocket rim

  @override
  void render(Canvas canvas) {
    final h = geometry.halfBoard;

    // ── Wooden frame ────────────────────────────────────────────────────────
    final frameRect = Rect.fromCenter(
      center: Offset.zero,
      width: h * 2,
      height: h * 2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(frameRect, const Radius.circular(0.4)),
      Paint()..color = _frameOuter,
    );

    // Inner bevel.
    final bevelRect = frameRect.deflate(h * 0.04);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bevelRect, const Radius.circular(0.3)),
      Paint()..color = _frameInner,
    );

    // ── Playing surface (tan) ───────────────────────────────────────────────
    final surfaceInset = h * 0.16;
    final surfaceRect = Rect.fromCenter(
      center: Offset.zero,
      width: (h - surfaceInset) * 2,
      height: (h - surfaceInset) * 2,
    );
    canvas.drawRect(surfaceRect, Paint()..color = _surface);
    canvas.drawRect(
      surfaceRect,
      Paint()
        ..color = _surfaceEdge
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.08,
    );

    final s = h - surfaceInset; // half-extent of the playing surface

    _drawCornerArrows(canvas, s);
    _drawPockets(canvas);
    _drawCenter(canvas);
    _drawBaselines(canvas, s);
  }

  /// Diagonal corner "arrow" guide lines pointing toward each pocket.
  void _drawCornerArrows(Canvas canvas, double s) {
    final paint = Paint()
      ..color = _line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.05
      ..strokeCap = StrokeCap.round;

    final inset = s * 0.30;
    final len = s * 0.34;
    for (final sx in const [-1.0, 1.0]) {
      for (final sy in const [-1.0, 1.0]) {
        final corner = Offset(sx * (s - inset), sy * (s - inset));
        // Two short strokes forming a small arrow toward the corner.
        final tip = Offset(sx * (s - inset + len), sy * (s - inset + len));
        canvas.drawLine(corner, tip, paint);
        // Decorative dot at the inner end.
        canvas.drawCircle(corner, 0.07, Paint()..color = _line);
      }
    }
  }

  /// The four corner pocket holes (dark circles with a subtle rim).
  void _drawPockets(Canvas canvas) {
    final r = geometry.pocketRadius;
    for (final c in geometry.pocketCenters) {
      final center = Offset(c.x, -c.y); // world +y up → canvas y down
      canvas.drawCircle(center, r * 1.15, Paint()..color = _pocketRing);
      canvas.drawCircle(center, r, Paint()..color = _pocketHole);
    }
  }

  /// Centre double-circle (outer ring + inner filled dot).
  void _drawCenter(Canvas canvas) {
    final ring = Paint()
      ..color = _line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.06;
    canvas.drawCircle(Offset.zero, 0.9, ring);
    canvas.drawCircle(Offset.zero, 0.55, ring);
    canvas.drawCircle(
      Offset.zero,
      0.18,
      Paint()..color = _baseLine,
    );
  }

  /// The two baseline lines (top + bottom) with the small baseline circles at
  /// each end, matching a real carrom board.
  void _drawBaselines(Canvas canvas, double s) {
    final paint = Paint()
      ..color = _baseLine
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.07;

    // Baselines sit symmetrically; use the geometry baseline for the player's,
    // mirrored for the opponent's.
    final by = geometry.baselineY.abs();
    final xExtent = s * 0.62;

    for (final yWorld in [by, -by]) {
      final yCanvas = -yWorld; // flip for canvas
      canvas.drawLine(
        Offset(-xExtent, yCanvas),
        Offset(xExtent, yCanvas),
        paint,
      );
      // Small baseline circles at each end.
      for (final x in [-xExtent, xExtent]) {
        canvas.drawCircle(
          Offset(x, yCanvas),
          0.12,
          paint,
        );
      }
    }
  }

  /// Render before all physics bodies (lowest priority).
  @override
  int get priority => -10;
}

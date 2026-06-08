import 'dart:ui';

import 'package:flame/components.dart';

import '../../board/board_geometry.dart';

/// A simple felt-green background for the carrom board, rendered as a
/// coloured square centred on the world origin.
class BoardBackground extends Component {
  BoardBackground(this.geometry);

  final BoardGeometry geometry;

  static const _feltGreen = Color(0xFF2E6E50);
  static const _borderColor = Color(0xFF8B5E3C); // wood-brown rail border

  @override
  void render(Canvas canvas) {
    final h = geometry.halfBoard;
    final boardRect = Rect.fromCenter(
      center: Offset.zero,
      width: h * 2,
      height: h * 2,
    );

    // Felt surface
    canvas.drawRect(boardRect, Paint()..color = _feltGreen);

    // Board border / rail
    canvas.drawRect(
      boardRect,
      Paint()
        ..color = _borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.3,
    );
  }

  /// Render before all physics bodies (lowest priority).
  @override
  int get priority => -10;
}

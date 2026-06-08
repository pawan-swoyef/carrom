import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../board/board_geometry.dart';
import '../engine/carrom_game.dart';

/// Strike-control overlay that sits at the bottom of the game screen.
///
/// Provides:
///  - a horizontal slider to position the striker on the baseline;
///  - a vertical power meter the user drags;
///  - a STRIKE button that fires when the board is settled.
class StrikeControls extends StatefulWidget {
  const StrikeControls({super.key, required this.game});

  final CarromGame game;

  @override
  State<StrikeControls> createState() => _StrikeControlsState();
}

class _StrikeControlsState extends State<StrikeControls> {
  static const _defaultAngle = math.pi / 2; // straight up-field

  double _power = 0.5;
  double _angleRadians = _defaultAngle;

  // Striker-X slider value in [0,1] normalised range.
  double _strikerNorm = 0.5;

  BoardGeometry get _geo => widget.game.geometry;

  void _onStrikerSlider(double value) {
    setState(() => _strikerNorm = value);
    final x = _geo.strikerMinX + value * (_geo.strikerMaxX - _geo.strikerMinX);
    widget.game.setStrikerX(x);
  }

  void _onPowerDrag(DragUpdateDetails d, double availableHeight) {
    if (availableHeight <= 0) return;
    final delta = -d.delta.dy / availableHeight; // up = more power
    setState(() {
      _power = (_power + delta).clamp(0.0, 1.0);
    });
  }

  void _onAimDrag(DragUpdateDetails d) {
    // Compute angle from drag delta; up-screen (-y) is forward (π/2).
    final dx = d.delta.dx;
    final dy = d.delta.dy;
    if (dx.abs() + dy.abs() < 0.5) return;
    // In Flutter coords +y is down; we want +y up in physics, so negate dy.
    final angle = math.atan2(-dy, dx);
    setState(() => _angleRadians = angle);
  }

  void _strike() {
    widget.game.launch(angleRadians: _angleRadians, power: _power);
    setState(() {}); // trigger settled-check rebuild
  }

  @override
  Widget build(BuildContext context) {
    final settled = widget.game.isSettled;

    return Container(
      color: AppColors.woodDark.withValues(alpha: 0.92),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Striker position slider ──────────────────────────────
          Row(
            children: [
              const Text(
                'POS',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  letterSpacing: 1,
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.gold,
                    inactiveTrackColor: AppColors.surface,
                    thumbColor: AppColors.goldBright,
                    overlayColor: AppColors.gold.withValues(alpha: 0.2),
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 8),
                    trackHeight: 3,
                  ),
                  child: Slider(
                    value: _strikerNorm,
                    onChanged: _onStrikerSlider,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // ── Power + Aim + Strike row ─────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Power meter
              _PowerMeter(
                power: _power,
                onDragUpdate: _onPowerDrag,
              ),
              const SizedBox(width: 12),
              // Aim pad
              Expanded(
                child: _AimPad(
                  angleRadians: _angleRadians,
                  onDragUpdate: _onAimDrag,
                ),
              ),
              const SizedBox(width: 12),
              // Strike button
              _StrikeButton(
                enabled: settled,
                onPressed: _strike,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _PowerMeter extends StatelessWidget {
  const _PowerMeter({required this.power, required this.onDragUpdate});

  final double power;
  final void Function(DragUpdateDetails, double) onDragUpdate;

  @override
  Widget build(BuildContext context) {
    const height = 80.0;
    const width = 28.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'PWR',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 9,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onVerticalDragUpdate: (d) => onDragUpdate(d, height),
          child: SizedBox(
            width: width,
            height: height,
            child: CustomPaint(
              painter: _PowerMeterPainter(power: power),
            ),
          ),
        ),
      ],
    );
  }
}

class _PowerMeterPainter extends CustomPainter {
  const _PowerMeterPainter({required this.power});
  final double power;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = AppColors.surface;
    final fill = Paint()
      ..color = Color.lerp(AppColors.gold, AppColors.crimson, power)!;
    final border = Paint()
      ..color = AppColors.textMuted
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rr = RRect.fromRectXY(rect, 4, 4);
    canvas.drawRRect(rr, bg);

    final fillH = size.height * power;
    final fillRect = Rect.fromLTWH(0, size.height - fillH, size.width, fillH);
    final fillRR = RRect.fromRectXY(fillRect, 4, 4);
    canvas.drawRRect(fillRR, fill);
    canvas.drawRRect(rr, border);
  }

  @override
  bool shouldRepaint(_PowerMeterPainter old) => old.power != power;
}

class _AimPad extends StatelessWidget {
  const _AimPad({required this.angleRadians, required this.onDragUpdate});

  final double angleRadians;
  final void Function(DragUpdateDetails) onDragUpdate;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'AIM  (drag)',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 9,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onPanUpdate: onDragUpdate,
          child: Container(
            width: double.infinity,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.4)),
            ),
            child: CustomPaint(
              painter: _AimIndicatorPainter(angleRadians: angleRadians),
            ),
          ),
        ),
      ],
    );
  }
}

class _AimIndicatorPainter extends CustomPainter {
  const _AimIndicatorPainter({required this.angleRadians});
  final double angleRadians;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final len = math.min(cx, cy) * 0.85;

    // Arrow line
    final dx = math.cos(angleRadians) * len;
    // Flutter y is down; physics +y is up, so negate
    final dy = -math.sin(angleRadians) * len;

    final paint = Paint()
      ..color = AppColors.gold
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx + dx, cy + dy),
      paint,
    );

    // Arrowhead
    final angle = math.atan2(dy, dx);
    const headLen = 8.0;
    const headAngle = 0.4;
    final tip = Offset(cx + dx, cy + dy);
    canvas.drawLine(
      tip,
      Offset(
        tip.dx - headLen * math.cos(angle - headAngle),
        tip.dy - headLen * math.sin(angle - headAngle),
      ),
      paint,
    );
    canvas.drawLine(
      tip,
      Offset(
        tip.dx - headLen * math.cos(angle + headAngle),
        tip.dy - headLen * math.sin(angle + headAngle),
      ),
      paint,
    );

    // Centre dot
    canvas.drawCircle(
      Offset(cx, cy),
      3,
      Paint()..color = AppColors.goldBright,
    );
  }

  @override
  bool shouldRepaint(_AimIndicatorPainter old) =>
      old.angleRadians != angleRadians;
}

class _StrikeButton extends StatelessWidget {
  const _StrikeButton({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.crimson,
        disabledBackgroundColor: AppColors.crimsonDark,
        foregroundColor: AppColors.textLight,
        disabledForegroundColor: AppColors.textMuted,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: enabled ? 4 : 0,
      ),
      child: const Text(
        'STRIKE',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

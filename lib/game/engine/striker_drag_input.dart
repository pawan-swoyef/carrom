import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:vector_math/vector_math_64.dart' as vm64;

import '../../theme/app_colors.dart';
import '../board/aim.dart';

/// Transparent full-screen component that intercepts drag gestures and converts
/// them into striker positioning / aim / launch actions on [CarromGame].
///
/// Added to [camera.viewport] so it lives in screen space. Canvas positions are
/// converted to world coordinates via [Forge2DGame.screenToWorld].
///
/// PULL-BACK SLINGSHOT interaction (Carrom Pool style):
///
///   IDLE ──dragStart──► POSITIONING (finger near baseline)
///                   └──► AIMING    (finger already into the board)
///   POSITIONING ──fingerMovesIntoBoard──► AIMING (striker X locks)
///   AIMING ──dragEnd──► IDLE + launch (fires OPPOSITE the pull)
///   POSITIONING ──dragEnd──► IDLE  (no shot; striker stays where moved)
class StrikerDragInput extends PositionComponent
    with HasGameReference<Forge2DGame>, DragCallbacks {
  StrikerDragInput({
    required this.onUpdateAim,
    required this.onRelease,
    required this.onPower,
  }) : super(priority: 10);

  /// Called every drag-update while aiming. [strikerWorld] and [fireTarget] are
  /// world points: draw the aim line from striker toward fireTarget. When not
  /// aiming, called with [isAiming] = false (hide the line).
  final void Function(
    Vector2? strikerWorld,
    Vector2? fireTarget,
    bool isAiming,
  ) onUpdateAim;

  /// Called on drag-end if a valid shot was computed.
  final void Function(double angleRadians, double power) onRelease;

  /// Called with the live pull power 0..1 (0 when not aiming).
  final void Function(double power) onPower;

  /// Vertical threshold (world units): finger within this distance of baselineY
  /// is still in positioning mode.
  static const double _positioningBand = 0.6;

  /// Maximum pull distance for full power (world units).
  /// Tuning point: halfBoard = 5.0.
  static const double maxDrag = 5.0;

  bool _dragging = false;
  bool _aiming = false;

  // Flame's Vector2 (32-bit) for internal tracking.
  Vector2 _fingerWorld = Vector2.zero();
  Vector2 _lockedStrikerWorld = Vector2.zero();

  // ── Component setup ────────────────────────────────────────────────────────

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size; // always fill the canvas
  }

  /// Accept touches anywhere on the canvas.
  @override
  bool containsLocalPoint(Vector2 point) => true;

  // ── DragCallbacks ──────────────────────────────────────────────────────────

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    final carromGame = _carromGame;
    if (carromGame == null || !carromGame.isSettled) return;

    _dragging = true;
    _aiming = false;
    _fingerWorld = game.screenToWorld(event.canvasPosition);

    final baselineY = carromGame.geometry.baselineY as double;
    final dy = (_fingerWorld.y - baselineY).abs();

    if (dy > _positioningBand) {
      // Initial touch already into the board → aim immediately.
      _aiming = true;
      _lockedStrikerWorld = _readStrikerPos(carromGame);
    } else {
      // Near baseline → position the striker.
      carromGame.setStrikerX(_fingerWorld.x);
    }
    _emit();
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (!_dragging) return;
    final carromGame = _carromGame;
    if (carromGame == null) return;

    _fingerWorld = game.screenToWorld(event.canvasEndPosition);

    if (!_aiming) {
      final baselineY = carromGame.geometry.baselineY as double;
      final dy = (_fingerWorld.y - baselineY).abs();
      if (dy <= _positioningBand) {
        carromGame.setStrikerX(_fingerWorld.x);
      } else {
        // Crossed the threshold → lock striker X and enter aim mode.
        _aiming = true;
        _lockedStrikerWorld = _readStrikerPos(carromGame);
      }
    }
    _emit();
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (!_dragging) return;
    _dragging = false;

    if (_aiming) {
      final aim = _computeAim();
      // Releasing with zero pull is not a shot.
      if (aim.power > 0) {
        onRelease(aim.angleRadians, aim.power);
      }
    }

    _reset();
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    _reset();
    super.onDragCancel(event);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  ShotAim _computeAim() {
    final striker = vm64.Vector2(
      _lockedStrikerWorld.x.toDouble(),
      _lockedStrikerWorld.y.toDouble(),
    );
    final finger = vm64.Vector2(
      _fingerWorld.x.toDouble(),
      _fingerWorld.y.toDouble(),
    );
    return aimFromPullback(
      strikerPos: striker,
      fingerPos: finger,
      maxDrag: maxDrag,
    );
  }

  /// Pushes the current state out to the aim-line overlay + power meter.
  void _emit() {
    if (!_aiming) {
      onUpdateAim(null, null, false);
      onPower(0);
      return;
    }
    final aim = _computeAim();
    onPower(aim.power);

    // Fire target: a point ahead of the striker along the fire direction.
    // Length scales with power so the guide reads like the mockup.
    final length = 2.0 + aim.power * 6.0;
    final target = Vector2(
      _lockedStrikerWorld.x + math.cos(aim.angleRadians) * length,
      _lockedStrikerWorld.y + math.sin(aim.angleRadians) * length,
    );
    onUpdateAim(_lockedStrikerWorld.clone(), target, true);
  }

  void _reset() {
    _dragging = false;
    _aiming = false;
    onUpdateAim(null, null, false);
    onPower(0);
  }

  /// Returns the game cast as dynamic to avoid a circular dependency on
  /// CarromGame. All accessed members ([isSettled], [geometry], [setStrikerX],
  /// [striker]) are part of CarromGame's stable public API.
  dynamic get _carromGame => game;

  /// Read the current striker world position from the body (forge2d 32-bit).
  Vector2 _readStrikerPos(dynamic carromGame) {
    final pos = carromGame.striker.body.position;
    return Vector2(pos.x.toDouble(), pos.y.toDouble());
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Aim-line overlay
// ─────────────────────────────────────────────────────────────────────────────

/// Renders a DOTTED GOLD line from the striker pointing in the FIRE direction
/// (opposite the pull) while aiming. Added to [camera.viewfinder] so it renders
/// in world space.
///
/// Call [setAim] to update visibility and endpoints each frame.
class AimLineOverlay extends Component with HasGameReference<Forge2DGame> {
  bool _visible = false;
  Vector2 _from = Vector2.zero();
  Vector2 _to = Vector2.zero();

  /// Update the aim-line state. [from] (striker) and [to] (fire target) are in
  /// world coordinates.
  void setAim({required bool visible, Vector2? from, Vector2? to}) {
    _visible = visible;
    if (from != null) _from = from.clone();
    if (to != null) _to = to.clone();
  }

  @override
  void render(Canvas canvas) {
    if (!_visible) return;

    // This component is added to camera.viewfinder. The viewfinder applies
    // its own transform (zoom + translation) before calling render, so to draw
    // at world point (wx, wy) relative to viewfinder we use (local.x, -local.y).
    final zoom = game.camera.viewfinder.zoom;
    final vfPos = game.camera.viewfinder.position;

    final fromLocal = (_from - vfPos) * zoom;
    final toLocal = (_to - vfPos) * zoom;

    final fromOffset = Offset(fromLocal.x, -fromLocal.y);
    final toOffset = Offset(toLocal.x, -toLocal.y);

    // ─ Dotted gold guide line ─────────────────────────────────────────────────
    final paint = Paint()
      ..color = AppColors.gold
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    _drawDottedLine(canvas, fromOffset, toOffset, paint, dash: 9, gap: 7);

    // ─ Direction tip ──────────────────────────────────────────────────────────
    canvas.drawCircle(
      toOffset,
      5.0,
      Paint()..color = AppColors.goldBright,
    );
  }

  /// Draws a dashed line between [a] and [b] using [dash]-px segments separated
  /// by [gap]-px gaps (both in canvas pixels).
  void _drawDottedLine(
    Canvas canvas,
    Offset a,
    Offset b,
    Paint paint, {
    required double dash,
    required double gap,
  }) {
    final delta = b - a;
    final total = delta.distance;
    if (total == 0) return;
    final dir = delta / total;
    var drawn = 0.0;
    while (drawn < total) {
      final start = a + dir * drawn;
      final end = a + dir * math.min(drawn + dash, total);
      canvas.drawLine(start, end, paint);
      drawn += dash + gap;
    }
  }
}

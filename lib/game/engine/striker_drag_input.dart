import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:vector_math/vector_math_64.dart' as vm64;

import '../board/aim.dart';

/// Transparent full-screen component that intercepts drag gestures and converts
/// them into striker positioning / aim / launch actions on [CarromGame].
///
/// Added to [camera.viewport] so it lives in screen space. Canvas positions are
/// converted to world coordinates via [Forge2DGame.screenToWorld].
///
/// Interaction state machine:
///
///   IDLE ──dragStart──► POSITIONING (finger near baseline)
///                   └──► AIMING    (finger already far from baseline)
///   POSITIONING ──fingerMovesUp──► AIMING
///   AIMING ──dragEnd──► IDLE + launch
///   POSITIONING ──dragEnd──► IDLE  (no shot; striker stays where moved)
class StrikerDragInput extends PositionComponent
    with HasGameReference<Forge2DGame>, DragCallbacks {
  StrikerDragInput({required this.onUpdateAim, required this.onRelease})
    : super(priority: 10);

  /// Called every drag-update: [fingerWorld] is null when not dragging.
  final void Function(Vector2? fingerWorld, bool isAiming) onUpdateAim;

  /// Called on drag-end if a valid shot was computed.
  final void Function(double angleRadians, double power) onRelease;

  /// Vertical threshold (world units): finger within this distance of baselineY
  /// is still in positioning mode.
  static const double _positioningBand = 0.6;

  /// Maximum drag distance for full power (world units).
  /// Tuning point: halfBoard = 5.0. Increase for gentler power curve.
  static const double maxDrag = 5.0;

  bool _dragging = false;
  bool _aiming = false;

  // Flame's Vector2 (32-bit) for internal tracking
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
      // Initial touch already far from baseline → aim immediately.
      _aiming = true;
      _lockedStrikerWorld = _readStrikerPos(carromGame);
    } else {
      // Near baseline → position the striker.
      carromGame.setStrikerX(_fingerWorld.x);
    }
    onUpdateAim(_fingerWorld, _aiming);
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
    onUpdateAim(_fingerWorld, _aiming);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (!_dragging) return;
    _dragging = false;

    if (_aiming) {
      // Convert to vm64.Vector2 for aimFromDrag (uses vector_math_64).
      final strikerV64 = vm64.Vector2(
        _lockedStrikerWorld.x.toDouble(),
        _lockedStrikerWorld.y.toDouble(),
      );
      final fingerV64 = vm64.Vector2(
        _fingerWorld.x.toDouble(),
        _fingerWorld.y.toDouble(),
      );
      final aim = aimFromDrag(
        striker: strikerV64,
        finger: fingerV64,
        maxDrag: maxDrag,
      );
      if (aim != null) {
        onRelease(aim.angleRadians, aim.power);
      }
    }

    _aiming = false;
    onUpdateAim(null, false);
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    _dragging = false;
    _aiming = false;
    onUpdateAim(null, false);
    super.onDragCancel(event);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

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

/// Renders a gold line + crimson dot from the striker toward the finger while
/// aiming. Added to [camera.viewfinder] so it renders in world space.
///
/// Call [setAim] to update visibility and endpoints each frame.
class AimLineOverlay extends Component with HasGameReference<Forge2DGame> {
  bool _visible = false;
  Vector2 _from = Vector2.zero();
  Vector2 _to = Vector2.zero();

  /// Update the aim-line state. [from] and [to] are in world coordinates.
  void setAim({required bool visible, Vector2? from, Vector2? to}) {
    _visible = visible;
    if (from != null) _from = from.clone();
    if (to != null) _to = to.clone();
  }

  @override
  void render(Canvas canvas) {
    if (!_visible) return;

    // This component is added to camera.viewfinder. The viewfinder applies
    // its own transform (zoom + translation) before calling render, so the
    // canvas coordinate system here is:
    //   origin = viewfinder.position in world units (board centre)
    //   scale  = zoom px per world unit
    //   y-axis = DOWN (canvas convention, opposite to physics world +y up)
    //
    // Therefore to draw at world point (wx, wy) we simply use (wx, -wy).
    final zoom = game.camera.viewfinder.zoom;
    final vfPos = game.camera.viewfinder.position;

    // World → canvas-local (accounting for camera pan and zoom)
    final fromLocal = (_from - vfPos) * zoom;
    final toLocal = (_to - vfPos) * zoom;

    final fromOffset = Offset(fromLocal.x, -fromLocal.y);
    final toOffset = Offset(toLocal.x, -toLocal.y);

    // ─ Aim line ──────────────────────────────────────────────────────────────
    final linePaint =
        Paint()
          ..color = const Color(0xFFFFD700) // gold
          ..strokeWidth = 3.0
          ..strokeCap = StrokeCap.round;

    canvas.drawLine(fromOffset, toOffset, linePaint);

    // ─ Finger-tip dot ────────────────────────────────────────────────────────
    canvas.drawCircle(
      toOffset,
      6.0,
      Paint()..color = const Color(0xFFDC143C), // crimson
    );
  }
}

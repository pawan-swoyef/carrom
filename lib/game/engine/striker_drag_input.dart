import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:vector_math/vector_math_64.dart' as vm64;

import '../../theme/app_colors.dart';
import '../board/aim.dart';
import '../board/aim_prediction.dart';
import 'striker_phase.dart';

/// Transparent full-screen component that intercepts drag gestures and converts
/// them into striker positioning / aim / launch actions on [CarromGame].
///
/// Added to [camera.viewport] so it lives in screen space. Canvas positions are
/// converted to world coordinates via [Forge2DGame.screenToWorld].
///
/// FSM-DRIVEN: the component reads [CarromGame.phase] and [CarromGame.interactive]
/// and only acts when the phase is [StrikerPhase.placing] or
/// [StrikerPhase.aiming]. SIMULATING (and non-interactive turns) ignore all
/// touches.
///
/// PULL-BACK SLINGSHOT interaction (Carrom Pool style):
///
///   PLACING ──dragStart near baseline──► reposition striker (setStrikerX)
///   PLACING ──fingerLeavesBand────────► AIMING (beginAiming + lock striker X)
///   AIMING  ──dragUpdate──────────────► predictive aim line + ghost circle
///   AIMING  ──dragEnd (power>deadZone)─► launch (fires OPPOSITE the pull)
///   AIMING  ──dragEnd (power<=deadZone)► cancelAiming → PLACING
class StrikerDragInput extends PositionComponent
    with HasGameReference<Forge2DGame>, DragCallbacks {
  StrikerDragInput({
    required this.onUpdateAim,
    required this.onRelease,
    required this.onPower,
  }) : super(priority: 10);

  /// Called every drag-update. [strikerWorld] is the (locked) striker centre and
  /// [impact] is the predicted impact point — draw the aim line + ghost circle
  /// between them. [hitCoin] is true when the predicted impact is a coin (so the
  /// overlay can highlight). When not aiming, called with [isAiming] = false.
  final void Function(
    Vector2? strikerWorld,
    Vector2? impact,
    bool hitCoin,
    bool isAiming,
  ) onUpdateAim;

  /// Called on drag-end if a valid shot was computed (power past the dead-zone).
  final void Function(double angleRadians, double power) onRelease;

  /// Called with the live pull power 0..1 (0 when not aiming).
  final void Function(double power) onPower;

  /// Vertical threshold (world units): finger within this distance of baselineY
  /// is still in positioning mode. Device-tuning point.
  static const double positioningBand = 0.6;

  /// Maximum pull distance for full power (world units). Device-tuning point.
  /// (halfBoard = 5.0.)
  static const double maxDrag = 5.0;

  /// Releases with power below this are treated as a cancel, not a shot.
  /// Device-tuning point.
  static const double deadZone = 0.05;

  bool _dragging = false;

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
    if (!_canInteract(carromGame)) return;

    _dragging = true;
    _fingerWorld = game.screenToWorld(event.canvasPosition);

    final baselineY = carromGame.geometry.baselineY as double;
    final dy = (_fingerWorld.y - baselineY).abs();

    if (dy > positioningBand) {
      // Initial touch already away from the baseline band → aim immediately.
      _beginAiming(carromGame);
    } else {
      // Near baseline → position the striker.
      carromGame.setStrikerX(_fingerWorld.x);
    }
    _emit(carromGame);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (!_dragging) return;
    final carromGame = _carromGame;
    if (carromGame == null) return;

    _fingerWorld = game.screenToWorld(event.canvasEndPosition);

    if (_phaseOf(carromGame) == StrikerPhase.placing) {
      final baselineY = carromGame.geometry.baselineY as double;
      final dy = (_fingerWorld.y - baselineY).abs();
      if (dy <= positioningBand) {
        carromGame.setStrikerX(_fingerWorld.x);
      } else {
        // Crossed the band → lock striker X and enter aim mode.
        _beginAiming(carromGame);
      }
    }
    _emit(carromGame);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (!_dragging) return;
    final carromGame = _carromGame;
    _dragging = false;

    if (carromGame != null && _phaseOf(carromGame) == StrikerPhase.aiming) {
      final aim = _computeAim();
      if (aim.power > deadZone) {
        onRelease(aim.angleRadians, aim.power);
      } else {
        carromGame.cancelAiming();
      }
    }

    _reset();
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    final carromGame = _carromGame;
    if (carromGame != null && _phaseOf(carromGame) == StrikerPhase.aiming) {
      carromGame.cancelAiming();
    }
    _reset();
    super.onDragCancel(event);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// True when the game is loaded, settled, interactive, and in a phase that
  /// accepts touch input (placing or aiming).
  bool _canInteract(dynamic carromGame) {
    if (carromGame == null) return false;
    if (!(carromGame.interactive as bool)) return false;
    if (!(carromGame.isSettled as bool)) return false;
    final phase = _phaseOf(carromGame);
    return phase == StrikerPhase.placing || phase == StrikerPhase.aiming;
  }

  StrikerPhase _phaseOf(dynamic carromGame) =>
      carromGame.phase.value as StrikerPhase;

  /// Transition the game to AIMING and capture the locked striker world point.
  void _beginAiming(dynamic carromGame) {
    carromGame.beginAiming();
    _lockedStrikerWorld = _readStrikerPos(carromGame);
  }

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

  /// Pushes the current state out to the aim overlay + power meter.
  void _emit(dynamic carromGame) {
    if (_phaseOf(carromGame) != StrikerPhase.aiming) {
      onUpdateAim(null, null, false, false);
      onPower(0);
      return;
    }
    final aim = _computeAim();
    onPower(aim.power);

    if (aim.power <= 0) {
      // No pull yet: nothing meaningful to predict.
      onUpdateAim(null, null, false, false);
      return;
    }

    final geometry = carromGame.geometry;
    final strikerRadius = geometry.strikerRadius as double;
    final halfBoard = geometry.halfBoard as double;
    final coinRadius = geometry.coinRadius as double;

    // Predictive raycast runs in vector_math_64 space (the pure function's
    // type). Build vm64 vectors at the boundary from forge2d body positions.
    final origin = vm64.Vector2(
      _lockedStrikerWorld.x.toDouble(),
      _lockedStrikerWorld.y.toDouble(),
    );
    final dir = vm64.Vector2(
      math.cos(aim.angleRadians),
      math.sin(aim.angleRadians),
    );
    final coins = <AimCircle>[
      for (final c in (carromGame.coins as List))
        AimCircle(
          vm64.Vector2(
            (c.body.position.x as num).toDouble(),
            (c.body.position.y as num).toDouble(),
          ),
          coinRadius,
        ),
    ];

    final impact = predictImpact(
      origin: origin,
      dir: dir,
      strikerRadius: strikerRadius,
      halfBoard: halfBoard,
      coins: coins,
    );

    // Hand the overlay forge2d (32-bit) Vector2s for drawing.
    final impactWorld = Vector2(impact.point.x, impact.point.y);
    onUpdateAim(
      _lockedStrikerWorld.clone(),
      impactWorld,
      impact.type == ImpactType.coin,
      true,
    );
  }

  void _reset() {
    _dragging = false;
    onUpdateAim(null, null, false, false);
    onPower(0);
  }

  /// Returns the game cast as dynamic to avoid a circular dependency on
  /// CarromGame. All accessed members ([isSettled], [interactive], [phase],
  /// [geometry], [coins], [setStrikerX], [beginAiming], [cancelAiming],
  /// [striker]) are part of CarromGame's stable public API.
  dynamic get _carromGame => game;

  /// Read the current striker world position from the body (forge2d 32-bit).
  Vector2 _readStrikerPos(dynamic carromGame) {
    final pos = carromGame.striker.body.position;
    return Vector2(pos.x.toDouble(), pos.y.toDouble());
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Predictive aim overlay
// ─────────────────────────────────────────────────────────────────────────────

/// Renders a DOTTED GOLD line from the striker to the predicted IMPACT POINT,
/// plus a stroked "ghost" striker circle at that impact point. Added to
/// [camera.viewfinder] so it renders in world space.
///
/// The ghost circle is gold when the predicted impact is a wall, and a brighter
/// crimson tint when a coin will be struck — so the player can see they are
/// lined up on a coin.
///
/// Call [setAim] to update visibility, endpoints, and the hit-coin flag.
class AimLineOverlay extends Component with HasGameReference<Forge2DGame> {
  bool _visible = false;
  bool _hitCoin = false;
  Vector2 _from = Vector2.zero();
  Vector2 _to = Vector2.zero();

  /// Update the aim-preview state. [from] (striker centre) and [to] (impact
  /// point) are in world coordinates. [hitCoin] highlights the ghost circle.
  void setAim({
    required bool visible,
    Vector2? from,
    Vector2? to,
    bool hitCoin = false,
  }) {
    _visible = visible;
    _hitCoin = hitCoin;
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
    final linePaint = Paint()
      ..color = AppColors.gold
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    _drawDottedLine(canvas, fromOffset, toOffset, linePaint, dash: 9, gap: 7);

    // ─ Ghost target circle at the impact point ──────────────────────────────
    // strikerRadius is a world length; canvas px = world * zoom.
    final geometry = (game as dynamic).geometry;
    final strikerRadius = geometry.strikerRadius as double;
    final ghostRadius = strikerRadius * zoom;

    final ghostColor = _hitCoin ? AppColors.crimson : AppColors.gold;
    final ghostPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _hitCoin ? 3.0 : 2.0
      ..color = ghostColor.withValues(alpha: _hitCoin ? 0.95 : 0.7);

    canvas.drawCircle(toOffset, ghostRadius, ghostPaint);

    // Faint fill so the ghost reads as a disc, brighter when hitting a coin.
    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = ghostColor.withValues(alpha: _hitCoin ? 0.22 : 0.10);
    canvas.drawCircle(toOffset, ghostRadius, fillPaint);
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

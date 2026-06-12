import 'package:flame/components.dart' show Anchor;
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/foundation.dart';

import '../board/board_geometry.dart';
import '../board/coin_layout.dart';
import '../board/settle_detector.dart';
import '../board/strike_math.dart';
import '../rules/strike_outcome.dart';
import 'bodies/board_background.dart';
import 'bodies/coin_body.dart';
import 'bodies/pocket_body.dart';
import 'bodies/striker_body.dart';
import 'bodies/wall_body.dart';
import 'strike_result.dart';
import 'striker_drag_input.dart';

/// The Forge2D physics world for a carrom board: static rails, four corner
/// pocket sensors, 19 coins (9 white, 9 black, queen) and the striker. Pocket
/// sensors call [capture]; captured bodies are removed in [update] (the physics
/// world is locked during contact callbacks, so removal must be deferred).
class CarromGame extends Forge2DGame {
  // Portrait layout: the board is ~10 units wide/tall (halfBoard=5).
  // zoom=40 maps 1 physics unit → 40 logical pixels, so the 10-unit board
  // spans 400 pixels — comfortable on a portrait phone.
  CarromGame() : super(gravity: Vector2.zero(), zoom: 40);

  final BoardGeometry geometry = const BoardGeometry();

  final List<CoinBody> coins = [];
  final List<PocketBody> pockets = [];

  // Nullable until _placePieces completes; all public API guards on this so
  // it is safe to call isSettled / setStrikerX / launch before onLoad finishes.
  StrikerBody? _striker;

  /// The active striker. Only valid after [onLoad] has completed.
  StrikerBody get striker => _striker!;

  final StrikeResult _result = StrikeResult();
  final List<BodyComponent> _toCapture = [];

  static const _settle = SettleDetector();

  // Aim-line overlay — kept as a field so we can call setAim() from the drag
  // input's callbacks without a separate lookup.
  late final AimLineOverlay _aimLine;

  // Current pull-back power (0..1) while aiming, 0 otherwise. Driven by the
  // drag input; read by the STRIKE POWER meter via a ValueListenableBuilder.
  final ValueNotifier<double> _strikePower = ValueNotifier<double>(0);

  /// Live pull-back power in [0, 1] for the strike-power meter. 0 when idle.
  ValueListenable<double> get strikePower => _strikePower;

  // ──────────────────────────────────────────────────────────────────
  // Control API
  // ──────────────────────────────────────────────────────────────────

  /// True when every coin and the striker are below the rest-speed threshold.
  /// Returns false (not ready) if the board has not finished loading yet.
  bool get isSettled {
    if (_striker == null) return false;
    final speeds = <double>[
      ...coins.map((c) => c.body.linearVelocity.length),
      _striker!.body.linearVelocity.length,
    ];
    return _settle.isSettled(speeds);
  }

  /// Moves the striker to [x] on the baseline. Only effective when settled.
  void setStrikerX(double x) {
    if (!isSettled) return;
    final clamped = StrikeMath(geometry).clampStrikerX(x);
    // Vector2 here is forge2d's 32-bit version (from flame_forge2d import).
    _striker!.body.setTransform(Vector2(clamped, geometry.baselineY), 0);
    _striker!.body.linearVelocity = Vector2.zero();
    _striker!.body.angularVelocity = 0;
  }

  /// Launches the striker. Only effective when settled.
  void launch({required double angleRadians, required double power}) {
    if (!isSettled) return;
    _result.reset();
    _strikePower.value = 0;
    _striker!.captured = false;
    // StrikeMath.impulse returns vector_math_64.Vector2; extract x,y to build
    // the forge2d (32-bit) Vector2 that applyLinearImpulse expects.
    final imp =
        StrikeMath(geometry).impulse(angleRadians: angleRadians, power: power);
    _striker!.body.applyLinearImpulse(Vector2(imp.x, imp.y));
  }

  /// Removes all coins and the striker, then rebuilds the opening layout with
  /// a fresh striker at the baseline. Clears any pending strike result.
  Future<void> resetBoard() async {
    for (final coin in List<CoinBody>.from(coins)) {
      coin.removeFromParent();
    }
    coins.clear();

    _striker?.removeFromParent();
    _striker = null;
    _result.reset();
    _strikePower.value = 0;
    _toCapture.clear();

    await _placePieces();
  }

  // ──────────────────────────────────────────────────────────────────
  // Lifecycle
  // ──────────────────────────────────────────────────────────────────

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Centre camera on board origin; +y is up-field (flame default).
    camera.viewfinder.position = Vector2.zero();
    camera.viewfinder.anchor = Anchor.center;

    await world.add(BoardBackground(geometry));
    await world.add(WallBody(geometry));

    for (final center in geometry.pocketCenters) {
      final pocket = PocketBody(
        geometry: geometry,
        pocketCenter: Vector2(center.x, center.y),
      );
      pockets.add(pocket);
      await world.add(pocket);
    }

    await _placePieces();

    // ── Drag-to-strike input ─────────────────────────────────────────
    // AimLineOverlay lives in the viewfinder so it renders in world space.
    _aimLine = AimLineOverlay();
    await camera.viewfinder.add(_aimLine);

    // StrikerDragInput lives in the viewport (screen space) so it covers the
    // full canvas and receives touch events before world components do.
    await camera.viewport.add(
      StrikerDragInput(
        onUpdateAim: (strikerWorld, fireTarget, isAiming) {
          if (!isAiming || strikerWorld == null || fireTarget == null) {
            _aimLine.setAim(visible: false);
          } else {
            _aimLine.setAim(
              visible: true,
              from: strikerWorld,
              to: fireTarget,
            );
          }
        },
        onPower: (power) {
          _strikePower.value = power;
        },
        onRelease: (angleRadians, power) {
          launch(angleRadians: angleRadians, power: power);
        },
      ),
    );
  }

  /// Places 19 coins + a fresh striker. Used by [onLoad] and [resetBoard].
  Future<void> _placePieces() async {
    for (final placement in buildOpeningLayout(geometry)) {
      final coin = CoinBody(
        geometry: geometry,
        type: placement.type,
        startPosition: Vector2(placement.position.x, placement.position.y),
      );
      coins.add(coin);
      await world.add(coin);
    }

    final s = StrikerBody(geometry);
    _striker = s;
    await world.add(s);
  }

  // ──────────────────────────────────────────────────────────────────
  // Capture / update
  // ──────────────────────────────────────────────────────────────────

  /// Called from [PocketBody.beginContact]. Marks the captured piece and queues
  /// it for deferred removal. Guards against double-capture.
  void capture(BodyComponent body) {
    if (body is CoinBody) {
      if (body.captured) return;
      body.captured = true;
      _result.pocketed.add(body.type);
      _toCapture.add(body);
    } else if (body is StrikerBody) {
      if (body.captured) return;
      body.captured = true;
      _result.strikerPocketed = true;
      _toCapture.add(body);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_toCapture.isEmpty) return;
    for (final body in _toCapture) {
      if (body is CoinBody) coins.remove(body);
      body.removeFromParent();
    }
    _toCapture.clear();
  }

  @override
  void onRemove() {
    _strikePower.dispose();
    super.onRemove();
  }

  /// Returns and clears the accumulated outcome of the current strike.
  StrikeOutcome takeStrikeResult() {
    final outcome = _result.toOutcome();
    _result.reset();
    return outcome;
  }
}

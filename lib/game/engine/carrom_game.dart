import 'package:flame_forge2d/flame_forge2d.dart';

import '../board/board_geometry.dart';
import '../board/coin_layout.dart';
import '../rules/strike_outcome.dart';
import 'bodies/coin_body.dart';
import 'bodies/pocket_body.dart';
import 'bodies/striker_body.dart';
import 'bodies/wall_body.dart';
import 'strike_result.dart';

/// The Forge2D physics world for a carrom board: static rails, four corner
/// pocket sensors, 19 coins (9 white, 9 black, queen) and the striker. Pocket
/// sensors call [capture]; captured bodies are removed in [update] (the physics
/// world is locked during contact callbacks, so removal must be deferred).
class CarromGame extends Forge2DGame {
  CarromGame() : super(gravity: Vector2.zero());

  final BoardGeometry geometry = const BoardGeometry();

  final List<CoinBody> coins = [];
  final List<PocketBody> pockets = [];
  late final StrikerBody striker;

  final StrikeResult _result = StrikeResult();
  final List<BodyComponent> _toCapture = [];

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    await world.add(WallBody(geometry));

    for (final center in geometry.pocketCenters) {
      final pocket = PocketBody(
        geometry: geometry,
        pocketCenter: Vector2(center.x, center.y),
      );
      pockets.add(pocket);
      await world.add(pocket);
    }

    for (final placement in buildOpeningLayout(geometry)) {
      final coin = CoinBody(
        geometry: geometry,
        type: placement.type,
        startPosition: Vector2(placement.position.x, placement.position.y),
      );
      coins.add(coin);
      await world.add(coin);
    }

    striker = StrikerBody(geometry);
    await world.add(striker);
  }

  /// Called from [PocketBody.beginContact]. Marks the captured piece and queues
  /// it for deferred removal. Guards against double-capture.
  void capture(BodyComponent body) {
    if (body is CoinBody) {
      if (body.captured) {
        return;
      }
      body.captured = true;
      _result.pocketed.add(body.type);
      _toCapture.add(body);
    } else if (body is StrikerBody) {
      if (body.captured) {
        return;
      }
      body.captured = true;
      _result.strikerPocketed = true;
      _toCapture.add(body);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_toCapture.isEmpty) {
      return;
    }
    for (final body in _toCapture) {
      if (body is CoinBody) {
        coins.remove(body);
      }
      body.removeFromParent();
    }
    _toCapture.clear();
  }

  /// Returns and clears the accumulated outcome of the current strike.
  StrikeOutcome takeStrikeResult() {
    final outcome = _result.toOutcome();
    _result.reset();
    return outcome;
  }
}

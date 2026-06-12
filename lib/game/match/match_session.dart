import 'package:flutter/foundation.dart';
import '../game_launch_args.dart';
import '../rules/coin_type.dart';
import '../rules/match_state.dart';
import '../rules/player.dart';
import '../rules/rules_engine.dart';
import '../rules/strike_outcome.dart';
import 'player_kind.dart';

/// High-level queen state for the HUD pill.
enum QueenStatus { onBoard, pendingCover, covered }

/// Owns the live [MatchState] for one match and advances it via the pure
/// [RulesEngine]. UI listens to this for HUD updates.
class MatchSession extends ChangeNotifier {
  final GameMode mode;
  final RulesEngine _engine;
  MatchState _state;

  MatchSession({
    required this.mode,
    CoinType playerOneColor = CoinType.white,
    RulesEngine engine = const RulesEngine(),
  })  : _engine = engine,
        _state = MatchState.initial(playerOneColor: playerOneColor);

  MatchState get state => _state;
  Player get currentPlayer => _state.currentPlayer;
  bool get isOver => _state.isGameOver;
  Player? get winner => _state.winner;

  CoinType colorOf(Player p) => _state.colorOf(p);
  int coinsRemainingFor(Player p) => _state.remainingFor(p);

  PlayerKind kindOf(Player p) {
    if (mode == GameMode.vsComputer && p == Player.two) return PlayerKind.ai;
    return PlayerKind.human;
  }

  /// True when it is currently the AI seat's turn (vsComputer only).
  bool get turnIsAI => kindOf(currentPlayer) == PlayerKind.ai;

  QueenStatus get queenStatus {
    if (!_state.queenOnBoard && _state.queenCoverPending) {
      return QueenStatus.pendingCover;
    }
    if (!_state.queenOnBoard) return QueenStatus.covered;
    return QueenStatus.onBoard;
  }

  /// Advances the match by one resolved strike.
  void applyStrike(StrikeOutcome outcome) {
    if (_state.isGameOver) return;
    _state = _engine.resolve(_state, outcome);
    notifyListeners();
  }
}

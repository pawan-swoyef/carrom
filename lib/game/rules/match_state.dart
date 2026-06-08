import 'coin_type.dart';
import 'player.dart';

/// Immutable snapshot of a carrom match. Mutated only via [RulesEngine].
class MatchState {
  final Player currentPlayer;
  final CoinType playerOneColor; // white or black; player two owns the other
  final int whiteRemaining;
  final int blackRemaining;
  final bool queenOnBoard;
  final bool queenCoverPending; // currentPlayer must cover on the next strike
  final Player? winner;

  const MatchState({
    required this.currentPlayer,
    required this.playerOneColor,
    required this.whiteRemaining,
    required this.blackRemaining,
    required this.queenOnBoard,
    required this.queenCoverPending,
    this.winner,
  });

  factory MatchState.initial({CoinType playerOneColor = CoinType.white}) {
    return MatchState(
      currentPlayer: Player.one,
      playerOneColor: playerOneColor,
      whiteRemaining: 9,
      blackRemaining: 9,
      queenOnBoard: true,
      queenCoverPending: false,
    );
  }

  bool get isGameOver => winner != null;

  CoinType colorOf(Player p) =>
      p == Player.one ? playerOneColor : otherColor(playerOneColor);

  int remainingOfColor(CoinType color) =>
      color == CoinType.white ? whiteRemaining : blackRemaining;

  int remainingFor(Player p) => remainingOfColor(colorOf(p));

  MatchState copyWith({
    Player? currentPlayer,
    CoinType? playerOneColor,
    int? whiteRemaining,
    int? blackRemaining,
    bool? queenOnBoard,
    bool? queenCoverPending,
    Player? winner,
  }) {
    return MatchState(
      currentPlayer: currentPlayer ?? this.currentPlayer,
      playerOneColor: playerOneColor ?? this.playerOneColor,
      whiteRemaining: whiteRemaining ?? this.whiteRemaining,
      blackRemaining: blackRemaining ?? this.blackRemaining,
      queenOnBoard: queenOnBoard ?? this.queenOnBoard,
      queenCoverPending: queenCoverPending ?? this.queenCoverPending,
      winner: winner ?? this.winner,
    );
  }
}

import 'coin_type.dart';
import 'match_state.dart';
import 'player.dart';
import 'strike_outcome.dart';

/// Pure carrom rules. Given a [MatchState] and the [StrikeOutcome] of one
/// strike, returns the next [MatchState].
class RulesEngine {
  const RulesEngine();

  MatchState resolve(MatchState state, StrikeOutcome outcome) {
    if (state.isGameOver) return state;

    final p = state.currentPlayer;
    final myColor = state.colorOf(p);

    final pocketedWhite =
        outcome.pocketed.where((c) => c == CoinType.white).length;
    final pocketedBlack =
        outcome.pocketed.where((c) => c == CoinType.black).length;
    final queenPocketed = outcome.pocketed.contains(CoinType.queen);
    final myPocketed = myColor == CoinType.white ? pocketedWhite : pocketedBlack;

    var white = state.whiteRemaining - pocketedWhite;
    var black = state.blackRemaining - pocketedBlack;
    var queenOnBoard = queenPocketed ? false : state.queenOnBoard;
    var coverPending = state.queenCoverPending;

    int colorCount(CoinType color) => color == CoinType.white ? white : black;
    void returnOne(CoinType color) {
      if (color == CoinType.white) {
        white += 1;
      } else {
        black += 1;
      }
    }

    // ---- FOUL: striker pocketed ----
    if (outcome.strikerPocketed) {
      white += pocketedWhite;
      black += pocketedBlack;
      if (queenPocketed) queenOnBoard = true;
      if (coverPending) queenOnBoard = true;
      if (colorCount(myColor) < 9) returnOne(myColor);
      return state.copyWith(
        currentPlayer: other(p),
        whiteRemaining: white,
        blackRemaining: black,
        queenOnBoard: queenOnBoard,
        queenCoverPending: false,
      );
    }

    // ---- LEGAL STRIKE ----
    if (coverPending) {
      if (myPocketed >= 1) {
        coverPending = false;
      } else {
        queenOnBoard = true;
        coverPending = false;
      }
    } else if (queenPocketed) {
      if (myPocketed < 1) {
        coverPending = true;
      }
    }

    final continues = myPocketed >= 1 || queenPocketed;

    // ---- WIN CHECK ----
    if (colorCount(myColor) == 0) {
      if (!queenOnBoard && !coverPending) {
        return state.copyWith(
          winner: p,
          whiteRemaining: white,
          blackRemaining: black,
          queenOnBoard: queenOnBoard,
          queenCoverPending: false,
        );
      }
      returnOne(myColor);
      // Defensive: reaching count==0 requires pocketing your own last coin this
      // strike, which already resolves any pending cover above, so coverPending
      // is effectively always false here. Kept as belt-and-suspenders.
      if (coverPending) {
        queenOnBoard = true;
        coverPending = false;
      }
      return state.copyWith(
        currentPlayer: other(p),
        whiteRemaining: white,
        blackRemaining: black,
        queenOnBoard: queenOnBoard,
        queenCoverPending: false,
      );
    }

    // ---- CONTINUE OR PASS ----
    return state.copyWith(
      currentPlayer: continues ? p : other(p),
      whiteRemaining: white,
      blackRemaining: black,
      queenOnBoard: queenOnBoard,
      queenCoverPending: continues ? coverPending : false,
    );
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:carrom_pro/game/rules/coin_type.dart';
import 'package:carrom_pro/game/rules/player.dart';
import 'package:carrom_pro/game/rules/match_state.dart';
import 'package:carrom_pro/game/rules/strike_outcome.dart';
import 'package:carrom_pro/game/rules/rules_engine.dart';

void main() {
  final engine = RulesEngine();

  MatchState start() => MatchState.initial();

  group('basic turn flow', () {
    test('pocketing your own coin lets you strike again', () {
      final s = engine.resolve(
        start(),
        const StrikeOutcome(pocketed: [CoinType.white]),
      );
      expect(s.currentPlayer, Player.one);
      expect(s.whiteRemaining, 8);
      expect(s.blackRemaining, 9);
    });

    test('pocketing nothing passes the turn', () {
      final s = engine.resolve(start(), const StrikeOutcome());
      expect(s.currentPlayer, Player.two);
      expect(s.whiteRemaining, 9);
    });

    test('pocketing only the opponent coin credits them and passes turn', () {
      final s = engine.resolve(
        start(),
        const StrikeOutcome(pocketed: [CoinType.black]),
      );
      expect(s.currentPlayer, Player.two);
      expect(s.blackRemaining, 8);
      expect(s.whiteRemaining, 9);
    });

    test('pocketing own + opponent coin: counts both, strike again', () {
      final s = engine.resolve(
        start(),
        const StrikeOutcome(pocketed: [CoinType.white, CoinType.black]),
      );
      expect(s.currentPlayer, Player.one);
      expect(s.whiteRemaining, 8);
      expect(s.blackRemaining, 8);
    });
  });

  group('striker foul', () {
    test('striker pocketed with nothing else: penalty when coins banked', () {
      final banked = start().copyWith(whiteRemaining: 8);
      final s = engine.resolve(
        banked,
        const StrikeOutcome(strikerPocketed: true),
      );
      expect(s.currentPlayer, Player.two);
      expect(s.whiteRemaining, 9);
    });

    test('striker foul returns coins pocketed on the same strike', () {
      final s = engine.resolve(
        start(),
        const StrikeOutcome(pocketed: [CoinType.white], strikerPocketed: true),
      );
      expect(s.currentPlayer, Player.two);
      expect(s.whiteRemaining, 9);
    });

    test('no penalty coin when player has banked nothing yet', () {
      final s = engine.resolve(
        start(),
        const StrikeOutcome(strikerPocketed: true),
      );
      expect(s.currentPlayer, Player.two);
      expect(s.whiteRemaining, 9);
    });
  });

  group('queen cover', () {
    test('queen + own coin same strike = secured immediately', () {
      final s = engine.resolve(
        start(),
        const StrikeOutcome(pocketed: [CoinType.queen, CoinType.white]),
      );
      expect(s.queenOnBoard, false);
      expect(s.queenCoverPending, false);
      expect(s.currentPlayer, Player.one);
      expect(s.whiteRemaining, 8);
    });

    test('queen alone = cover pending, same player strikes again', () {
      final s = engine.resolve(
        start(),
        const StrikeOutcome(pocketed: [CoinType.queen]),
      );
      expect(s.queenOnBoard, false);
      expect(s.queenCoverPending, true);
      expect(s.currentPlayer, Player.one);
    });

    test('pending cover succeeds when own coin pocketed next', () {
      final pending = start().copyWith(queenOnBoard: false, queenCoverPending: true);
      final s = engine.resolve(
        pending,
        const StrikeOutcome(pocketed: [CoinType.white]),
      );
      expect(s.queenCoverPending, false);
      expect(s.queenOnBoard, false);
      expect(s.currentPlayer, Player.one);
      expect(s.whiteRemaining, 8);
    });

    test('pending cover fails when nothing pocketed: queen returns', () {
      final pending = start().copyWith(queenOnBoard: false, queenCoverPending: true);
      final s = engine.resolve(pending, const StrikeOutcome());
      expect(s.queenOnBoard, true);
      expect(s.queenCoverPending, false);
      expect(s.currentPlayer, Player.two);
    });

    test('foul while cover pending returns the queen', () {
      final pending = start().copyWith(queenOnBoard: false, queenCoverPending: true);
      final s = engine.resolve(
        pending,
        const StrikeOutcome(strikerPocketed: true),
      );
      expect(s.queenOnBoard, true);
      expect(s.queenCoverPending, false);
      expect(s.currentPlayer, Player.two);
    });
  });

  group('win conditions', () {
    test('clearing last coin with queen already resolved wins', () {
      final nearWin = start().copyWith(whiteRemaining: 1, queenOnBoard: false);
      final s = engine.resolve(
        nearWin,
        const StrikeOutcome(pocketed: [CoinType.white]),
      );
      expect(s.winner, Player.one);
      expect(s.isGameOver, true);
    });

    test('clearing last coin while queen still on board is denied', () {
      final nearWin = start().copyWith(whiteRemaining: 1, queenOnBoard: true);
      final s = engine.resolve(
        nearWin,
        const StrikeOutcome(pocketed: [CoinType.white]),
      );
      expect(s.winner, isNull);
      expect(s.whiteRemaining, 1);
      expect(s.currentPlayer, Player.two);
    });

    test('queen + last coin same strike wins (covered immediately)', () {
      final nearWin = start().copyWith(whiteRemaining: 1, queenOnBoard: true);
      final s = engine.resolve(
        nearWin,
        const StrikeOutcome(pocketed: [CoinType.queen, CoinType.white]),
      );
      expect(s.winner, Player.one);
    });

    test('resolve on a finished match returns it unchanged', () {
      final finished = start().copyWith(winner: Player.one);
      final s = engine.resolve(
        finished,
        const StrikeOutcome(pocketed: [CoinType.black]),
      );
      expect(s, same(finished));
    });
  });

  group('end-to-end scenario', () {
    test('player one sweeps to a legal win', () {
      var s = MatchState.initial(); // p1 white, p2 black

      // P1 pockets 7 white across continued strikes.
      for (var i = 0; i < 7; i++) {
        s = engine.resolve(s, const StrikeOutcome(pocketed: [CoinType.white]));
        expect(s.currentPlayer, Player.one);
      }
      expect(s.whiteRemaining, 2);

      // P1 pockets the queen alone -> cover pending, still P1.
      s = engine.resolve(s, const StrikeOutcome(pocketed: [CoinType.queen]));
      expect(s.queenCoverPending, true);
      expect(s.currentPlayer, Player.one);

      // P1 covers with a white -> secured, 1 white left, still P1.
      s = engine.resolve(s, const StrikeOutcome(pocketed: [CoinType.white]));
      expect(s.queenCoverPending, false);
      expect(s.queenOnBoard, false);
      expect(s.whiteRemaining, 1);

      // P1 pockets the last white with the queen resolved -> win.
      s = engine.resolve(s, const StrikeOutcome(pocketed: [CoinType.white]));
      expect(s.winner, Player.one);
      expect(s.isGameOver, true);
    });

    test('miss then opponent takes over', () {
      var s = MatchState.initial();
      s = engine.resolve(s, const StrikeOutcome()); // p1 misses
      expect(s.currentPlayer, Player.two);
      s = engine.resolve(s, const StrikeOutcome(pocketed: [CoinType.black]));
      expect(s.currentPlayer, Player.two); // own coin -> continue
      expect(s.blackRemaining, 8);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:carrom_pro/game/rules/coin_type.dart';
import 'package:carrom_pro/game/rules/player.dart';
import 'package:carrom_pro/game/rules/match_state.dart';

void main() {
  test('initial state: player one to strike, 9+9 coins, queen on board', () {
    final s = MatchState.initial();
    expect(s.currentPlayer, Player.one);
    expect(s.playerOneColor, CoinType.white);
    expect(s.whiteRemaining, 9);
    expect(s.blackRemaining, 9);
    expect(s.queenOnBoard, true);
    expect(s.queenCoverPending, false);
    expect(s.winner, isNull);
    expect(s.isGameOver, false);
  });

  test('initial state can assign player one black', () {
    final s = MatchState.initial(playerOneColor: CoinType.black);
    expect(s.playerOneColor, CoinType.black);
    expect(s.colorOf(Player.one), CoinType.black);
    expect(s.colorOf(Player.two), CoinType.white);
  });

  test('remainingFor maps each player to their color count', () {
    final s = MatchState.initial().copyWith(whiteRemaining: 4, blackRemaining: 7);
    expect(s.remainingFor(Player.one), 4); // one = white
    expect(s.remainingFor(Player.two), 7); // two = black
  });

  test('copyWith overrides only the given fields', () {
    final s = MatchState.initial().copyWith(currentPlayer: Player.two);
    expect(s.currentPlayer, Player.two);
    expect(s.whiteRemaining, 9);
  });

  test('isGameOver becomes true when a winner is set', () {
    final s = MatchState.initial().copyWith(winner: Player.one);
    expect(s.isGameOver, true);
  });
}

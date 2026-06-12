import 'package:flutter_test/flutter_test.dart';
import 'package:carrom_pro/game/game_launch_args.dart';
import 'package:carrom_pro/game/match/match_session.dart';
import 'package:carrom_pro/game/match/player_kind.dart';
import 'package:carrom_pro/game/rules/coin_type.dart';
import 'package:carrom_pro/game/rules/player.dart';
import 'package:carrom_pro/game/rules/strike_outcome.dart';

void main() {
  test('two-player session: player one starts, owns white', () {
    final s = MatchSession(mode: GameMode.twoPlayer);
    expect(s.currentPlayer, Player.one);
    expect(s.colorOf(Player.one), CoinType.white);
    expect(s.kindOf(Player.one), PlayerKind.human);
    expect(s.kindOf(Player.two), PlayerKind.human);
    expect(s.isOver, false);
  });

  test('vsComputer: player two is the AI', () {
    final s = MatchSession(mode: GameMode.vsComputer);
    expect(s.kindOf(Player.one), PlayerKind.human);
    expect(s.kindOf(Player.two), PlayerKind.ai);
  });

  test('applyStrike resolves through the rules engine and notifies', () {
    final s = MatchSession(mode: GameMode.twoPlayer);
    var notified = 0;
    s.addListener(() => notified++);
    s.applyStrike(const StrikeOutcome(pocketed: [CoinType.white]));
    expect(s.currentPlayer, Player.one);
    expect(s.coinsRemainingFor(Player.one), 8);
    expect(notified, greaterThan(0));
  });

  test('missing passes the turn to player two', () {
    final s = MatchSession(mode: GameMode.twoPlayer);
    s.applyStrike(const StrikeOutcome());
    expect(s.currentPlayer, Player.two);
  });

  test('exposes queen status string', () {
    final s = MatchSession(mode: GameMode.twoPlayer);
    expect(s.queenStatus, QueenStatus.onBoard);
    s.applyStrike(const StrikeOutcome(pocketed: [CoinType.queen]));
    expect(s.queenStatus, QueenStatus.pendingCover);
  });

  test('turnIsAI is true only on the AI seat in vsComputer', () {
    final s = MatchSession(mode: GameMode.vsComputer);
    expect(s.turnIsAI, false);
    s.applyStrike(const StrikeOutcome());
    expect(s.turnIsAI, true);
  });

  test('isOver and winner reflect the underlying state initially', () {
    final s = MatchSession(mode: GameMode.twoPlayer);
    expect(s.isOver, false);
    expect(s.winner, isNull);
  });
}

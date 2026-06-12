import 'package:flutter_test/flutter_test.dart';
import 'package:carrom_pro/game/profile/player_profile.dart';

void main() {
  test('defaults are all zero/empty', () {
    const p = PlayerProfile();
    expect(p.coins, 0);
    expect(p.xp, 0);
    expect(p.wins, 0);
    expect(p.losses, 0);
    expect(p.bestStreak, 0);
    expect(p.currentStreak, 0);
    expect(p.history, isEmpty);
  });

  test('derived: gamesPlayed, level, efficiency', () {
    const p = PlayerProfile(xp: 250, wins: 3, losses: 1);
    expect(p.gamesPlayed, 4);
    expect(p.level, 3);
    expect(p.efficiency, closeTo(0.75, 1e-9));
  });

  test('efficiency is 0 with no games', () {
    expect(const PlayerProfile().efficiency, 0);
  });

  test('copyWith overrides only given fields', () {
    const p = PlayerProfile(coins: 50);
    expect(p.copyWith(coins: 80).coins, 80);
    expect(p.copyWith(xp: 10).coins, 50);
  });

  test('toJson/fromJson round-trips', () {
    const p = PlayerProfile(
      coins: 120, xp: 340, wins: 5, losses: 2,
      bestStreak: 3, currentStreak: 1, history: [10, 20, 30],
    );
    final back = PlayerProfile.fromJson(p.toJson());
    expect(back.coins, 120);
    expect(back.xp, 340);
    expect(back.wins, 5);
    expect(back.losses, 2);
    expect(back.bestStreak, 3);
    expect(back.currentStreak, 1);
    expect(back.history, [10, 20, 30]);
  });
}

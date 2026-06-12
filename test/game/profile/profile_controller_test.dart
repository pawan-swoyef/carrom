import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carrom_pro/services/storage_service.dart';
import 'package:carrom_pro/game/profile/profile_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<StorageService> fresh() async {
    SharedPreferences.setMockInitialValues({});
    return StorageService.create();
  }

  test('starts empty', () async {
    final c = ProfileController(await fresh());
    expect(c.profile.coins, 0);
    expect(c.profile.gamesPlayed, 0);
  });

  test('recordMatch win awards coins + xp, increments wins + streak', () async {
    final c = ProfileController(await fresh());
    await c.recordMatch(won: true, coinsPocketed: 9);
    expect(c.profile.wins, 1);
    expect(c.profile.currentStreak, 1);
    expect(c.profile.bestStreak, 1);
    expect(c.profile.coins, greaterThan(0));
    expect(c.profile.xp, greaterThan(0));
    expect(c.profile.history.length, 1);
  });

  test('a loss resets the current streak but keeps best', () async {
    final c = ProfileController(await fresh());
    await c.recordMatch(won: true, coinsPocketed: 5);
    await c.recordMatch(won: true, coinsPocketed: 5);
    expect(c.profile.bestStreak, 2);
    await c.recordMatch(won: false, coinsPocketed: 2);
    expect(c.profile.currentStreak, 0);
    expect(c.profile.bestStreak, 2);
    expect(c.profile.losses, 1);
  });

  test('persists across reloads', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.create();
    final c = ProfileController(storage);
    await c.recordMatch(won: true, coinsPocketed: 4);
    final coins = c.profile.coins;

    final reloaded = ProfileController(await StorageService.create());
    expect(reloaded.profile.coins, coins);
    expect(reloaded.profile.wins, 1);
  });

  test('spend fails when insufficient, succeeds otherwise', () async {
    final c = ProfileController(await fresh());
    await c.addCoins(50);
    expect(await c.spend(80), false);
    expect(c.profile.coins, 50);
    expect(await c.spend(30), true);
    expect(c.profile.coins, 20);
  });

  test('reset clears everything', () async {
    final c = ProfileController(await fresh());
    await c.recordMatch(won: true, coinsPocketed: 9);
    await c.reset();
    expect(c.profile.coins, 0);
    expect(c.profile.wins, 0);
  });
}

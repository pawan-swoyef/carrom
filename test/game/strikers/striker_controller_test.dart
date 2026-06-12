import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carrom_pro/services/storage_service.dart';
import 'package:carrom_pro/game/profile/profile_controller.dart';
import 'package:carrom_pro/game/strikers/striker_controller.dart';
import 'package:carrom_pro/game/strikers/striker_skin.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<(StorageService, ProfileController)> fresh() async {
    SharedPreferences.setMockInitialValues({});
    final s = await StorageService.create();
    return (s, ProfileController(s));
  }

  test('starts with only the classic striker equipped', () async {
    final (s, p) = await fresh();
    final c = StrikerController(s, p);
    expect(c.inventory.equipped, kDefaultStrikerId);
    expect(c.equippedSkin.id, kDefaultStrikerId);
  });

  test('buy fails without enough coins', () async {
    final (s, p) = await fresh();
    final c = StrikerController(s, p);
    expect(await c.buy(skinById('onyx')), false);
    expect(c.isOwned('onyx'), false);
  });

  test('buy succeeds, deducts coins, marks owned', () async {
    final (s, p) = await fresh();
    await p.addCoins(2000);
    final c = StrikerController(s, p);
    expect(await c.buy(skinById('onyx')), true);
    expect(c.isOwned('onyx'), true);
    expect(p.profile.coins, 800);
  });

  test('equip only works for owned skins', () async {
    final (s, p) = await fresh();
    final c = StrikerController(s, p);
    await c.equip('onyx');
    expect(c.inventory.equipped, kDefaultStrikerId);
  });

  test('persists owned + equipped across reloads', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.create();
    final profile = ProfileController(storage);
    await profile.addCoins(1000);
    final c = StrikerController(storage, profile);
    await c.buy(skinById('crimson'));
    await c.equip('crimson');

    final reloaded = StrikerController(
        await StorageService.create(), ProfileController(await StorageService.create()));
    expect(reloaded.isOwned('crimson'), true);
    expect(reloaded.inventory.equipped, 'crimson');
  });
}

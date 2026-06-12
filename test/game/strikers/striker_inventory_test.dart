import 'package:flutter_test/flutter_test.dart';
import 'package:carrom_pro/game/strikers/striker_inventory.dart';
import 'package:carrom_pro/game/strikers/striker_skin.dart';

void main() {
  test('defaults: only the classic striker, equipped', () {
    const inv = StrikerInventory();
    expect(inv.isOwned(kDefaultStrikerId), true);
    expect(inv.equipped, kDefaultStrikerId);
    expect(inv.isOwned('onyx'), false);
  });

  test('copyWith adds owned + changes equipped', () {
    const inv = StrikerInventory();
    final next = inv.copyWith(owned: {kDefaultStrikerId, 'onyx'}, equipped: 'onyx');
    expect(next.isOwned('onyx'), true);
    expect(next.equipped, 'onyx');
  });

  test('toJson/fromJson round-trips', () {
    const inv = StrikerInventory(owned: {kDefaultStrikerId, 'emerald'}, equipped: 'emerald');
    final back = StrikerInventory.fromJson(inv.toJson());
    expect(back.isOwned('emerald'), true);
    expect(back.equipped, 'emerald');
  });

  test('fromJson always includes the default striker', () {
    final back = StrikerInventory.fromJson({'owned': ['onyx'], 'equipped': 'onyx'});
    expect(back.isOwned(kDefaultStrikerId), true);
  });
}

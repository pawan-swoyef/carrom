import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carrom_pro/services/storage_service.dart';
import 'package:carrom_pro/settings/difficulty.dart';
import 'package:carrom_pro/settings/settings_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<StorageService> freshStorage() async {
    SharedPreferences.setMockInitialValues({});
    return StorageService.create();
  }

  test('defaults: sound on, music on, vibration on, medium difficulty',
      () async {
    final controller = SettingsController(await freshStorage());
    expect(controller.settings.soundEffects, true);
    expect(controller.settings.music, true);
    expect(controller.settings.vibration, true);
    expect(controller.settings.defaultDifficulty, Difficulty.medium);
  });

  test('setSoundEffects updates state and notifies', () async {
    final controller = SettingsController(await freshStorage());
    var notified = 0;
    controller.addListener(() => notified++);
    await controller.setSoundEffects(false);
    expect(controller.settings.soundEffects, false);
    expect(notified, greaterThan(0));
  });

  test('setDefaultDifficulty persists across reloads', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.create();
    final controller = SettingsController(storage);
    await controller.setDefaultDifficulty(Difficulty.hard);

    final reloaded = SettingsController(await StorageService.create());
    expect(reloaded.settings.defaultDifficulty, Difficulty.hard);
  });
}

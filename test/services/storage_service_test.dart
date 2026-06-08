import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carrom_pro/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<StorageService> freshStorage() async {
    SharedPreferences.setMockInitialValues({});
    return StorageService.create();
  }

  test('getBool returns default when key missing', () async {
    final storage = await freshStorage();
    expect(storage.getBool('missing', defaultValue: true), true);
  });

  test('setBool then getBool round-trips', () async {
    final storage = await freshStorage();
    await storage.setBool('sound', false);
    expect(storage.getBool('sound', defaultValue: true), false);
  });

  test('getInt returns default when key missing', () async {
    final storage = await freshStorage();
    expect(storage.getInt('coins', defaultValue: 100), 100);
  });

  test('setInt then getInt round-trips', () async {
    final storage = await freshStorage();
    await storage.setInt('coins', 250);
    expect(storage.getInt('coins'), 250);
  });

  test('setString then getString round-trips', () async {
    final storage = await freshStorage();
    await storage.setString('name', 'Alex Pro');
    expect(storage.getString('name'), 'Alex Pro');
  });

  test('setJson then getJson round-trips a map', () async {
    final storage = await freshStorage();
    await storage.setJson('inv', {'owned': ['a', 'b'], 'equipped': 'a'});
    final read = storage.getJson('inv');
    expect(read?['equipped'], 'a');
    expect((read?['owned'] as List).length, 2);
  });

  test('getJson returns null when key missing', () async {
    final storage = await freshStorage();
    expect(storage.getJson('nope'), isNull);
  });

  test('getJson returns null on corrupted (non-object) data', () async {
    final storage = await freshStorage();
    await storage.setString('inv', 'not json at all');
    expect(storage.getJson('inv'), isNull);
  });
}

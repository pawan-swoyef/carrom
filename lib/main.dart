import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/storage_service.dart';
import 'settings/settings_controller.dart';
import 'game/profile/profile_controller.dart';
import 'game/strikers/striker_controller.dart';
import 'services/ad_service.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Fire-and-forget; init is internally crash-safe and never awaited so it
  // cannot block or break startup.
  AdService.instance.init();
  final storage = await StorageService.create();
  final settings = SettingsController(storage);
  final profile = ProfileController(storage);
  final strikers = StrikerController(storage, profile);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: profile),
        ChangeNotifierProvider.value(value: strikers),
      ],
      child: const CarromProApp(),
    ),
  );
}

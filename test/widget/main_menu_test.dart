import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carrom_pro/services/storage_service.dart';
import 'package:carrom_pro/settings/settings_controller.dart';
import 'package:carrom_pro/game/profile/profile_controller.dart';
import 'package:carrom_pro/screens/main_menu_screen.dart';
import 'package:carrom_pro/navigation/home_shell.dart';

Future<Widget> _menuApp() async {
  SharedPreferences.setMockInitialValues({});
  final storage = await StorageService.create();
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => SettingsController(storage)),
      ChangeNotifierProvider(create: (_) => ProfileController(storage)),
    ],
    child: const MaterialApp(home: MainMenuScreen()),
  );
}

/// The menu is a portrait phone layout; size the test surface to match so the
/// vertical content does not overflow the default 800x600 test window.
void _portrait(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('main menu shows title and PLAY', (tester) async {
    _portrait(tester);
    await tester.pumpWidget(await _menuApp());
    expect(find.text('CARROM PRO'), findsOneWidget);
    expect(find.text('PLAY'), findsOneWidget);
  });

  testWidgets('tapping PLAY navigates to HomeShell', (tester) async {
    _portrait(tester);
    await tester.pumpWidget(await _menuApp());
    await tester.tap(find.text('PLAY'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeShell), findsOneWidget);
    expect(find.text('Shop'), findsOneWidget); // bottom-nav label
  });

  testWidgets('sound toggle flips icon', (tester) async {
    _portrait(tester);
    await tester.pumpWidget(await _menuApp());
    expect(find.byIcon(Icons.volume_up), findsOneWidget);
    await tester.tap(find.byIcon(Icons.volume_up));
    await tester.pump();
    expect(find.byIcon(Icons.volume_off), findsOneWidget);
  });
}

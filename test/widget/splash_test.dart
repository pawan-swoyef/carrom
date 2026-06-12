import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carrom_pro/services/storage_service.dart';
import 'package:carrom_pro/settings/settings_controller.dart';
import 'package:carrom_pro/game/profile/profile_controller.dart';
import 'package:carrom_pro/screens/splash_screen.dart';
import 'package:carrom_pro/screens/main_menu_screen.dart';

Future<Widget> _splashApp() async {
  SharedPreferences.setMockInitialValues({});
  final storage = await StorageService.create();
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => SettingsController(storage)),
      ChangeNotifierProvider(create: (_) => ProfileController(storage)),
    ],
    child: const MaterialApp(home: SplashScreen()),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('splash shows title then auto-advances to main menu',
      (tester) async {
    await tester.pumpWidget(await _splashApp());
    await tester.pump(); // start the fade-in

    // Initially on the splash, not yet on the menu.
    expect(find.text('CARROM PRO'), findsOneWidget);
    expect(find.byType(MainMenuScreen), findsNothing);

    // After the splash delay it replaces itself with the main menu.
    // (Avoid pumpAndSettle: the loader arc animates forever on the splash.)
    await tester.pump(const Duration(milliseconds: 2100));
    await tester.pump();
    expect(find.byType(MainMenuScreen), findsOneWidget);
  });
}

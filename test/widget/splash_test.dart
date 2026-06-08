import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carrom_pro/services/storage_service.dart';
import 'package:carrom_pro/settings/settings_controller.dart';
import 'package:carrom_pro/screens/splash_screen.dart';
import 'package:carrom_pro/screens/main_menu_screen.dart';

Future<Widget> _splashApp() async {
  SharedPreferences.setMockInitialValues({});
  final storage = await StorageService.create();
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => SettingsController(storage)),
    ],
    child: const MaterialApp(home: SplashScreen()),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('splash shows title then auto-advances to main menu',
      (tester) async {
    await tester.pumpWidget(await _splashApp());

    // Initially on the splash, not yet on the menu.
    expect(find.text('Carrom Pro'), findsOneWidget);
    expect(find.byType(MainMenuScreen), findsNothing);

    // After the splash delay it replaces itself with the main menu.
    await tester.pump(const Duration(milliseconds: 1900));
    await tester.pumpAndSettle();
    expect(find.byType(MainMenuScreen), findsOneWidget);
  });
}

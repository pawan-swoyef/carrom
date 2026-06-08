import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carrom_pro/services/storage_service.dart';
import 'package:carrom_pro/settings/settings_controller.dart';
import 'package:carrom_pro/navigation/home_shell.dart';
import 'package:carrom_pro/navigation/app_routes.dart';
import 'package:carrom_pro/game/ui/game_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Practice button pushes the game route', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.create();
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsController(storage)),
      ],
      child: MaterialApp(
        onGenerateRoute: AppRoutes.onGenerateRoute,
        home: const HomeShell(initialIndex: 0),
      ),
    ));

    await tester.tap(find.text('Practice'));
    // Use timed pumps instead of pumpAndSettle: GameWidget runs a continuous
    // game loop that never idles, so pumpAndSettle would time out.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300)); // route animation
    expect(find.byType(GameScreen), findsOneWidget);
  });
}

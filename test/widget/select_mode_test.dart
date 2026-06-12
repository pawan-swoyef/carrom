import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carrom_pro/services/storage_service.dart';
import 'package:carrom_pro/settings/settings_controller.dart';
import 'package:carrom_pro/game/profile/profile_controller.dart';
import 'package:carrom_pro/game/strikers/striker_controller.dart';
import 'package:carrom_pro/navigation/home_shell.dart';
import 'package:carrom_pro/navigation/app_routes.dart';
import 'package:carrom_pro/game/ui/game_screen.dart';
import 'package:carrom_pro/game/ui/choose_difficulty_screen.dart';

Future<Widget> _app() async {
  SharedPreferences.setMockInitialValues({});
  final storage = await StorageService.create();
  final profile = ProfileController(storage);
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: SettingsController(storage)),
      ChangeNotifierProvider.value(value: profile),
      ChangeNotifierProvider.value(value: StrikerController(storage, profile)),
    ],
    child: MaterialApp(
      onGenerateRoute: AppRoutes.onGenerateRoute,
      home: const HomeShell(initialIndex: 0),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Select Mode shows the three modes', (tester) async {
    await tester.pumpWidget(await _app());
    expect(find.text('vs Computer'), findsOneWidget);
    expect(find.text('2 Players'), findsOneWidget);
    expect(find.text('Practice'), findsOneWidget);
  });

  testWidgets('2 Players launches the game', (tester) async {
    await tester.pumpWidget(await _app());
    await tester.tap(find.text('2 Players'));
    await tester.pump();
    await tester.pump();
    expect(find.byType(GameScreen), findsOneWidget);
  });

  testWidgets('vs Computer opens Choose Difficulty', (tester) async {
    await tester.pumpWidget(await _app());
    await tester.tap(find.text('vs Computer'));
    await tester.pumpAndSettle();
    expect(find.byType(ChooseDifficultyScreen), findsOneWidget);
    expect(find.text('Start Game  ▷'), findsOneWidget);
  });
}

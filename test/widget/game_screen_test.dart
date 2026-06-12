import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carrom_pro/services/storage_service.dart';
import 'package:carrom_pro/settings/settings_controller.dart';
import 'package:carrom_pro/game/profile/profile_controller.dart';
import 'package:carrom_pro/game/game_launch_args.dart';
import 'package:carrom_pro/game/ui/game_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<Widget> app() async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.create();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsController(storage)),
        ChangeNotifierProvider(create: (_) => ProfileController(storage)),
      ],
      child: const MaterialApp(
        home: GameScreen(args: GameLaunchArgs(mode: GameMode.practice)),
      ),
    );
  }

  testWidgets('GameScreen mounts with the pull-back controls legend',
      (tester) async {
    await tester.pumpWidget(await app());
    // Two pumps to trigger build; never pumpAndSettle (game loop runs forever).
    await tester.pump();
    await tester.pump();

    expect(find.byType(GameScreen), findsOneWidget);

    // Controls legend present (the locked pull-back control model).
    expect(find.text('PULL BACK'), findsOneWidget);
    expect(find.text('AIM DRAG'), findsOneWidget);

    // The old STRIKE button is gone.
    expect(find.text('STRIKE'), findsNothing);

    // STRIKE POWER meter label is present.
    expect(find.text('STRIKE POWER'), findsOneWidget);
  });

  testWidgets('Reset button is present and tappable', (tester) async {
    await tester.pumpWidget(await app());
    await tester.pump();
    await tester.pump();

    expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Icons.refresh_rounded));
    await tester.pump();
  });
}

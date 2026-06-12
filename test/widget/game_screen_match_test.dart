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

  Future<Widget> app(GameMode mode) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.create();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsController(storage)),
        ChangeNotifierProvider(create: (_) => ProfileController(storage)),
      ],
      child: MaterialApp(home: GameScreen(args: GameLaunchArgs(mode: mode))),
    );
  }

  testWidgets('two-player match shows both player panels and queen pill',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(await app(GameMode.twoPlayer));
    await tester.pump();
    await tester.pump();

    expect(find.text('Player 1'), findsOneWidget);
    expect(find.text('Player 2'), findsOneWidget);
    expect(find.text('ON BOARD'), findsOneWidget);
  });

  testWidgets('vsComputer shows the Computer panel', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(await app(GameMode.vsComputer));
    await tester.pump();
    await tester.pump();

    expect(find.text('Computer'), findsOneWidget);
    expect(find.text('Player 1'), findsOneWidget);

    // Flush the AI "thinking" timer so no pending timer trips the test.
    await tester.pump(const Duration(seconds: 1));
  });
}

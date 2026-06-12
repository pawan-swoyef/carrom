import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:carrom_pro/game/game_launch_args.dart';
import 'package:carrom_pro/game/ui/game_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('two-player match shows both player panels and queen pill',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: GameScreen(args: GameLaunchArgs(mode: GameMode.twoPlayer)),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Player 1'), findsOneWidget);
    expect(find.text('Player 2'), findsOneWidget);
    expect(find.text('ON BOARD'), findsOneWidget);
  });
}

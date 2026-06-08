import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:carrom_pro/game/game_launch_args.dart';
import 'package:carrom_pro/game/ui/game_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('GameScreen mounts and STRIKE control is present', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GameScreen(
          args: GameLaunchArgs(mode: GameMode.practice),
        ),
      ),
    );

    // One pump to trigger widget build; don't use pumpAndSettle (game loop).
    await tester.pump();
    await tester.pump();

    // The screen itself should be present.
    expect(find.byType(GameScreen), findsOneWidget);

    // The STRIKE button must be visible.
    expect(find.text('STRIKE'), findsOneWidget);
  });

  testWidgets('Reset button calls resetBoard without crashing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GameScreen(
          args: GameLaunchArgs(mode: GameMode.practice),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    // Tap the reset button — should not throw.
    await tester.tap(find.text('Reset'));
    await tester.pump();
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:carrom_pro/game/game_launch_args.dart';
import 'package:carrom_pro/game/ui/game_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('GameScreen mounts without exception', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GameScreen(
          args: GameLaunchArgs(mode: GameMode.practice),
        ),
      ),
    );

    // Two pumps to trigger build; never use pumpAndSettle (game loop runs forever).
    await tester.pump();
    await tester.pump();

    // The screen itself must be present.
    expect(find.byType(GameScreen), findsOneWidget);

    // Old STRIKE button must be gone.
    expect(find.text('STRIKE'), findsNothing);

    // Drag hint is present.
    expect(find.text('Drag the striker to aim'), findsOneWidget);
  });

  testWidgets('Reset button is present and tappable', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GameScreen(
          args: GameLaunchArgs(mode: GameMode.practice),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    // Reset button must exist.
    expect(find.text('Reset'), findsOneWidget);

    // Tapping it must not throw.
    await tester.tap(find.text('Reset'));
    await tester.pump();
  });
}

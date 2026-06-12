import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carrom_pro/services/storage_service.dart';
import 'package:carrom_pro/game/profile/profile_controller.dart';
import 'package:carrom_pro/screens/tabs/profile_tab.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('profile tab shows wins and rank', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.create();
    final profile = ProfileController(storage);
    await profile.recordMatch(won: true, coinsPocketed: 6);

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider.value(
          value: profile,
          child: const Scaffold(body: ProfileTab()),
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('Wins'), findsOneWidget);
    expect(find.textContaining('Rank'), findsWidgets);
  });
}

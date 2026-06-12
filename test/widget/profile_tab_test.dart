import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carrom_pro/services/storage_service.dart';
import 'package:carrom_pro/game/profile/profile_controller.dart';
import 'package:carrom_pro/screens/tabs/profile_tab.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('records screen shows stats and rank name', (tester) async {
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.create();
    final profile = ProfileController(storage);
    await profile.recordMatch(won: true, coinsPocketed: 6);

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider.value(
        value: profile,
        child: const Scaffold(body: ProfileTab()),
      ),
    ));
    await tester.pump();

    expect(find.text('YOUR RECORDS'), findsOneWidget);
    expect(find.text('WINS'), findsOneWidget);
    // Rank name (default 'Rookie' at low xp), shown uppercase.
    expect(find.text('ROOKIE'), findsOneWidget);
  });
}

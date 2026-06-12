import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carrom_pro/services/storage_service.dart';
import 'package:carrom_pro/game/profile/profile_controller.dart';
import 'package:carrom_pro/game/strikers/striker_controller.dart';
import 'package:carrom_pro/screens/tabs/strikers_tab.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('strikers tab shows the equipped default and an EQUIPPED state',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.create();
    final profile = ProfileController(storage);
    final strikers = StrikerController(storage, profile);

    await tester.pumpWidget(MaterialApp(
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: profile),
          ChangeNotifierProvider.value(value: strikers),
        ],
        child: const Scaffold(body: StrikersTab()),
      ),
    ));
    await tester.pump();

    // The default 'Classic' striker is owned + equipped.
    expect(find.text('Classic'), findsOneWidget);
    expect(find.text('EQUIPPED'), findsWidgets);
  });
}

# Carrom Pro — Phase 1: Foundation — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stand up the Carrom Pro Flutter project with a themed, navigable app shell (splash → main menu → bottom-nav tabs) backed by tested storage and settings services.

**Architecture:** A single Flutter app. Pure-Dart, unit-tested services (`StorageService`, `SettingsController`) sit below the UI. State is provided with the `provider` package. Navigation uses plain Flutter `Navigator` plus a `HomeShell` widget that hosts the Play/Shop/Strikers/Profile bottom nav (tabs are placeholders this phase; real screens arrive in later phases).

**Tech Stack:** Flutter 3.41, Dart 3.11, `shared_preferences`, `provider`. (Flame/Forge2D, audio, and ads are added in later phases.)

---

## File Structure (created this phase)

```
lib/
  main.dart                       app entry; init storage + providers
  app.dart                        CarromProApp (MaterialApp, theme, home)
  theme/
    app_colors.dart               palette constants
    app_theme.dart                ThemeData
  services/
    storage_service.dart          shared_preferences wrapper (bool/int/string/json)
  settings/
    difficulty.dart               Difficulty enum
    settings.dart                 immutable Settings model
    settings_controller.dart      ChangeNotifier, loads/persists settings
  navigation/
    home_shell.dart               bottom-nav scaffold (4 tabs)
  screens/
    splash_screen.dart            title + spinner, auto-advances
    main_menu_screen.dart         Play + How to Play/Stats/Settings + sound toggle
    tabs/
      play_tab.dart               placeholder (Select Mode arrives Phase 2)
      shop_tab.dart               placeholder (Phase 4)
      strikers_tab.dart           placeholder (Phase 4)
      profile_tab.dart            placeholder (Phase 3)
test/
  services/storage_service_test.dart
  settings/settings_controller_test.dart
  widget/main_menu_test.dart
```

---

## Task 0: Project scaffold, git, dependencies

**Files:**
- Create: whole Flutter project in `c:\Users\acer\Desktop\dashain\caram`
- Modify: `pubspec.yaml`

- [ ] **Step 1: Scaffold the Flutter project into the existing folder**

The folder already contains `docs/`. `flutter create` adds project files alongside it without deleting `docs/`.

Run:
```bash
flutter create --org com.sirenai --project-name carrom_pro --platforms android,ios .
```
Expected: "All done!" and a `lib/`, `pubspec.yaml`, `android/`, `ios/` appear.

- [ ] **Step 2: Initialize git and make the first commit**

Run:
```bash
git init
git add -A
git commit -m "chore: scaffold carrom_pro flutter project"
```
Expected: a commit is created (the spec in `docs/` is included).

- [ ] **Step 3: Add runtime dependencies**

Run:
```bash
flutter pub add shared_preferences provider
```
Expected: `pubspec.yaml` gains `shared_preferences` and `provider`; `pub get` succeeds.

- [ ] **Step 4: Verify the fresh project compiles and tests run**

Run:
```bash
flutter test
```
Expected: the default `widget_test.dart` may FAIL because it references the default counter app. Delete it so the suite is clean:
```bash
git rm test/widget_test.dart
```
Then re-run `flutter test` — Expected: "No tests ran" or all pass.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "chore: add shared_preferences and provider, remove default test"
```

---

## Task 1: Theme (colors + ThemeData)

**Files:**
- Create: `lib/theme/app_colors.dart`
- Create: `lib/theme/app_theme.dart`

- [ ] **Step 1: Create the color palette**

`lib/theme/app_colors.dart`:
```dart
import 'package:flutter/material.dart';

/// Palette locked from the approved Carrom Pro mockups.
class AppColors {
  AppColors._();

  static const Color woodDark = Color(0xFF161210);
  static const Color woodGrain = Color(0xFF241B14);
  static const Color surface = Color(0xFF2A2622);

  static const Color gold = Color(0xFFE6C068);
  static const Color goldBright = Color(0xFFF2D27E);

  static const Color crimson = Color(0xFFB03048);
  static const Color crimsonDark = Color(0xFF7A1F30);

  static const Color felt = Color(0xFF2E6E50);
  static const Color pinkHeading = Color(0xFFF4A9B8);

  static const Color textLight = Color(0xFFEDE6DD);
  static const Color textMuted = Color(0xFF9A8F86);
}
```

- [ ] **Step 2: Create the ThemeData**

`lib/theme/app_theme.dart`:
```dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.woodDark,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.crimson,
        secondary: AppColors.gold,
        surface: AppColors.surface,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textLight,
        displayColor: AppColors.gold,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.woodGrain,
        selectedItemColor: AppColors.crimson,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
```

- [ ] **Step 3: Verify it compiles**

Run:
```bash
flutter analyze lib/theme
```
Expected: "No issues found!"

- [ ] **Step 4: Commit**

```bash
git add lib/theme
git commit -m "feat: add app color palette and theme"
```

---

## Task 2: StorageService (TDD)

**Files:**
- Create: `lib/services/storage_service.dart`
- Test: `test/services/storage_service_test.dart`

- [ ] **Step 1: Write the failing test**

`test/services/storage_service_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carrom_pro/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<StorageService> freshStorage() async {
    SharedPreferences.setMockInitialValues({});
    return StorageService.create();
  }

  test('getBool returns default when key missing', () async {
    final storage = await freshStorage();
    expect(storage.getBool('missing', defaultValue: true), true);
  });

  test('setBool then getBool round-trips', () async {
    final storage = await freshStorage();
    await storage.setBool('sound', false);
    expect(storage.getBool('sound', defaultValue: true), false);
  });

  test('getInt returns default when key missing', () async {
    final storage = await freshStorage();
    expect(storage.getInt('coins', defaultValue: 100), 100);
  });

  test('setJson then getJson round-trips a map', () async {
    final storage = await freshStorage();
    await storage.setJson('inv', {'owned': ['a', 'b'], 'equipped': 'a'});
    final read = storage.getJson('inv');
    expect(read?['equipped'], 'a');
    expect((read?['owned'] as List).length, 2);
  });

  test('getJson returns null when key missing', () async {
    final storage = await freshStorage();
    expect(storage.getJson('nope'), isNull);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run:
```bash
flutter test test/services/storage_service_test.dart
```
Expected: FAIL — `Target of URI doesn't exist: 'package:carrom_pro/services/storage_service.dart'`.

- [ ] **Step 3: Write the minimal implementation**

`lib/services/storage_service.dart`:
```dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Thin typed wrapper over shared_preferences. Scalar getters take a
/// defaultValue; JSON helpers store maps as encoded strings.
class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  bool getBool(String key, {bool defaultValue = false}) =>
      _prefs.getBool(key) ?? defaultValue;

  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);

  int getInt(String key, {int defaultValue = 0}) =>
      _prefs.getInt(key) ?? defaultValue;

  Future<void> setInt(String key, int value) => _prefs.setInt(key, value);

  String? getString(String key) => _prefs.getString(key);

  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);

  Map<String, dynamic>? getJson(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> setJson(String key, Map<String, dynamic> value) =>
      _prefs.setString(key, jsonEncode(value));
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run:
```bash
flutter test test/services/storage_service_test.dart
```
Expected: All 5 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/services/storage_service.dart test/services/storage_service_test.dart
git commit -m "feat: add tested StorageService wrapper"
```

---

## Task 3: Settings model + SettingsController (TDD)

**Files:**
- Create: `lib/settings/difficulty.dart`
- Create: `lib/settings/settings.dart`
- Create: `lib/settings/settings_controller.dart`
- Test: `test/settings/settings_controller_test.dart`

- [ ] **Step 1: Create the Difficulty enum and Settings model**

`lib/settings/difficulty.dart`:
```dart
enum Difficulty { easy, medium, hard }
```

`lib/settings/settings.dart`:
```dart
import 'difficulty.dart';

class Settings {
  final bool soundEffects;
  final bool music;
  final bool vibration;
  final Difficulty defaultDifficulty;

  const Settings({
    this.soundEffects = true,
    this.music = true,
    this.vibration = true,
    this.defaultDifficulty = Difficulty.medium,
  });

  Settings copyWith({
    bool? soundEffects,
    bool? music,
    bool? vibration,
    Difficulty? defaultDifficulty,
  }) {
    return Settings(
      soundEffects: soundEffects ?? this.soundEffects,
      music: music ?? this.music,
      vibration: vibration ?? this.vibration,
      defaultDifficulty: defaultDifficulty ?? this.defaultDifficulty,
    );
  }
}
```

- [ ] **Step 2: Write the failing test**

`test/settings/settings_controller_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carrom_pro/services/storage_service.dart';
import 'package:carrom_pro/settings/difficulty.dart';
import 'package:carrom_pro/settings/settings_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<StorageService> freshStorage() async {
    SharedPreferences.setMockInitialValues({});
    return StorageService.create();
  }

  test('defaults: sound on, music on, vibration on, medium difficulty',
      () async {
    final controller = SettingsController(await freshStorage());
    expect(controller.settings.soundEffects, true);
    expect(controller.settings.music, true);
    expect(controller.settings.vibration, true);
    expect(controller.settings.defaultDifficulty, Difficulty.medium);
  });

  test('setSoundEffects updates state and notifies', () async {
    final controller = SettingsController(await freshStorage());
    var notified = 0;
    controller.addListener(() => notified++);
    await controller.setSoundEffects(false);
    expect(controller.settings.soundEffects, false);
    expect(notified, greaterThan(0));
  });

  test('setDefaultDifficulty persists across reloads', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.create();
    final controller = SettingsController(storage);
    await controller.setDefaultDifficulty(Difficulty.hard);

    final reloaded = SettingsController(await StorageService.create());
    expect(reloaded.settings.defaultDifficulty, Difficulty.hard);
  });
}
```

- [ ] **Step 3: Run the test to verify it fails**

Run:
```bash
flutter test test/settings/settings_controller_test.dart
```
Expected: FAIL — `Target of URI doesn't exist: '.../settings_controller.dart'`.

- [ ] **Step 4: Write the minimal implementation**

`lib/settings/settings_controller.dart`:
```dart
import 'package:flutter/foundation.dart';
import '../services/storage_service.dart';
import 'difficulty.dart';
import 'settings.dart';

class SettingsController extends ChangeNotifier {
  static const _kSound = 'settings.soundEffects';
  static const _kMusic = 'settings.music';
  static const _kVibration = 'settings.vibration';
  static const _kDifficulty = 'settings.defaultDifficulty';

  final StorageService _storage;
  Settings _settings = const Settings();

  SettingsController(this._storage) {
    _load();
  }

  Settings get settings => _settings;

  void _load() {
    _settings = Settings(
      soundEffects: _storage.getBool(_kSound, defaultValue: true),
      music: _storage.getBool(_kMusic, defaultValue: true),
      vibration: _storage.getBool(_kVibration, defaultValue: true),
      defaultDifficulty: Difficulty.values[_storage.getInt(
        _kDifficulty,
        defaultValue: Difficulty.medium.index,
      )],
    );
    notifyListeners();
  }

  Future<void> setSoundEffects(bool value) async {
    _settings = _settings.copyWith(soundEffects: value);
    await _storage.setBool(_kSound, value);
    notifyListeners();
  }

  Future<void> setMusic(bool value) async {
    _settings = _settings.copyWith(music: value);
    await _storage.setBool(_kMusic, value);
    notifyListeners();
  }

  Future<void> setVibration(bool value) async {
    _settings = _settings.copyWith(vibration: value);
    await _storage.setBool(_kVibration, value);
    notifyListeners();
  }

  Future<void> setDefaultDifficulty(Difficulty value) async {
    _settings = _settings.copyWith(defaultDifficulty: value);
    await _storage.setInt(_kDifficulty, value.index);
    notifyListeners();
  }
}
```

- [ ] **Step 5: Run the test to verify it passes**

Run:
```bash
flutter test test/settings/settings_controller_test.dart
```
Expected: All 3 tests PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/settings test/settings
git commit -m "feat: add Settings model and tested SettingsController"
```

---

## Task 4: HomeShell (bottom-nav scaffold) + placeholder tabs

**Files:**
- Create: `lib/screens/tabs/play_tab.dart`
- Create: `lib/screens/tabs/shop_tab.dart`
- Create: `lib/screens/tabs/strikers_tab.dart`
- Create: `lib/screens/tabs/profile_tab.dart`
- Create: `lib/navigation/home_shell.dart`

- [ ] **Step 1: Create the four placeholder tab widgets**

`lib/screens/tabs/play_tab.dart`:
```dart
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class PlayTab extends StatelessWidget {
  const PlayTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Select Mode\n(coming in Phase 2)',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.textMuted, fontSize: 18),
      ),
    );
  }
}
```

`lib/screens/tabs/shop_tab.dart`:
```dart
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class ShopTab extends StatelessWidget {
  const ShopTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Shop\n(coming in Phase 4)',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.textMuted, fontSize: 18),
      ),
    );
  }
}
```

`lib/screens/tabs/strikers_tab.dart`:
```dart
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class StrikersTab extends StatelessWidget {
  const StrikersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Strikers\n(coming in Phase 4)',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.textMuted, fontSize: 18),
      ),
    );
  }
}
```

`lib/screens/tabs/profile_tab.dart`:
```dart
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Profile\n(coming in Phase 3)',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.textMuted, fontSize: 18),
      ),
    );
  }
}
```

- [ ] **Step 2: Create the HomeShell**

`lib/navigation/home_shell.dart`:
```dart
import 'package:flutter/material.dart';
import '../screens/tabs/play_tab.dart';
import '../screens/tabs/shop_tab.dart';
import '../screens/tabs/strikers_tab.dart';
import '../screens/tabs/profile_tab.dart';

class HomeShell extends StatefulWidget {
  /// Index of the tab to open on first build (0 = Play).
  final int initialIndex;

  const HomeShell({super.key, this.initialIndex = 0});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _index = widget.initialIndex;

  static const _tabs = [PlayTab(), ShopTab(), StrikersTab(), ProfileTab()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.sports_esports), label: 'Play'),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag), label: 'Shop'),
          BottomNavigationBarItem(
              icon: Icon(Icons.adjust), label: 'Strikers'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Verify it compiles**

Run:
```bash
flutter analyze lib/navigation lib/screens/tabs
```
Expected: "No issues found!"

- [ ] **Step 4: Commit**

```bash
git add lib/navigation lib/screens/tabs
git commit -m "feat: add HomeShell bottom-nav scaffold with placeholder tabs"
```

---

## Task 5: Splash screen

**Files:**
- Create: `lib/screens/splash_screen.dart`

- [ ] **Step 1: Create the splash screen**

`lib/screens/splash_screen.dart`:
```dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'main_menu_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainMenuScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              'Carrom Pro',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: AppColors.gold,
              ),
            ),
            SizedBox(height: 28),
            CircularProgressIndicator(color: AppColors.gold),
            SizedBox(height: 60),
            Text('v1.0.0', style: TextStyle(color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify it compiles**

It imports `main_menu_screen.dart`, created in Task 6. This step will fail to analyze until Task 6 exists. Proceed to Task 6, then run analyze there. (No commit yet — committed together with Task 6.)

---

## Task 6: Main menu screen

**Files:**
- Create: `lib/screens/main_menu_screen.dart`

- [ ] **Step 1: Create the main menu screen**

`lib/screens/main_menu_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../settings/settings_controller.dart';
import '../navigation/home_shell.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  void _openPlay(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const HomeShell(initialIndex: 0)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  iconSize: 30,
                  color: AppColors.gold,
                  icon: Icon(settings.settings.soundEffects
                      ? Icons.volume_up
                      : Icons.volume_off),
                  onPressed: () => settings
                      .setSoundEffects(!settings.settings.soundEffects),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Carrom Pro',
                style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'THE PROFESSIONAL CIRCUIT',
                style: TextStyle(
                  color: AppColors.textMuted,
                  letterSpacing: 3,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _openPlay(context),
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    color: AppColors.crimson,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.gold, width: 4),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_arrow,
                          size: 64, color: AppColors.pinkHeading),
                      Text(
                        'PLAY',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.pinkHeading,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  _MenuChip(icon: Icons.menu_book, label: 'How to Play'),
                  _MenuChip(icon: Icons.bar_chart, label: 'Stats'),
                  _MenuChip(icon: Icons.settings, label: 'Settings'),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MenuChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 84,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.crimsonDark),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.gold),
          const SizedBox(height: 8),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textLight, fontSize: 12)),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Verify splash + menu compile together**

Run:
```bash
flutter analyze lib/screens
```
Expected: "No issues found!"

- [ ] **Step 3: Commit splash + menu**

```bash
git add lib/screens/splash_screen.dart lib/screens/main_menu_screen.dart
git commit -m "feat: add splash and main menu screens"
```

---

## Task 7: Wire app entry + widget smoke test

**Files:**
- Create: `lib/app.dart`
- Modify: `lib/main.dart` (replace generated content)
- Test: `test/widget/main_menu_test.dart`

- [ ] **Step 1: Create the app widget**

`lib/app.dart`:
```dart
import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

class CarromProApp extends StatelessWidget {
  const CarromProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Carrom Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const SplashScreen(),
    );
  }
}
```

- [ ] **Step 2: Replace `lib/main.dart`**

Overwrite `lib/main.dart` entirely with:
```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/storage_service.dart';
import 'settings/settings_controller.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await StorageService.create();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsController(storage)),
      ],
      child: const CarromProApp(),
    ),
  );
}
```

- [ ] **Step 3: Write the failing widget test**

`test/widget/main_menu_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carrom_pro/services/storage_service.dart';
import 'package:carrom_pro/settings/settings_controller.dart';
import 'package:carrom_pro/screens/main_menu_screen.dart';
import 'package:carrom_pro/navigation/home_shell.dart';

Future<Widget> _menuApp() async {
  SharedPreferences.setMockInitialValues({});
  final storage = await StorageService.create();
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => SettingsController(storage)),
    ],
    child: const MaterialApp(home: MainMenuScreen()),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('main menu shows title and PLAY', (tester) async {
    await tester.pumpWidget(await _menuApp());
    expect(find.text('Carrom Pro'), findsOneWidget);
    expect(find.text('PLAY'), findsOneWidget);
  });

  testWidgets('tapping PLAY navigates to HomeShell', (tester) async {
    await tester.pumpWidget(await _menuApp());
    await tester.tap(find.text('PLAY'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeShell), findsOneWidget);
    expect(find.text('Shop'), findsOneWidget); // bottom-nav label
  });

  testWidgets('sound toggle flips icon', (tester) async {
    await tester.pumpWidget(await _menuApp());
    expect(find.byIcon(Icons.volume_up), findsOneWidget);
    await tester.tap(find.byIcon(Icons.volume_up));
    await tester.pump();
    expect(find.byIcon(Icons.volume_off), findsOneWidget);
  });
}
```

- [ ] **Step 4: Run the widget test**

Run:
```bash
flutter test test/widget/main_menu_test.dart
```
Expected: All 3 tests PASS. (If `find.text('Carrom Pro')` matches more than one widget anywhere, scope is fine here since only the menu is pumped.)

- [ ] **Step 5: Run the full suite + analyze**

Run:
```bash
flutter analyze
flutter test
```
Expected: "No issues found!" and all tests across storage, settings, and widget suites PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/main.dart lib/app.dart test/widget/main_menu_test.dart
git commit -m "feat: wire app entry with providers and add main menu widget tests"
```

---

## Phase 1 Done — Definition of Done

- `flutter run` launches: splash (gold "Carrom Pro" + spinner) → main menu after ~1.8s.
- Main menu shows the crimson/gold PLAY circle, three menu chips, and a working sound toggle that persists.
- Tapping PLAY opens the HomeShell with a Play/Shop/Strikers/Profile bottom nav; tabs switch and show placeholders.
- `flutter test` is green; `flutter analyze` is clean.
- Next: **Phase 2 — Core game** (physics board, rules engine, hybrid controls, modes, AI).

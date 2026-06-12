# Carrom Pro — Phase 2C-3: Select Mode + Choose Difficulty Screens — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Make every mode reachable from the menu. PLAY → **Select Mode** (vs Computer · 2 Players · Practice); vs Computer → **Choose Difficulty** (Easy/Med/Hard → Start) → launches the game with the right `GameLaunchArgs`.

**Architecture:** The Play tab becomes the Select Mode UI (three cards). "vs Computer" pushes a `ChooseDifficultyScreen`; "2 Players" / "Practice" push the game directly via `AppRoutes.pushGame`. Difficulty defaults to the saved setting.

**Tech Stack:** Existing — `AppRoutes.pushGame`, `GameLaunchArgs{mode, difficulty}`, `SettingsController`, theme, provider.

---

## Task 1: Choose Difficulty screen

**Files:**
- Create: `lib/game/ui/choose_difficulty_screen.dart`

**Context:** `GameLaunchArgs({required GameMode mode, Difficulty? difficulty})`. `AppRoutes.pushGame(BuildContext, GameLaunchArgs)`. `SettingsController` (provided) → `settings.defaultDifficulty`. `Difficulty { easy, medium, hard }`.

- [ ] **Step 1: Create the screen**

`lib/game/ui/choose_difficulty_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../settings/difficulty.dart';
import '../../settings/settings_controller.dart';
import '../game_launch_args.dart';
import '../../navigation/app_routes.dart';

class ChooseDifficultyScreen extends StatefulWidget {
  const ChooseDifficultyScreen({super.key});

  @override
  State<ChooseDifficultyScreen> createState() => _ChooseDifficultyScreenState();
}

class _ChooseDifficultyScreenState extends State<ChooseDifficultyScreen> {
  late Difficulty _selected;

  @override
  void initState() {
    super.initState();
    _selected = context.read<SettingsController>().settings.defaultDifficulty;
  }

  void _start() {
    AppRoutes.pushGame(
      context,
      GameLaunchArgs(mode: GameMode.vsComputer, difficulty: _selected),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.woodDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.pinkHeading),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Choose Difficulty',
            style: TextStyle(
                color: AppColors.pinkHeading, fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _DifficultyCard(
                icon: Icons.sentiment_satisfied_alt,
                accent: AppColors.felt,
                title: 'Easy',
                desc: 'Relaxed play for beginners.',
                selected: _selected == Difficulty.easy,
                onTap: () => setState(() => _selected = Difficulty.easy),
              ),
              const SizedBox(height: 14),
              _DifficultyCard(
                icon: Icons.balance,
                accent: AppColors.gold,
                title: 'Medium',
                desc: 'A balanced challenge.',
                selected: _selected == Difficulty.medium,
                onTap: () => setState(() => _selected = Difficulty.medium),
              ),
              const SizedBox(height: 14),
              _DifficultyCard(
                icon: Icons.military_tech,
                accent: AppColors.crimson,
                title: 'Hard',
                desc: 'The Pro Circuit. Rarely misses.',
                selected: _selected == Difficulty.hard,
                onTap: () => setState(() => _selected = Difficulty.hard),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.crimson,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28)),
                  ),
                  onPressed: _start,
                  child: const Text('Start Game  ▷',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.pinkHeading)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _DifficultyCard extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String desc;
  final bool selected;
  final VoidCallback onTap;

  const _DifficultyCard({
    required this.icon,
    required this.accent,
    required this.title,
    required this.desc,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.gold : AppColors.crimsonDark,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                  border: Border.all(color: accent),
                ),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: AppColors.pinkHeading,
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(desc,
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 13)),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle, color: AppColors.gold),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify + commit**

Run: `flutter analyze lib/game/ui/choose_difficulty_screen.dart` — clean.
```bash
git add lib/game/ui/choose_difficulty_screen.dart
git commit -m "feat: add Choose Difficulty screen"
```

---

## Task 2: Select Mode (Play tab) + wiring + test

**Files:**
- Rewrite: `lib/screens/tabs/play_tab.dart`
- Test: `test/widget/select_mode_test.dart`

- [ ] **Step 1: Rewrite the Play tab as Select Mode**

`lib/screens/tabs/play_tab.dart`:
```dart
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../game/game_launch_args.dart';
import '../../navigation/app_routes.dart';
import '../../game/ui/choose_difficulty_screen.dart';

class PlayTab extends StatelessWidget {
  const PlayTab({super.key});

  void _launch(BuildContext context, GameMode mode) {
    AppRoutes.pushGame(context, GameLaunchArgs(mode: mode));
  }

  void _chooseDifficulty(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ChooseDifficultyScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text('Select Mode',
                style: TextStyle(
                    color: AppColors.pinkHeading,
                    fontSize: 24,
                    fontWeight: FontWeight.w800)),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                _ModeCard(
                  icon: Icons.smart_toy,
                  title: 'vs Computer',
                  desc: 'Challenge our advanced AI and sharpen your skills.',
                  onTap: () => _chooseDifficulty(context),
                ),
                const SizedBox(height: 16),
                _ModeCard(
                  icon: Icons.people_alt,
                  title: '2 Players',
                  desc: 'Classic local multiplayer. Pass and play with a friend.',
                  onTap: () => _launch(context, GameMode.twoPlayer),
                ),
                const SizedBox(height: 16),
                _ModeCard(
                  icon: Icons.adjust,
                  title: 'Practice',
                  desc: 'Unlimited shots to master your striker control.',
                  onTap: () => _launch(context, GameMode.practice),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.desc,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.felt.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.crimson, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.crimson,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: AppColors.pinkHeading, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: AppColors.gold,
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(desc,
                        style: const TextStyle(
                            color: AppColors.textLight, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Widget test**

`test/widget/select_mode_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carrom_pro/services/storage_service.dart';
import 'package:carrom_pro/settings/settings_controller.dart';
import 'package:carrom_pro/navigation/home_shell.dart';
import 'package:carrom_pro/navigation/app_routes.dart';
import 'package:carrom_pro/game/ui/game_screen.dart';
import 'package:carrom_pro/game/ui/choose_difficulty_screen.dart';

Future<Widget> _app() async {
  SharedPreferences.setMockInitialValues({});
  final storage = await StorageService.create();
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => SettingsController(storage)),
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
```

- [ ] **Step 3: Verify**

Run:
```bash
flutter analyze
flutter test
```
Expected: clean + green. (The `2 Players launches the game` test pushes a GameWidget — use `pump`, not `pumpAndSettle`, after that tap; `pumpAndSettle` is fine for the Choose Difficulty test since that screen has no running game.)

- [ ] **Step 4: Commit**

```bash
git add lib/screens/tabs/play_tab.dart test/widget/select_mode_test.dart
git commit -m "feat: Select Mode tab launches practice/2-player and opens difficulty for vs-Computer"
```

---

## Phase 2C-3 Done — Definition of Done

- From the menu: PLAY → Select Mode → 2 Players / Practice launches immediately; vs Computer → Choose Difficulty → Start launches with that difficulty.
- The whole single-player loop is reachable and playable end-to-end from the menu.
- `flutter test` green; `flutter analyze` clean.
- Phase 2C complete. Next major phase: **Phase 3** (economy + profile/XP), then Shop/Strikers (4), then audio/ads/polish (5).

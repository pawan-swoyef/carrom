# Carrom Pro — Phase 3: Economy + Profile/XP — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Add a local **coins** economy and a **profile** (XP, level, rank, wins/losses, streak, history). Award coins + XP + record the result when a vs-Computer match ends. Bind the menu's coins/level bar, the in-game coin pill, and a real **Profile/Records screen** to live data.

**Architecture:** A pure `PlayerProfile` model + rank logic (TDD). A `ProfileController` (ChangeNotifier) persists it via the existing `StorageService` (JSON blob) and exposes `recordMatch`, `spend`, `addCoins`, `reset`. Provided app-wide alongside `SettingsController`. The game screen calls `recordMatch` once when a vs-Computer match ends. The Profile tab renders the Records screen.

**Tech Stack:** Existing — `StorageService`, provider, theme. No new packages.

---

## File Structure (this phase)

```
lib/game/profile/
  player_profile.dart       immutable model (coins/xp/wins/losses/streak/history)
  rank.dart                 RankTier list + rankForXp(xp) -> RankInfo
  profile_controller.dart   ChangeNotifier persisting via StorageService
test/game/profile/
  player_profile_test.dart
  rank_test.dart
  profile_controller_test.dart
lib/main.dart               (modified) provide ProfileController
lib/screens/main_menu_screen.dart   (modified) bind coins/level
lib/game/ui/game_screen.dart        (modified) coin pill + award on win
lib/screens/tabs/profile_tab.dart   (modified) Records screen
```

---

## Task 1: PlayerProfile model + Rank (pure, TDD)

**Files:**
- Create: `lib/game/profile/player_profile.dart`
- Create: `lib/game/profile/rank.dart`
- Test: `test/game/profile/player_profile_test.dart`
- Test: `test/game/profile/rank_test.dart`

- [ ] **Step 1: Write the failing tests**

`test/game/profile/player_profile_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:carrom_pro/game/profile/player_profile.dart';

void main() {
  test('defaults are all zero/empty', () {
    const p = PlayerProfile();
    expect(p.coins, 0);
    expect(p.xp, 0);
    expect(p.wins, 0);
    expect(p.losses, 0);
    expect(p.bestStreak, 0);
    expect(p.currentStreak, 0);
    expect(p.history, isEmpty);
  });

  test('derived: gamesPlayed, level, efficiency', () {
    const p = PlayerProfile(xp: 250, wins: 3, losses: 1);
    expect(p.gamesPlayed, 4);
    expect(p.level, 3); // xp ~/ 100 + 1
    expect(p.efficiency, closeTo(0.75, 1e-9));
  });

  test('efficiency is 0 with no games', () {
    expect(const PlayerProfile().efficiency, 0);
  });

  test('copyWith overrides only given fields', () {
    const p = PlayerProfile(coins: 50);
    expect(p.copyWith(coins: 80).coins, 80);
    expect(p.copyWith(xp: 10).coins, 50);
  });

  test('toJson/fromJson round-trips', () {
    const p = PlayerProfile(
      coins: 120, xp: 340, wins: 5, losses: 2,
      bestStreak: 3, currentStreak: 1, history: [10, 20, 30],
    );
    final back = PlayerProfile.fromJson(p.toJson());
    expect(back.coins, 120);
    expect(back.xp, 340);
    expect(back.wins, 5);
    expect(back.losses, 2);
    expect(back.bestStreak, 3);
    expect(back.currentStreak, 1);
    expect(back.history, [10, 20, 30]);
  });
}
```

`test/game/profile/rank_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:carrom_pro/game/profile/rank.dart';

void main() {
  test('zero xp is the first tier', () {
    final r = rankForXp(0);
    expect(r.name, kRankTiers.first.name);
    expect(r.progress, inInclusiveRange(0.0, 1.0));
  });

  test('higher xp gives a later tier', () {
    final low = rankForXp(50);
    final high = rankForXp(5000);
    expect(high.tierIndex, greaterThan(low.tierIndex));
  });

  test('max tier reports full progress', () {
    final r = rankForXp(999999);
    expect(r.progress, 1.0);
    expect(r.name, kRankTiers.last.name);
  });

  test('progress is fractional within a tier', () {
    // Between tier 0 (min 0) and tier 1: halfway should be ~0.5.
    final mid = (kRankTiers[1].minXp) ~/ 2;
    final r = rankForXp(mid);
    expect(r.tierIndex, 0);
    expect(r.progress, closeTo(0.5, 0.2));
  });
}
```

- [ ] **Step 2: Run — expect failure** (`flutter test test/game/profile/`).

- [ ] **Step 3: Implement**

`lib/game/profile/player_profile.dart`:
```dart
/// Immutable local player profile. Persisted as JSON via ProfileController.
class PlayerProfile {
  final int coins;
  final int xp;
  final int wins;
  final int losses;
  final int bestStreak;
  final int currentStreak;
  final List<int> history; // coins earned per recent match (for the chart)

  const PlayerProfile({
    this.coins = 0,
    this.xp = 0,
    this.wins = 0,
    this.losses = 0,
    this.bestStreak = 0,
    this.currentStreak = 0,
    this.history = const [],
  });

  int get gamesPlayed => wins + losses;
  int get level => xp ~/ 100 + 1;
  double get efficiency => gamesPlayed == 0 ? 0 : wins / gamesPlayed;

  PlayerProfile copyWith({
    int? coins,
    int? xp,
    int? wins,
    int? losses,
    int? bestStreak,
    int? currentStreak,
    List<int>? history,
  }) {
    return PlayerProfile(
      coins: coins ?? this.coins,
      xp: xp ?? this.xp,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      bestStreak: bestStreak ?? this.bestStreak,
      currentStreak: currentStreak ?? this.currentStreak,
      history: history ?? this.history,
    );
  }

  Map<String, dynamic> toJson() => {
        'coins': coins,
        'xp': xp,
        'wins': wins,
        'losses': losses,
        'bestStreak': bestStreak,
        'currentStreak': currentStreak,
        'history': history,
      };

  factory PlayerProfile.fromJson(Map<String, dynamic> json) {
    return PlayerProfile(
      coins: (json['coins'] as num?)?.toInt() ?? 0,
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      wins: (json['wins'] as num?)?.toInt() ?? 0,
      losses: (json['losses'] as num?)?.toInt() ?? 0,
      bestStreak: (json['bestStreak'] as num?)?.toInt() ?? 0,
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
      history: ((json['history'] as List?) ?? const [])
          .map((e) => (e as num).toInt())
          .toList(),
    );
  }
}
```

`lib/game/profile/rank.dart`:
```dart
class RankTier {
  final String name;
  final int minXp;
  const RankTier(this.name, this.minXp);
}

/// Ascending by minXp. The first must start at 0.
const List<RankTier> kRankTiers = [
  RankTier('Rookie', 0),
  RankTier('Amateur', 200),
  RankTier('Pro', 600),
  RankTier('Veteran', 1200),
  RankTier('Master', 2000),
  RankTier('Pro Master', 3000),
  RankTier('Legend', 5000),
];

class RankInfo {
  final String name;
  final int tierIndex;
  final int xpIntoTier;
  final int xpForTier; // span to next tier; 0 at the max tier
  const RankInfo({
    required this.name,
    required this.tierIndex,
    required this.xpIntoTier,
    required this.xpForTier,
  });

  /// 0..1 toward the next tier (1.0 at the max tier).
  double get progress => xpForTier == 0 ? 1.0 : xpIntoTier / xpForTier;
  int get xpToNext => xpForTier == 0 ? 0 : xpForTier - xpIntoTier;
}

RankInfo rankForXp(int xp) {
  var index = 0;
  for (var i = 0; i < kRankTiers.length; i++) {
    if (xp >= kRankTiers[i].minXp) index = i;
  }
  final tier = kRankTiers[index];
  final isMax = index == kRankTiers.length - 1;
  final span = isMax ? 0 : kRankTiers[index + 1].minXp - tier.minXp;
  return RankInfo(
    name: tier.name,
    tierIndex: index,
    xpIntoTier: xp - tier.minXp,
    xpForTier: span,
  );
}
```

- [ ] **Step 4: Run — expect pass.** Commit:
```bash
git add lib/game/profile/player_profile.dart lib/game/profile/rank.dart test/game/profile
git commit -m "feat: add PlayerProfile model and rank tiers"
```

---

## Task 2: ProfileController (TDD)

**Files:**
- Create: `lib/game/profile/profile_controller.dart`
- Test: `test/game/profile/profile_controller_test.dart`

- [ ] **Step 1: Write the failing test**

`test/game/profile/profile_controller_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carrom_pro/services/storage_service.dart';
import 'package:carrom_pro/game/profile/profile_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<StorageService> fresh() async {
    SharedPreferences.setMockInitialValues({});
    return StorageService.create();
  }

  test('starts empty', () async {
    final c = ProfileController(await fresh());
    expect(c.profile.coins, 0);
    expect(c.profile.gamesPlayed, 0);
  });

  test('recordMatch win awards coins + xp, increments wins + streak', () async {
    final c = ProfileController(await fresh());
    await c.recordMatch(won: true, coinsPocketed: 9);
    expect(c.profile.wins, 1);
    expect(c.profile.currentStreak, 1);
    expect(c.profile.bestStreak, 1);
    expect(c.profile.coins, greaterThan(0));
    expect(c.profile.xp, greaterThan(0));
    expect(c.profile.history.length, 1);
  });

  test('a loss resets the current streak but keeps best', () async {
    final c = ProfileController(await fresh());
    await c.recordMatch(won: true, coinsPocketed: 5);
    await c.recordMatch(won: true, coinsPocketed: 5);
    expect(c.profile.bestStreak, 2);
    await c.recordMatch(won: false, coinsPocketed: 2);
    expect(c.profile.currentStreak, 0);
    expect(c.profile.bestStreak, 2);
    expect(c.profile.losses, 1);
  });

  test('persists across reloads', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.create();
    final c = ProfileController(storage);
    await c.recordMatch(won: true, coinsPocketed: 4);
    final coins = c.profile.coins;

    final reloaded = ProfileController(await StorageService.create());
    expect(reloaded.profile.coins, coins);
    expect(reloaded.profile.wins, 1);
  });

  test('spend fails when insufficient, succeeds otherwise', () async {
    final c = ProfileController(await fresh());
    await c.addCoins(50);
    expect(await c.spend(80), false);
    expect(c.profile.coins, 50);
    expect(await c.spend(30), true);
    expect(c.profile.coins, 20);
  });

  test('reset clears everything', () async {
    final c = ProfileController(await fresh());
    await c.recordMatch(won: true, coinsPocketed: 9);
    await c.reset();
    expect(c.profile.coins, 0);
    expect(c.profile.wins, 0);
  });
}
```

- [ ] **Step 2: Run — expect failure.**

- [ ] **Step 3: Implement**

`lib/game/profile/profile_controller.dart`:
```dart
import 'package:flutter/foundation.dart';
import '../../services/storage_service.dart';
import 'player_profile.dart';
import 'rank.dart';

/// Persisted player progression: coins, XP, stats. Notifies listeners on change.
class ProfileController extends ChangeNotifier {
  static const _key = 'profile';

  // Reward tuning (per match).
  static const int winBonusCoins = 100;
  static const int coinsPerPocket = 10;
  static const int winXp = 50;
  static const int lossXp = 15;
  static const int xpPerPocket = 5;
  static const int _historyCap = 12;

  final StorageService _storage;
  PlayerProfile _profile;

  ProfileController(this._storage) : _profile = _read(_storage);

  static PlayerProfile _read(StorageService s) {
    final json = s.getJson(_key);
    return json == null ? const PlayerProfile() : PlayerProfile.fromJson(json);
  }

  PlayerProfile get profile => _profile;
  RankInfo get rank => rankForXp(_profile.xp);

  Future<void> recordMatch({
    required bool won,
    required int coinsPocketed,
  }) async {
    final coinsEarned =
        (won ? winBonusCoins : 0) + coinsPocketed * coinsPerPocket;
    final xpEarned = (won ? winXp : lossXp) + coinsPocketed * xpPerPocket;
    final streak = won ? _profile.currentStreak + 1 : 0;
    final history = [..._profile.history, coinsEarned];
    final trimmed = history.length > _historyCap
        ? history.sublist(history.length - _historyCap)
        : history;

    _profile = _profile.copyWith(
      coins: _profile.coins + coinsEarned,
      xp: _profile.xp + xpEarned,
      wins: _profile.wins + (won ? 1 : 0),
      losses: _profile.losses + (won ? 0 : 1),
      currentStreak: streak,
      bestStreak: streak > _profile.bestStreak ? streak : _profile.bestStreak,
      history: trimmed,
    );
    await _save();
    notifyListeners();
  }

  Future<void> addCoins(int amount) async {
    _profile = _profile.copyWith(coins: _profile.coins + amount);
    await _save();
    notifyListeners();
  }

  Future<bool> spend(int amount) async {
    if (_profile.coins < amount) return false;
    _profile = _profile.copyWith(coins: _profile.coins - amount);
    await _save();
    notifyListeners();
    return true;
  }

  Future<void> reset() async {
    _profile = const PlayerProfile();
    await _save();
    notifyListeners();
  }

  Future<void> _save() => _storage.setJson(_key, _profile.toJson());
}
```

- [ ] **Step 4: Run — expect pass.** Commit:
```bash
git add lib/game/profile/profile_controller.dart test/game/profile/profile_controller_test.dart
git commit -m "feat: add ProfileController (coins, xp, stats, persistence)"
```

---

## Task 3: Provide controller + bind menu coins/level + HUD coin pill

**Files:**
- Modify: `lib/main.dart`
- Modify: `lib/screens/main_menu_screen.dart`
- Modify: `lib/game/ui/game_screen.dart`

- [ ] **Step 1: Provide ProfileController in `lib/main.dart`**

It already creates `storage` and a `MultiProvider`. Add a second provider:
```dart
import 'game/profile/profile_controller.dart';
```
In the `providers: [...]` list, add:
```dart
        ChangeNotifierProvider(create: (_) => ProfileController(storage)),
```

- [ ] **Step 2: Bind the menu's coins/level**

In `lib/screens/main_menu_screen.dart`, the `_StatsBar(coins: 0, level: 1)` is a placeholder. Read the profile:
```dart
import 'package:provider/provider.dart';
import '../game/profile/profile_controller.dart';
```
In `build`, get `final profile = context.watch<ProfileController>().profile;` and replace the placeholder with:
```dart
            _StatsBar(coins: profile.coins, level: profile.level),
```
Remove the `// Placeholder...` comment.

- [ ] **Step 3: Bind the in-game coin pill**

In `lib/game/ui/game_screen.dart`, the top-bar `_CoinPill(coins: 0)` shows a placeholder. Read the live balance (only meaningful for non-practice, but harmless everywhere):
```dart
import 'package:provider/provider.dart';
import '../profile/profile_controller.dart';
```
Where the coin pill is built, use `context.watch<ProfileController>().profile.coins`. (Keep it shown in practice too — it just shows the balance.) Remove the `// TODO(Phase 3)` comment.

- [ ] **Step 4: Verify + commit**

Run `flutter analyze` and `flutter test` — clean + green (existing widget tests that pump GameScreen/MainMenu must now provide a `ProfileController` — see note). 

> **Test note:** Any existing widget test that pumps `MainMenuScreen` or `GameScreen` directly inside a `MultiProvider` must add `ChangeNotifierProvider(create: (_) => ProfileController(storage))`. Tests that pump `GameScreen` WITHOUT a provider (e.g. `game_screen_test.dart`, `game_screen_match_test.dart`) will now throw `ProviderNotFound`. Fix each by wrapping the pumped widget in a `MultiProvider` providing both `SettingsController` and `ProfileController` over a fresh mock `StorageService`. Update them minimally.

```bash
git add lib/main.dart lib/screens/main_menu_screen.dart lib/game/ui/game_screen.dart test
git commit -m "feat: bind menu coins/level and in-game coin pill to ProfileController"
```

---

## Task 4: Award coins/XP when a vs-Computer match ends

**Files:**
- Modify: `lib/game/ui/game_screen.dart`

- [ ] **Step 1: Award once on match end**

In `_GameScreenState`, add `bool _awarded = false;`. In `_handleStrikeComplete`, when `session.isOver` is detected (the early-return branch), before/after `setState`, award exactly once for vs-Computer:
```dart
    if (session.isOver) {
      _awardIfNeeded(session);
      setState(() {});
      return;
    }
```
Add:
```dart
  void _awardIfNeeded(MatchSession session) {
    if (_awarded) return;
    if (widget.args.mode != GameMode.vsComputer) return;
    _awarded = true;
    final won = session.winner == Player.one;
    // Coins pocketed by the human (Player.one): 9 own coins minus those left.
    final pocketed = 9 - session.coinsRemainingFor(Player.one);
    context.read<ProfileController>().recordMatch(
          won: won,
          coinsPocketed: pocketed.clamp(0, 9),
        );
  }
```
In `_restartMatch`, reset `_awarded = false;` so the next match awards again.
(Imports: `package:provider/provider.dart`, `../profile/profile_controller.dart`, `../rules/player.dart` — some may already be present.)

- [ ] **Step 2: Verify + commit**

Run `flutter analyze` and `flutter test` — clean + green.
```bash
git add lib/game/ui/game_screen.dart
git commit -m "feat: award coins/xp and record result when a vs-Computer match ends"
```

---

## Task 5: Profile / Records screen

**Files:**
- Rewrite: `lib/screens/tabs/profile_tab.dart`

- [ ] **Step 1: Build the Records screen**

Rewrite `lib/screens/tabs/profile_tab.dart` to render the profile (bound via `context.watch<ProfileController>()`):
- Header "Your Records".
- A rank card: rank badge, `rank.name` ("Rank: <name>"), an XP progress bar (`rank.progress`) with `"<xpIntoTier> / <xpForTier> XP to next tier"` (or "Max tier" when `xpForTier == 0`).
- Stat tiles: **Wins** (`profile.wins`), **Losses** (`profile.losses`), **Performance Efficiency** (`(profile.efficiency * 100).round()%`), **Best Streak** (`profile.bestStreak`).
- A simple **Career Trajectory** bar chart from `profile.history` (each value → a vertical bar; scale to the max; if empty, show a "Play a match to see your trajectory" placeholder). Use `Container`s with heights — no chart package.
- A **Reset Records** button → `context.read<ProfileController>().reset()` (confirm via a simple AlertDialog).
Style with `AppColors` to match the dark/gold theme and the Records mockup. Keep it a single focused widget file; extract small private widgets (`_StatTile`, `_TrajectoryChart`) as needed.

- [ ] **Step 2: Widget test**

Create `test/widget/profile_tab_test.dart`:
```dart
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
```

- [ ] **Step 3: Verify + commit**

Run `flutter analyze` and `flutter test` — clean + green.
```bash
git add lib/screens/tabs/profile_tab.dart test/widget/profile_tab_test.dart
git commit -m "feat: add Profile/Records screen bound to ProfileController"
```

---

## Phase 3 Done — Definition of Done

- Winning/losing a vs-Computer match awards coins + XP and updates wins/losses/streak, persisted on device.
- The main menu's coins/level bar and the in-game coin pill show real values.
- The Profile tab shows rank + XP progress, wins/losses/efficiency/streak, a career-trajectory chart, and a working Reset.
- `flutter test` green; `flutter analyze` clean.
- Next: **Phase 4** — Shop + Strikers (spend coins on cosmetic strikers); then **Phase 5** — audio + ads + polish.

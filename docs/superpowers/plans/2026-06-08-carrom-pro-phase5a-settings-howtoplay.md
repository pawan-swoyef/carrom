# Carrom Pro — Phase 5A: Settings + How to Play Screens — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Build the Settings screen (audio/haptics toggles + default difficulty + reset stats) and the How to Play screen, and wire the main-menu pills (How to Play / Stats / Settings) to open them.

**Architecture:** Two pushed full-screen routes. Settings binds to the existing `SettingsController` (sound/music/vibration/difficulty) and `ProfileController` (reset). How to Play is static instructional content. The menu's three chips push these (Stats → a screen wrapping the existing `ProfileTab`).

**Tech Stack:** Existing — `SettingsController`, `ProfileController`, provider, theme. No new packages.

---

## Task 1: Settings screen

**Files:**
- Create: `lib/screens/settings_screen.dart`

**Context:** `SettingsController` (provided): `settings.soundEffects/music/vibration` (bool), `settings.defaultDifficulty` (Difficulty), `setSoundEffects/setMusic/setVibration(bool)`, `setDefaultDifficulty(Difficulty)`. `ProfileController.reset()`. `Difficulty { easy, medium, hard }`.

- [ ] **Step 1: Create the screen**

`lib/screens/settings_screen.dart`: a `StatelessWidget` `SettingsScreen` with its own `Scaffold` + `AppBar` (back, "Settings" title gold/pink, transparent). Body (`ListView`, padded):
- Section label "AUDIO & HAPTICS" (muted, letter-spaced).
- A card with three `SwitchListTile`s (gold active thumb): **Sound Effects** (`settings.soundEffects` → `setSoundEffects`), **Music** (→ `setMusic`), **Vibration** (→ `setVibration`). Read via `context.watch<SettingsController>()`.
- Section label "GAMEPLAY".
- A card with "Default Difficulty" + a 3-segment control (Easy / Med / Hard) — use a `SegmentedButton<Difficulty>` or a Row of selectable chips bound to `settings.defaultDifficulty` → `setDefaultDifficulty`. Selected segment crimson.
- A full-width crimson **"Reset All Stats"** `FilledButton.icon` → confirm `AlertDialog` → `context.read<ProfileController>().reset()`.
- A muted "Terms of Service & Privacy Policy" text link (no-op / underline).
- A footer card "Carrom Pro v1.0.0" + a muted tagline.
Style with `AppColors` to match the dark/gold/crimson Settings mockup.

- [ ] **Step 2: Verify + commit**

Run `flutter analyze lib/screens/settings_screen.dart` — clean.
```bash
git add lib/screens/settings_screen.dart
git commit -m "feat: add Settings screen"
```

---

## Task 2: How to Play screen

**Files:**
- Create: `lib/screens/how_to_play_screen.dart`

- [ ] **Step 1: Create the screen**

`lib/screens/how_to_play_screen.dart`: a `StatelessWidget` `HowToPlayScreen` with `Scaffold` + `AppBar` (back, "How to Play"). Body (`ListView`): numbered sections in styled cards:
1. **The Goal** — "Be the first to pocket all your coins (Black or White) into the four corner pockets."
2. **The Queen** — "The red Queen is worth bonus points. After pocketing the Queen you MUST 'cover' it by pocketing one of your own coins on the same or the very next strike — otherwise it returns to the board."
3. **Controls** — three sub-points: **Aim** ("Drag the striker to aim; a guide line shows the shot direction."), **Power** ("Pull back — the further you pull, the stronger the strike."), **Release** ("Lift your finger to launch.").
Each section: a small numbered gold circle + a gold title + muted body text, in a dark rounded card.
At the bottom: a full-width crimson **"Start Match"** `FilledButton` → `Navigator.of(context).maybePop()` (returns to the menu/select mode).
Style with `AppColors`.

- [ ] **Step 2: Verify + commit**

Run `flutter analyze lib/screens/how_to_play_screen.dart` — clean.
```bash
git add lib/screens/how_to_play_screen.dart
git commit -m "feat: add How to Play screen"
```

---

## Task 3: Wire the main-menu pills

**Files:**
- Modify: `lib/screens/main_menu_screen.dart`
- Test: `test/widget/main_menu_test.dart` (extend)

- [ ] **Step 1: Wire the chips**

In `lib/screens/main_menu_screen.dart`, the three pills currently call `_comingSoon(...)`. Replace their `onTap`s:
- **How to Play** → `Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HowToPlayScreen()))`.
- **Settings** → `Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()))`.
- **Stats** → push a screen that shows the records. Simplest: `MaterialPageRoute(builder: (_) => Scaffold(appBar: AppBar(title: const Text('Stats')), body: const SafeArea(child: ProfileTab())))` — reuse the existing `ProfileTab`. (Import `ProfileTab` from `tabs/profile_tab.dart`.)
Remove the now-unused `_comingSoon` method if nothing else uses it. Add imports for `SettingsScreen`, `HowToPlayScreen`, `ProfileTab`.

- [ ] **Step 2: Extend the menu test**

Add to `test/widget/main_menu_test.dart`:
```dart
  testWidgets('Settings chip opens the Settings screen', (tester) async {
    _portrait(tester);
    await tester.pumpWidget(await _menuApp());
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('AUDIO & HAPTICS'), findsOneWidget);
  });
```
(`_menuApp` already provides SettingsController + ProfileController + StrikerController? Check — it must provide SettingsController AND ProfileController for Settings/Stats. If `_menuApp` lacks ProfileController, add it. The Settings screen reads both.)

- [ ] **Step 3: Verify + commit**

Run `flutter analyze` and `flutter test` — clean + green. (Settings screen reads `SettingsController` + `ProfileController`; ensure the menu test's provider tree has both.)
```bash
git add lib/screens/main_menu_screen.dart test/widget/main_menu_test.dart
git commit -m "feat: wire menu pills to Settings, How to Play, and Stats"
```

---

## Phase 5A Done — Definition of Done

- Main menu's **How to Play**, **Stats**, **Settings** chips open real screens.
- Settings toggles persist (sound/music/vibration/difficulty); Reset All Stats clears the profile.
- `flutter test` green; `flutter analyze` clean.
- Next: **Phase 5B** — audio (SFX service + wiring; needs sound asset files), then **5C** — ads.

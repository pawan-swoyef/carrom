# Carrom Pro — Phase 4: Shop + Strikers — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans. Steps use checkbox (`- [ ]`) syntax.

**Goal:** A cosmetic striker shop. Players spend coins to buy striker skins, equip one, and the equipped skin renders on the in-game striker. Two bottom-nav tabs (Shop, Strikers) become functional.

**Architecture:** A static `StrikerSkin` catalog (id, name, price, render colours). A persisted `StrikerInventory` (owned ids + equipped id). A `StrikerController` (ChangeNotifier) that buys (spending via the existing `ProfileController`) and equips, persisted via `StorageService`. The `StrikerBody` renders using the equipped skin's colours; `GameScreen` passes the equipped skin into `CarromGame`. Shop + Strikers screens bind to the controllers.

**Tech Stack:** Existing — `StorageService`, `ProfileController`, provider, theme, Flame. No new packages.

---

## File Structure (this phase)

```
lib/game/strikers/
  striker_skin.dart         StrikerSkin + kStrikerCatalog + skinById
  striker_inventory.dart    owned ids + equipped id (persistable)
  striker_controller.dart   ChangeNotifier: buy/equip/persist
test/game/strikers/
  striker_inventory_test.dart
  striker_controller_test.dart
lib/main.dart                       (modified) provide StrikerController
lib/game/engine/bodies/striker_body.dart  (modified) render via skin
lib/game/engine/carrom_game.dart          (modified) accept a StrikerSkin
lib/game/ui/game_screen.dart              (modified) pass equipped skin
lib/screens/tabs/shop_tab.dart            (modified) Shop screen
lib/screens/tabs/strikers_tab.dart        (modified) Strikers screen
```

---

## Task 1: Catalog + inventory + controller (TDD) + provide

**Files:**
- Create: `lib/game/strikers/striker_skin.dart`
- Create: `lib/game/strikers/striker_inventory.dart`
- Create: `lib/game/strikers/striker_controller.dart`
- Test: `test/game/strikers/striker_inventory_test.dart`
- Test: `test/game/strikers/striker_controller_test.dart`
- Modify: `lib/main.dart`

- [ ] **Step 1: Catalog**

`lib/game/strikers/striker_skin.dart`:
```dart
/// A cosmetic striker skin. Colours are ARGB ints used by StrikerBody.render.
class StrikerSkin {
  final String id;
  final String name;
  final int price; // 0 = free/default
  final int fill;
  final int ring;
  final int accent;
  const StrikerSkin({
    required this.id,
    required this.name,
    required this.price,
    required this.fill,
    required this.ring,
    required this.accent,
  });
}

const String kDefaultStrikerId = 'classic';

/// The shop catalog. The first entry is the free default.
const List<StrikerSkin> kStrikerCatalog = [
  StrikerSkin(
      id: 'classic', name: 'Classic', price: 0,
      fill: 0xFFF5C1A0, ring: 0xFFD4915A, accent: 0xFFFBE8D8),
  StrikerSkin(
      id: 'crimson', name: 'Crimson Vibe', price: 800,
      fill: 0xFFB03048, ring: 0xFF7A1F30, accent: 0xFFF4A9B8),
  StrikerSkin(
      id: 'onyx', name: 'Onyx', price: 1200,
      fill: 0xFF2A2A2E, ring: 0xFF555560, accent: 0xFF8A8A95),
  StrikerSkin(
      id: 'royalgold', name: 'Royal Gold', price: 1500,
      fill: 0xFFE6C068, ring: 0xFFB8923E, accent: 0xFFFBE8D8),
  StrikerSkin(
      id: 'emerald', name: 'Emerald', price: 2500,
      fill: 0xFF2E8B6E, ring: 0xFF1C5A46, accent: 0xFFB8F0DC),
];

StrikerSkin skinById(String id) =>
    kStrikerCatalog.firstWhere((s) => s.id == id,
        orElse: () => kStrikerCatalog.first);
```

- [ ] **Step 2: Inventory model + test (TDD)**

`test/game/strikers/striker_inventory_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:carrom_pro/game/strikers/striker_inventory.dart';
import 'package:carrom_pro/game/strikers/striker_skin.dart';

void main() {
  test('defaults: only the classic striker, equipped', () {
    const inv = StrikerInventory();
    expect(inv.isOwned(kDefaultStrikerId), true);
    expect(inv.equipped, kDefaultStrikerId);
    expect(inv.isOwned('onyx'), false);
  });

  test('copyWith adds owned + changes equipped', () {
    const inv = StrikerInventory();
    final next = inv.copyWith(owned: {kDefaultStrikerId, 'onyx'}, equipped: 'onyx');
    expect(next.isOwned('onyx'), true);
    expect(next.equipped, 'onyx');
  });

  test('toJson/fromJson round-trips', () {
    const inv = StrikerInventory(owned: {kDefaultStrikerId, 'emerald'}, equipped: 'emerald');
    final back = StrikerInventory.fromJson(inv.toJson());
    expect(back.isOwned('emerald'), true);
    expect(back.equipped, 'emerald');
  });

  test('fromJson always includes the default striker', () {
    final back = StrikerInventory.fromJson({'owned': ['onyx'], 'equipped': 'onyx'});
    expect(back.isOwned(kDefaultStrikerId), true);
  });
}
```

`lib/game/strikers/striker_inventory.dart`:
```dart
import 'striker_skin.dart';

/// The player's owned striker ids and the equipped one. The default striker is
/// always owned.
class StrikerInventory {
  final Set<String> owned;
  final String equipped;

  const StrikerInventory({
    this.owned = const {kDefaultStrikerId},
    this.equipped = kDefaultStrikerId,
  });

  bool isOwned(String id) => owned.contains(id);
  bool isEquipped(String id) => equipped == id;

  StrikerInventory copyWith({Set<String>? owned, String? equipped}) =>
      StrikerInventory(
        owned: owned ?? this.owned,
        equipped: equipped ?? this.equipped,
      );

  Map<String, dynamic> toJson() => {
        'owned': owned.toList(),
        'equipped': equipped,
      };

  factory StrikerInventory.fromJson(Map<String, dynamic> json) {
    final owned = {
      kDefaultStrikerId,
      ...((json['owned'] as List?) ?? const []).map((e) => e as String),
    };
    final equipped = (json['equipped'] as String?) ?? kDefaultStrikerId;
    return StrikerInventory(
      owned: owned,
      equipped: owned.contains(equipped) ? equipped : kDefaultStrikerId,
    );
  }
}
```

- [ ] **Step 3: Controller + test (TDD)**

`test/game/strikers/striker_controller_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carrom_pro/services/storage_service.dart';
import 'package:carrom_pro/game/profile/profile_controller.dart';
import 'package:carrom_pro/game/strikers/striker_controller.dart';
import 'package:carrom_pro/game/strikers/striker_skin.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<(StorageService, ProfileController)> fresh() async {
    SharedPreferences.setMockInitialValues({});
    final s = await StorageService.create();
    return (s, ProfileController(s));
  }

  test('starts with only the classic striker equipped', () async {
    final (s, p) = await fresh();
    final c = StrikerController(s, p);
    expect(c.inventory.equipped, kDefaultStrikerId);
    expect(c.equippedSkin.id, kDefaultStrikerId);
  });

  test('buy fails without enough coins', () async {
    final (s, p) = await fresh();
    final c = StrikerController(s, p);
    final onyx = skinById('onyx'); // 1200
    expect(await c.buy(onyx), false);
    expect(c.isOwned('onyx'), false);
  });

  test('buy succeeds, deducts coins, marks owned', () async {
    final (s, p) = await fresh();
    await p.addCoins(2000);
    final c = StrikerController(s, p);
    final onyx = skinById('onyx');
    expect(await c.buy(onyx), true);
    expect(c.isOwned('onyx'), true);
    expect(p.profile.coins, 800); // 2000 - 1200
  });

  test('equip only works for owned skins', () async {
    final (s, p) = await fresh();
    final c = StrikerController(s, p);
    await c.equip('onyx'); // not owned → ignored
    expect(c.inventory.equipped, kDefaultStrikerId);
  });

  test('persists owned + equipped across reloads', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.create();
    final profile = ProfileController(storage);
    await profile.addCoins(1000);
    final c = StrikerController(storage, profile);
    await c.buy(skinById('crimson')); // 800
    await c.equip('crimson');

    final reloaded = StrikerController(
        await StorageService.create(), ProfileController(await StorageService.create()));
    expect(reloaded.isOwned('crimson'), true);
    expect(reloaded.inventory.equipped, 'crimson');
  });
}
```

`lib/game/strikers/striker_controller.dart`:
```dart
import 'package:flutter/foundation.dart';
import '../../services/storage_service.dart';
import '../profile/profile_controller.dart';
import 'striker_inventory.dart';
import 'striker_skin.dart';

/// Owns the player's striker inventory: buying (spends via ProfileController),
/// equipping, persistence.
class StrikerController extends ChangeNotifier {
  static const _key = 'strikers';

  final StorageService _storage;
  final ProfileController _profile;
  StrikerInventory _inv;

  StrikerController(this._storage, this._profile) : _inv = _read(_storage);

  static StrikerInventory _read(StorageService s) {
    final json = s.getJson(_key);
    return json == null
        ? const StrikerInventory()
        : StrikerInventory.fromJson(json);
  }

  StrikerInventory get inventory => _inv;
  StrikerSkin get equippedSkin => skinById(_inv.equipped);
  bool isOwned(String id) => _inv.isOwned(id);
  bool isEquipped(String id) => _inv.isEquipped(id);

  /// Buys [skin] if not owned and the player can afford it. Returns success.
  Future<bool> buy(StrikerSkin skin) async {
    if (_inv.isOwned(skin.id)) return false;
    final paid = await _profile.spend(skin.price);
    if (!paid) return false;
    _inv = _inv.copyWith(owned: {..._inv.owned, skin.id});
    await _save();
    notifyListeners();
    return true;
  }

  Future<void> equip(String id) async {
    if (!_inv.isOwned(id)) return;
    _inv = _inv.copyWith(equipped: id);
    await _save();
    notifyListeners();
  }

  Future<void> _save() => _storage.setJson(_key, _inv.toJson());
}
```

- [ ] **Step 4: Run all strikers tests — expect pass.**

Run: `flutter test test/game/strikers/`

- [ ] **Step 5: Provide StrikerController in `lib/main.dart`**

`StrikerController` needs the `ProfileController` instance. Restructure `main()` to create the controllers explicitly and provide them with `.value`:
```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await StorageService.create();
  final settings = SettingsController(storage);
  final profile = ProfileController(storage);
  final strikers = StrikerController(storage, profile);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: profile),
        ChangeNotifierProvider.value(value: strikers),
      ],
      child: const CarromProApp(),
    ),
  );
}
```
(Add the import for `striker_controller.dart`.)

- [ ] **Step 6: Verify + commit**

Run `flutter analyze` and `flutter test` — clean + green.
```bash
git add lib/game/strikers test/game/strikers lib/main.dart
git commit -m "feat: add striker catalog, inventory, StrikerController + provide it"
```

---

## Task 2: Apply the equipped skin to the in-game striker

**Files:**
- Modify: `lib/game/engine/bodies/striker_body.dart`
- Modify: `lib/game/engine/carrom_game.dart`
- Modify: `lib/game/ui/game_screen.dart`

- [ ] **Step 1: StrikerBody takes a skin**

In `lib/game/engine/bodies/striker_body.dart`, add a `StrikerSkin skin` field (import `striker_skin.dart`), defaulting to the classic skin: constructor `StrikerBody(this.geometry, {StrikerSkin? skin}) : skin = skin ?? skinById(kDefaultStrikerId);`. In `render`, replace the hard-coded `_fillColor/_ringColor/_innerColor` with `Color(skin.fill)`, `Color(skin.ring)`, `Color(skin.accent)`.

- [ ] **Step 2: CarromGame accepts a skin**

In `lib/game/engine/carrom_game.dart`, add a constructor param: `CarromGame({StrikerSkin? strikerSkin}) : strikerSkin = strikerSkin ?? skinById(kDefaultStrikerId), super(gravity: Vector2.zero(), zoom: 40);` with a `final StrikerSkin strikerSkin;` field (import the skin). In `_placePieces`, build the striker as `StrikerBody(geometry, skin: strikerSkin)`.

- [ ] **Step 3: GameScreen passes the equipped skin**

In `lib/game/ui/game_screen.dart` `initState`, read the equipped skin and pass it:
```dart
_game = CarromGame(skin: context.read<StrikerController>().equippedSkin);
```
Wait — the param is `strikerSkin`; use `CarromGame(strikerSkin: context.read<StrikerController>().equippedSkin)`. (Add imports for `StrikerController`.)

- [ ] **Step 4: Verify + commit**

Run `flutter analyze` and `flutter test` — clean + green. (Headless engine tests construct `CarromGame()` with no skin → defaults to classic; they keep passing. Widget tests pumping GameScreen now need a `StrikerController` provider — add it to those tests' `MultiProvider` over the same mock storage + a ProfileController.)
```bash
git add lib/game/engine lib/game/ui/game_screen.dart test
git commit -m "feat: render the equipped striker skin in-game"
```

---

## Task 3: Shop screen

**Files:**
- Rewrite: `lib/screens/tabs/shop_tab.dart`

- [ ] **Step 1: Build the Shop**

Rewrite `lib/screens/tabs/shop_tab.dart` as the Shop body (no Scaffold — HomeShell provides it; ProfileTab pattern). Read `final strikers = context.watch<StrikerController>();` and `final coins = context.watch<ProfileController>().profile.coins;`.
- **Header row:** "SHOP" title (gold) + a coin pill "★ <coins>".
- **Featured banner:** a rounded card ("FEATURED", "Ivory Collection", "Premium Striker Pack · Limited Edition", a crimson "View Pack" button). View Pack can scroll to / highlight the grid (or just a no-op styled button for now).
- **"ELITE STRIKERS" section** + a grid (`GridView`, 2 columns, `shrinkWrap` inside a scroll, or a `Wrap`) of cards for every skin in `kStrikerCatalog` except the default (or include it — your call; skip 'classic' since it's free/owned). Each card (`_StrikerCard`):
  - a circular preview rendered from the skin's colours (a `CustomPaint` or layered `Container`s: filled `Color(skin.fill)` circle + ring `Color(skin.ring)` + accent `Color(skin.accent)`),
  - the name,
  - if owned: "✓ OWNED" + an **EQUIP** button (gold outline; when already equipped show "EQUIPPED" disabled / gold-filled); else "★ <price>" + a **BUY** button (crimson).
  - Owned+equipped card: gold border.
  - BUY → `final ok = await strikers.buy(skin); if (!ok) show a SnackBar "Not enough coins";`. EQUIP → `strikers.equip(skin.id)`.
Style to match the mockup (dark cards, gold accents, crimson BUY). Make the whole body scrollable and overflow-safe at phone width (GridView childAspectRatio tuned; FittedBox on long text).

- [ ] **Step 2: Verify + commit**

Run `flutter analyze` and `flutter test` — clean + green. (Add a widget test `test/widget/shop_test.dart` that pumps ShopTab inside a MultiProvider (SettingsController not needed; ProfileController + StrikerController over mock storage), gives the profile coins, and asserts a striker name like 'Onyx' and a 'BUY' label appear. Set a portrait surface size to avoid overflow.)
```bash
git add lib/screens/tabs/shop_tab.dart test/widget/shop_test.dart
git commit -m "feat: add Shop screen (buy/equip striker skins)"
```

---

## Task 4: Strikers screen (equip owned)

**Files:**
- Rewrite: `lib/screens/tabs/strikers_tab.dart`

- [ ] **Step 1: Build the Strikers gallery**

Rewrite `lib/screens/tabs/strikers_tab.dart` as the body: read `StrikerController`. Show a header "MY STRIKERS" and a grid of the OWNED skins (`kStrikerCatalog.where((s) => strikers.isOwned(s.id))`). Each card: the skin preview circle + name + an **EQUIP/EQUIPPED** state (equipped one highlighted gold). Tapping a non-equipped owned card → `strikers.equip(s.id)`. Locked/unowned skins are NOT shown here (they live in the Shop) — optionally show a muted "Get more in the Shop" hint. Scrollable, overflow-safe.

- [ ] **Step 2: Verify + commit**

Run `flutter analyze` and `flutter test` — clean + green. (Optional: a small widget test asserting the equipped striker shows as equipped.)
```bash
git add lib/screens/tabs/strikers_tab.dart test
git commit -m "feat: add Strikers screen to equip owned skins"
```

---

## Phase 4 Done — Definition of Done

- Shop lists striker skins with live prices; BUY spends coins (blocked when too poor) and unlocks the skin; EQUIP sets it.
- Strikers tab shows owned skins and equips them.
- The equipped skin renders on the in-game striker.
- Inventory + equipped persist on device.
- `flutter test` green; `flutter analyze` clean.
- Next: **Phase 5** — audio (SFX), ads (google_mobile_ads), and final polish (How to Play, Settings screen, result-screen stats).

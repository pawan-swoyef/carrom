# Carrom Pro — UI Design Brief

A handoff document for the UI/UX team. It covers the app concept, the visual
direction, and every screen and dialog the app needs, with the elements and
states each should contain.

---

## 1. The Concept

**Carrom Pro** is a premium, fully-offline mobile carrom game (Android/iOS).
Players flick a striker to pocket their coins on a physics-based board. It ships
with three modes, full standard carrom rules (including the red Queen), and a
meta layer of progression, currency, and cosmetic strikers.

**Modes**
- **vs Computer** — single player against AI (Easy / Medium / Hard).
- **2 Players** — local pass-and-play on one device.
- **Practice** — solo free play, no opponent, unlimited shots.

**Meta systems** (all offline, saved on device)
- **Coins** — soft currency earned by winning and pocketing coins.
- **Profile / Records** — XP, rank tiers, win/loss stats, streaks, history.
- **Shop + Strikers** — buy and equip cosmetic striker skins with coins.

---

## 2. Visual Direction

The reference look is a **premium real carrom board** (think Carrom Pool) wrapped
in a dark, gold-accented "pro tournament" shell.

**Two visual worlds, kept consistent:**

1. **The board (in-game):** a realistic carrom board — polished **wooden frame**,
   smooth **tan/cream playing surface**, the traditional **painted lines** (center
   double-circle, four diagonal arrows pointing to the pockets, the two red
   baseline rectangles on each side), **four corner pockets**, **beige/natural and
   black coins**, a **red Queen** at center, and a **decorative striker**.

2. **The shell (menus/HUD):** dark vertical **wood-grain** backgrounds, **gold**
   titles and accents, **crimson red** primary buttons, with **pink-tinted**
   headings. Premium, clean, tactile.

**Color palette**
| Token | Hex | Use |
|---|---|---|
| Wood dark | `#161210` | App background |
| Wood grain | `#241B14` | Panels, nav bar |
| Surface | `#2A2622` | Cards, chips |
| Gold | `#E6C068` | Titles, accents, active ring |
| Gold bright | `#F2D27E` | Highlights |
| Crimson | `#B03048` | Primary buttons, Queen, active tab |
| Crimson dark | `#7A1F30` | Borders, pressed states |
| Felt / board green (alt) | `#2E6E50` | Optional board surface variant |
| Board tan | `#E2B66B` | Default board playing surface |
| Pink heading | `#F4A9B8` | Screen titles on dark |
| Text light | `#EDE6DD` | Body text |
| Text muted | `#9A8F86` | Secondary text |

**Type:** a strong serif/display for "Carrom Pro" and screen titles (gold);
a clean sans for body and buttons.

**Orientation:** **Portrait** everywhere (the board is square and fits portrait).

**Touch targets:** large, finger-friendly. Buttons rounded, with subtle depth
(inner shadow / bevel) consistent with the existing mockups.

---

## 3. Global Navigation

A persistent **bottom navigation bar** appears on the main hub screens:

`Play · Shop · Strikers · Profile`

- Active tab: crimson pill + label.
- Inactive: muted icon + label.
- The **Splash**, **Main Menu**, **full-screen Gameplay**, and modal dialogs do
  NOT show the bottom nav.

---

## 4. Screens

For each screen: **purpose**, **key elements**, and **states/notes**. Deliver each
in portrait at common phone sizes (e.g. 1080×2340), plus note safe-area handling.

### 4.1 Splash
- **Purpose:** brand moment while the app loads.
- **Elements:** "Carrom Pro" logo/title (gold), a board/striker emblem, a loading
  indicator (the gold ring arc), version label (e.g. `v1.0.0`) bottom-center.
- **States:** loading only; auto-advances to Main Menu.

### 4.2 Main Menu
- **Purpose:** entry hub.
- **Elements:** title + tagline ("THE PROFESSIONAL CIRCUIT"), a large circular
  **PLAY** button (crimson fill, gold ring), three secondary chips —
  **How to Play**, **Stats**, **Settings** — a sound on/off toggle (top corner),
  and a banner ad slot (bottom).
- **States:** sound on vs off (icon swap).

### 4.3 Select Mode
- **Purpose:** choose how to play.
- **Elements:** three large cards — **vs Computer**, **2 Players**, **Practice** —
  each with an icon, title, and one-line description. Top bar with back + settings.
  Bottom nav (Play active).
- **States:** card default / pressed.

### 4.4 Choose Difficulty *(only after "vs Computer")*
- **Purpose:** pick AI strength.
- **Elements:** three option cards — **Easy** ("Relaxed play for beginners"),
  **Medium** ("A balanced challenge"), **Hard** ("The Pro Circuit. Rarely
  misses") — a "Board Ready" preview panel, and a large **Start Game** button.
- **States:** unselected / selected (highlighted) per option.

### 4.5 Gameplay *(the core screen — see §6 for full HUD/controls detail)*
- **Purpose:** play a match on the board.
- **Elements:** top HUD (both players, turn indicator, Queen status, coin
  balance, pause), the **carrom board** (rendered by the game engine), and the
  bottom **strike interaction area** with an **aim guideline**.
- **States:** your turn / opponent's turn / simulating (pieces moving) /
  turn-result banners. (Details in §6.)

### 4.6 Settings
- **Purpose:** preferences.
- **Elements:** section **Audio & Haptics** — Sound Effects, Music, Vibration
  toggles. Section **Gameplay** — Default Difficulty segmented control
  (Easy/Med/Hard). A **Reset All Stats** button (destructive, crimson).
  Terms/Privacy link. App version footer. Bottom nav.
- **States:** each toggle on/off; selected difficulty.

### 4.7 Profile / Your Records
- **Purpose:** progression and stats.
- **Elements:** rank badge + **Rank tier** name (e.g. "Pro Master") with an XP
  progress bar ("750 / 1000 XP to next tier"); stat tiles — **Wins**, **Losses**,
  **Performance Efficiency %**, **All-time Best Streak**; a **Career Trajectory**
  bar chart; **Main Menu** and **Reset Records** buttons. Bottom nav (Profile
  active).
- **States:** empty (new player, zeros) vs populated.

### 4.8 How to Play
- **Purpose:** teach the rules + controls.
- **Elements:** numbered scrollable sections — **The Goal** (pocket all your
  coins), **The Queen** (pocket then cover on the same/next strike), **Controls**
  (Aim / Power / Release, with a small diagram) — and a **Start Match** button.
- **States:** scroll position only.

### 4.9 Shop
- **Purpose:** buy cosmetic strikers / packs with coins.
- **Elements:** coin balance (top); a featured item banner (e.g. "Premium Striker
  Pack — Ivory Collection"); a grid of purchasable items, each with a preview
  image, name, price (★ coins), and a **Buy** / **Owned** / **Equip** state.
  Bottom nav (Shop active).
- **States per item:** locked/buyable (price shown) · insufficient funds
  (disabled/greyed) · owned (not equipped) · owned + equipped (checkmark/ring).

### 4.10 Strikers
- **Purpose:** view and equip owned strikers.
- **Elements:** a gallery/grid of striker skins; each shows preview + name; the
  equipped one is highlighted; **Equip** action on selection; locked ones link to
  Shop. Bottom nav (Strikers active).
- **States:** owned/equipped/locked per striker.

---

## 5. Dialogs & Overlays

Modal layers over a screen (mostly over Gameplay). Provide as overlay frames.

### 5.1 Pause
- "Paused" title; **Resume**, **Restart**, sound toggle, **Quit to Menu**.

### 5.2 Quit Confirmation
- "Leave game? Progress will be lost." — **Yes, quit** / **Cancel**.

### 5.3 Result — Victory
- Big "VICTORY!" (gold), a sub-line (e.g. "Grand Slam Achieved"), a summary panel
  (**Coins Pocketed**, **Match Time**, coins earned), and **Play Again** /
  **Main Menu**. Trophy icon, gold frame, celebratory feel.

### 5.4 Result — Defeat / Draw
- "You Lose" / "Computer Wins" / "Draw"; same summary layout; **Rematch** /
  **Main Menu**. (Can reuse the Victory frame with different icon/text/color.)

### 5.5 Turn-Change Banner *(transient)*
- Brief centered banner: "Player 2's Turn" / "Computer's Turn". Fades out (~1s).

### 5.6 Foul Notice *(transient toast)*
- Short red banner: "Foul! One coin returned." Auto-dismiss.

### 5.7 Queen Notice *(transient toast)*
- "Queen pocketed — cover it!" / "Queen covered!" / "Queen returns to board."
  Auto-dismiss.

### 5.8 Coin-Pocketed Feedback *(transient)*
- Small "+1"/coin pop near the scoring player's panel. Subtle.

### 5.9 Ad Interstitial *(full screen)*
- A brief "Loading…" placeholder frame shown before/after the ad (the ad itself
  is provided by the ad SDK).

---

## 6. Gameplay Screen — Detailed Spec

This is the most important screen. Board is rendered by the physics engine; the
team should design the **frame, HUD, controls, and overlays** around it.

### 6.1 Top HUD
- **Player One panel:** avatar, name, coin color dot (White/Black), **coins
  remaining** count (badge).
- **Player Two / Computer panel:** same, mirrored on the right.
- **Active-turn indicator:** glow/ring/arrow on whoever's turn it is, plus a
  center label ("Your Turn" / "Computer's Turn").
- **Queen status chip:** shows "On board" / "Pocketed — pending cover" / "Covered".
- **Coin balance** (★) and a **Pause** button (top corner).

### 6.2 The Board
- Square carrom board centered: wooden frame, tan surface, painted center
  double-circle, four diagonal corner arrows, the two red baseline rectangles,
  four corner pockets. 9 white + 9 black coins + red Queen arranged in the center
  cluster; the striker on the active player's baseline.

### 6.3 Strike Interaction (controls)
**FINAL control model — pull-back slingshot (Carrom Pool style):**
- **Position:** drag the striker left/right along the baseline.
- **Aim:** drag to aim; a **dotted gold aim line** extends from the striker.
- **Power:** **pull back** to build power; the vertical **STRIKE POWER** meter
  (crimson gradient) fills as you pull.
- **Release:** the striker fires **forward** along the aim line.
- A clear **disabled state** while pieces are still moving.
- Bottom controls legend icons: **PULL BACK · RELEASE · AIM DRAG**.

### 6.4 Gameplay states to design
- **Idle / your turn:** striker placed, "drag to aim" hint (first turn only).
- **Aiming:** aim guideline + power indicator visible.
- **Simulating:** pieces moving, input locked (no aim line; maybe a subtle
  "…" indicator).
- **Opponent/AI turn:** input locked, opponent panel active.
- **Banners:** turn-change, foul, queen — see §5.

---

## 7. Component / Style Guidelines

- **Buttons:** primary = crimson fill, light text, rounded (~12–16px), subtle
  bevel; secondary = surface card with crimson-dark border + gold icon.
- **Cards:** surface color, rounded, 1px crimson-dark border, soft inner shadow.
- **Toggles:** gold knob on dark track.
- **Chips/badges:** small rounded surface tiles; counts in gold or pink.
- **Icons:** line icons in gold (inactive) / pink or crimson (active).
- **Motion:** subtle scale on press; banners fade+slide; victory has a celebratory
  pop. Keep menus snappy.

---

## 8. Asset Checklist (for the UI team)

- App icon + splash logo (gold "Carrom Pro").
- **Board art:** wooden frame, tan surface texture, painted lines (center circle,
  arrows, baseline rectangles), corner pockets.
- **Pieces:** white coin, black coin, red Queen, and **striker skins** (at least:
  default + 1–2 premium for the shop, e.g. "Ivory").
- **Aim guideline** + power indicator visuals.
- Icons: play, sound on/off, settings, stats/chart, book (how-to), shop bag,
  striker (target), profile, pause, back, coin (★), trophy, rank badge, foul,
  queen.
- Player avatars (default set), computer/robot avatar.
- Backgrounds: wood-grain (menus), board surface.
- Result screens: trophy, defeat icon, gold frame, confetti.
- Empty-state illustration for new Profile.

---

## 9. Screen Inventory (quick checklist)

**Screens (10):** Splash · Main Menu · Select Mode · Choose Difficulty · Gameplay
· Settings · Profile/Records · How to Play · Shop · Strikers

**Dialogs/Overlays (9):** Pause · Quit Confirm · Victory · Defeat/Draw ·
Turn-Change Banner · Foul Notice · Queen Notice · Coin-Pocketed Feedback ·
Ad Interstitial

**Bottom nav (4 tabs):** Play · Shop · Strikers · Profile

# Carrom Pro — Design Spec

**Date:** 2026-06-08
**Status:** Approved (brainstorming complete)
**Platform:** Flutter + Flame + Forge2D (Box2D), offline mobile (Android/iOS)

---

## 1. Overview

Carrom Pro is a fully-offline mobile carrom game with realistic Forge2D
physics. It ships with three game modes (vs Computer, local 2-player pass &
play, Practice), full standard carrom rules including the red Queen and the
queen-cover mechanic, and a meta layer of local economy, profile/XP, and a
cosmetic striker shop. No backend or networking — all state is persisted
locally.

### Visual identity (locked from approved mockups)
- Dark vertical wood-grain backgrounds.
- **Gold** for titles/accents, **crimson red** for primary buttons and Queen,
  **green felt** as a secondary surface, **pink-tinted** headings on dark.
- Portrait orientation throughout (carrom board is square → fits portrait).
- App name: **Carrom Pro**. Tagline: "The Professional Circuit".

---

## 2. Architecture

Layered, with the hard game logic kept as **pure Dart** (no Flame dependency)
so it is unit-testable without running physics.

```
┌─────────────────────────────────────────────┐
│  Flutter UI (screens, overlays, bottom nav)  │
├─────────────────────────────────────────────┤
│  Game Mode Controller                        │
│  (decides human/AI per turn, drives scoring) │
├──────────────────┬──────────────────────────┤
│  Rules Engine    │   AI Player               │
│  (PURE DART)     │   (PURE DART)             │
├──────────────────┴──────────────────────────┤
│  Flame + Forge2D simulation                  │
│  striker · coins · walls · pocket sensors    │
├─────────────────────────────────────────────┤
│  Meta systems (PURE DART + storage)          │
│  economy · profile/XP · shop/strikers        │
├─────────────────────────────────────────────┤
│  Services: storage · audio · ads             │
└─────────────────────────────────────────────┘
```

**Key decision:** the physics layer only reports facts ("these coins were
pocketed this turn; striker pocketed yes/no"). The Rules Engine consumes those
facts and decides the next state. The Rules Engine and AI Player never import
Flame.

---

## 3. Modules

### 3.1 Game core (Flame + Forge2D)
- `CarromGame extends Forge2DGame`: zero gravity (top-down), linear damping on
  pieces to model board friction so pieces decelerate and stop.
- Bodies:
  - `Striker` (dynamic, heavier).
  - `Coin` with type White / Black / Queen — 9 white, 9 black, 1 red queen.
  - `BoardWalls` (static rails forming the frame; restitution tuned for bounce).
  - `Pocket` x4 (corner sensor fixtures; on overlap, the piece is captured).
- Standard opening layout: coins arranged in the center circle, queen at center.
- Restitution / friction / pocket radius are tuning constants, validated by
  play-testing (not unit tests).

### 3.2 Controls — Hybrid scheme
1. **Position:** horizontal slider slides the striker left/right along the
   active player's baseline.
2. **Aim:** drag on/around the striker rotates the aim direction; an aim line
   is drawn.
3. **Power:** vertical POWER meter sets strike strength (drag to fill).
4. **Strike:** the **STRIKE** button launches the striker (applies linear
   impulse along the aim vector scaled by power).

Input is locked during simulation and during the opponent/AI turn.

### 3.3 Rules engine (pure Dart, TDD)
Owns all match logic:
- Side assignment (one player White, other Black).
- Per-turn resolution given `{coinsPocketed, strikerPocketed}`:
  - Pocketing one of your own coins → score + **continue turn** (extra shot).
  - Pocketing no coin → turn passes.
  - Pocketing opponent coin / wrong-coin fouls → penalty (return a coin) and
    turn passes (configurable to standard rules).
  - Striker pocketed → foul: return one pocketed coin to board, turn passes.
- **Queen-cover:** pocketing the Queen marks it *pending*. It is only secured
  if the same player pockets one of their own coins on the **next** strike. If
  not covered, the Queen returns to the board (center).
- Win: a player pockets all their coins (and, if they had pocketed the Queen,
  it is covered). Standard tie-break/draw handling.
- Pure data in/out — no Flame, no rendering.

### 3.4 AI player (pure Dart, TDD)
- Given a board snapshot (piece positions, whose coins), choose a target coin +
  target pocket, compute the required striker placement + aim vector + power.
- Apply **difficulty noise** to aim/power: Easy (large noise), Medium, Hard
  (minimal noise, "rarely misses").
- Output is an intended shot `{strikerX, aimAngle, power}` handed to the same
  control path a human would drive.

### 3.5 Modes
- **vs Computer:** human vs AI; difficulty chosen on the Choose Difficulty
  screen (Easy/Medium/Hard).
- **2 Players:** local pass & play; turn-change banner cues the next human.
- **Practice:** solo free play, unlimited shots, no opponent, no win condition.
- A Mode Controller maps "whose turn" → human input or AI, and decides what
  match results feed into the meta systems (Practice does not award progression
  by default).

### 3.6 Economy (local)
- Single soft currency: **★ coins**.
- Earned: match win bonus + per coin pocketed during a match.
- Spent: striker shop.
- Persisted locally; surfaced in the gameplay HUD and shop.

### 3.7 Profile / Records (local)
- XP awarded per match (win/loss/coins). XP maps to **rank tiers** (e.g. "Pro
  Master") with progress to next tier.
- Tracked: wins, losses, games played, performance efficiency %, all-time best
  streak, and a per-session history powering the "Career Trajectory" chart.
- Backs the Records / Profile screen.

### 3.8 Shop + Strikers (local)
- Catalog of cosmetic striker skins: `{id, name, price, owned, equipped}`.
- Buy with coins (insufficient funds blocked); equip → applied to the striker
  sprite in gameplay. Exactly one equipped at a time.
- "Premium Striker Pack / Ivory Collection" featured item.
- v1 is coins-only (no real-money IAP).

### 3.9 Services
- **Storage:** `shared_preferences` for scalar settings/stats; JSON-encoded
  blobs for shop inventory and match history.
- **Audio:** SFX for strike, coin collision, pocket, win/lose; respects the
  Sound/Music/Vibration toggles.
- **Ads:** `google_mobile_ads` — banner on the main menu, interstitial between
  matches (before the result dialog).

---

## 4. Screens & overlays (from approved mockups)

**Screens:** Splash, Main Menu, Select Mode, Choose Difficulty, Gameplay (+HUD),
Settings, Records/Profile, How to Play, Shop, Strikers.

**Bottom nav:** Play · Shop · Strikers · Profile.

**Overlays/dialogs:** Pause, Quit confirm, Victory/Result, Lose/Draw,
turn-change banner, foul notice, queen notice, coin-pocketed feedback, ad
interstitial.

**Gameplay HUD:** both player panels (avatar, coin color, coins remaining),
active-turn highlight, Queen status ("Pocketed/pending/covered"), coin balance,
pause + info buttons, the slider/POWER/STRIKE control cluster.

---

## 5. Data flow (one turn)

Slide striker → aim → fill POWER → STRIKE → impulse on striker body → Forge2D
simulates collisions → pocket sensors flag captured pieces → when all piece
velocities ≈ 0 the turn **settles** → Rules Engine resolves (scores, fouls,
queen-cover, win check) → HUD updates → control passes to next player (human
input, or AI computes & auto-strikes) → on match end, results feed Economy +
Profile, then the Result dialog shows.

---

## 6. Testing strategy

- **Unit tests (TDD):** Rules Engine (turn resolution, queen-cover edge cases,
  fouls, win/draw), AI Player (target & pocket selection, difficulty noise
  bounds), Economy (earn/spend math), Profile (XP→rank, streak, efficiency),
  Shop (buy/equip, insufficient funds).
- **Play-test tuning:** physics constants (friction/damping, restitution,
  pocket radius, striker mass, impulse scaling), control feel.

---

## 7. Build order (phased)

1. **Foundation** — scaffold, theme, storage + settings services, navigation /
   bottom-nav shell, splash + main menu.
2. **Core game** — physics board, rules engine (TDD), hybrid controls, modes,
   AI (TDD). *Playable carrom after this phase.*
3. **Profile + Economy** — XP/rank/stats, coin earning, Records screen.
4. **Shop + Strikers** — inventory, purchasing, equipping cosmetics.
5. **Ads + audio + polish** — SFX, ads, result/victory flow, How to Play.

Each phase rests on a working previous phase; phase 2 delivers a playable game
early, and the meta systems layer on top of match results.

---

## 8. Scope boundaries (YAGNI)

- **Offline only.** No networking, no real tournaments, no leaderboards server.
  The "Global Elite Tournament" banner is decorative copy.
- **No real-money IAP** in v1 (shop is coins-only).
- Single soft currency (no gems/second currency).
- Cosmetic-only shop (skins never affect physics/gameplay).

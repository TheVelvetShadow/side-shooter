# Space Shooter — Game Design Document

> **For Claude Code:** Read this file before starting any session. It contains settled design decisions. Do not deviate from the systems described here without flagging a conflict first. Cross-reference `TODO.md` for current task priorities and `Card_Database_Spreadsheet.xlsx` / `weapons_prototype.xlsx` for content data.

---

## 1. Game Overview

A roguelike horizontal space shooter with bullet-bouncing mechanics and a Balatro-inspired Pilot card system. The core loop combines moment-to-moment shooting with strategic pilot composition and weapon building across escalating difficulty tiers called Antes.

**Engine:** Godot 4.x / GDScript  
**Architecture:** EventBus pattern for decoupled signals, Autoloads for global state  
**Testing:** GUT framework (TDD — red/green/refactor cycle)  
**Collision Layers:** 1=Player, 2=Enemies, 4=Player bullets, 8=Enemy bullets

---

## 2. Core Run Structure (The Ante Loop)

The run is structured in Antes, each containing 3 levels. This mirrors Balatro's ante system.

```
ANTE 1
  └── Level 1 (wave) → Shop → Level 2 (wave) → Shop → Level 3 (Boss)
                                                              ↓
ANTE 2 (harder enemies, better cards available in pool)
  └── Level 1 → Shop → Level 2 → Shop → Level 3 (Boss)
                                                              ↓
ANTE 3 ...
```

**Key rules:**
- All pilot upgrades and weapon tiers persist for the full run
- The shop appears between every level — pilots can be swapped or bought here
- Boss kills gate progression to the next Ante
- Unlocks earned (ships, pilots, weapons) persist across runs via meta-progression (Pilot Academy)
- Enemy kills drop **Energy** (the in-game resource); Energy is collected and spent mid-run on weapon tier upgrades OR ship stat upgrades via a pause menu

---

## 3. Weapon System

### 3.1 Weapon Categories

Three categories, each with distinct behaviour and card synergies:

| Category | Examples | Characteristics |
|---|---|---|
| Ballistic | Machine Gun, Shotgun | High fire rate, low per-shot damage, projectile count scaling |
| Energy | Laser, Plasma Cannon | Consistent DPS, AOE potential, slower fire rate |
| Missile | Homing Missile | Tracking, AOE on impact, medium fire rate |

### 3.2 Weapon Slots

- Default: 4–6 weapon slots active simultaneously (Brotato-style)
- All equipped weapons fire independently on their own timers
- Weapons do not directly interact mid-flight — interaction happens through shared card modifiers

### 3.3 Weapon Tiers (XP-Driven Merging)

Weapons upgrade through 5 tiers. Tiers are reached via XP thresholds — **merging is automatic when a weapon accumulates enough XP**, not triggered by finding duplicates.

```
Tier 1 → Tier 2 → Tier 3 → Tier 4 → Tier 5
```

Each tier improves base stats according to per-weapon scaling profiles defined in `weapons_prototype.xlsx`. Different weapons scale differently — e.g. Shotgun emphasises projectile count growth, Laser emphasises fire rate.

Tier upgrades happen **mid-level** as XP is earned, creating reactive feedback during combat (distinct from the strategic card layer at the shop).

### 3.4 Weapon Scaling Formula (Base Stats Only)

```
Tier Damage    = Base Damage    × (1 + DMG_Scale)^(tier - 1)
Tier Fire Rate = Base Fire Rate × (1 + RoF_Scale)^(tier - 1)
Tier AOE       = Base AOE       × (1 + AOE_Scale)^(tier - 1)
```

Base values and scale percentages live in `weapons_prototype.xlsx` — do not hardcode them.

---

## 4. Pilot System

### 4.1 Overview

Pilots are strategic modifier cards (Balatro-style Jokers) applied on top of base weapon and ship stats. They are thematically framed as specialist pilots with unique abilities and affinities. Pilots are separate from the XP/gem system. They are acquired and managed at the **shop between levels only**.

Lore framing: each Pilot card represents a specialist who joins your squad — their expertise translates directly into stat bonuses (e.g. a weapons specialist who adds +30 damage to Ballistic weapons, or an ace who doubles damage on bounced shots).

### 4.2 Pilot Acquisition

- Pilots are available to buy/swap in the shop after every level
- Rarer pilots become available in higher Antes
- Pilots are unlocked into the pool via meta-progression (Pilot Academy) — not all pilots are available from run 1
- The player holds a limited active pilot roster (target: ~5 active pilots)
- Pilots are not lost between levels within a run — they accumulate and compound

### 4.3 Pilot Types

Three distinct pilot types exist in the pool. All three can appear simultaneously, creating emergent synergies through RNG:

| Type | Scope | Example | Notes |
|---|---|---|---|
| **Global** | All weapons / ship | +15% Attack Damage | Always useful, baseline floor |
| **Weapon Type** | One category | Ballistic ×2 Damage | Build-shapers — reward committing to a category |
| **Conditional** | Trigger-based | ×3 damage on bounced shots | High ceiling, weak alone, explosive in combos |

Conditionals tied to the **bounce mechanic** are a signature pilot type unique to this game — prioritise designing these.

### 4.4 Order of Operations (Balatro-Style)

This order is fixed and must be implemented consistently. Pilots resolve in layers, left to right:

```
Base Damage
  + Flat additions       (global pilots: e.g. Power Surge +15%)
  × Type multiplier      (weapon category pilots: e.g. Ballistic ×2)
  × Conditional mult     (trigger pilots: e.g. Bounce ×3, Pierce ×2)
  × Combo bonus          (multi-pilot combos: e.g. The Infinite Bouncer ×1.5)
```

**The UI must make this chain visible.** When a shot fires and triggers modifiers, the player should see the running multiplication — e.g.:

```
12 → ×2 (Ballistic) → ×3 (Bounce) = 72
```

This is the core dopamine loop. The order of operations is also strategy — stacking a type multiplier before a conditional multiplier compounds correctly.

### 4.5 Pilot Rarity Distribution

| Rarity | Target % | Notes |
|---|---|---|
| Common | 70% | Global stat pilots, safe picks |
| Rare | 25% | Weapon type pilots, build-shapers |
| Epic | 4.5% | Strong conditionals, combo enablers |
| Legendary | 0.5% | Run-defining, one per pool |

Target total pilot pool: **100+ pilots**. Currently 6 designed (see `Card_Database_Spreadsheet.xlsx` — rename to `Pilot_Database_Spreadsheet.xlsx`). Pilots are added to the pool as they are unlocked via meta-progression.

### 4.6 Pilot Combo System

Some pilot combinations trigger named combos with bonus effects. These are tracked in the Card Combos sheet. Example: **The Infinite Bouncer** (Ricochet ×3 + Bounce Master + Super Bounce) gives +25% damage per bounce and bounced bullets deal +50%.

Combo detection must be implemented in the pilot resolution system — check active pilot roster against combo trigger conditions after every pilot acquisition.

---

## 5. Damage Calculation (Full Stack)

Putting weapons, ship bonuses, and pilots together, the complete damage formula for a single shot is:

```
Final Damage = (Base Damage [weapon tier] + Ship Weapon Bonuses + Pilot Flat Additions)
               × Pilot Type Multiplier
               × Pilot Conditional Multiplier
               × Pilot Combo Bonus (if triggered)
```

Ship weapon bonuses (e.g. "+2 damage") are applied as flat additions before the pilot multiplier chain. This means pilot multipliers amplify ship bonuses — rewarding matched ship+pilot builds.

Projectile count and fire rate are calculated separately using the same layered approach and then feed into DPS:

```
Final DPS = Final Damage × Final Fire Rate × Final Projectile Count
```

The Card Simulator sheet in `weapons_prototype.xlsx` models this — use it to sanity check implementation.

---

## 6. Controls & Aiming

### 6.1 Movement
Ship moves in 8 directions. Bindings: WASD + Arrow keys (keyboard), left stick (gamepad).

### 6.2 Aiming
The player controls a **crosshair** that can be positioned anywhere on screen:

| Input | Behaviour |
|---|---|
| Mouse move | Crosshair snaps to mouse position; OS cursor is hidden |
| Gamepad right stick | Crosshair moves at `AIM_SPEED` px/s from current position |
| Switching input | Detected automatically — last input wins |

The crosshair is a Node2D added by Main.gd at runtime. It registers in group `"crosshair"` so Player can locate it.

### 6.3 Firing Direction
Bullets fire from `BulletSpawn` toward `crosshair.global_position`. This gives bullets a real direction vector (X + Y components), which means:
- Bullets naturally have Y velocity whenever the crosshair is off-axis
- Bounce mechanic works without any additional setup

Fire bindings: Space / Mouse Left Button / Gamepad face button A.

### 6.4 Input Actions Summary

| Action | Keyboard | Mouse | Gamepad |
|---|---|---|---|
| move_up | W / ↑ | — | Left stick up / D-pad up |
| move_down | S / ↓ | — | Left stick down / D-pad down |
| move_left | A / ← | — | Left stick left / D-pad left |
| move_right | D / → | — | Left stick right / D-pad right |
| fire | Space | Left click | A button |
| aim | — | Mouse position | Right stick (aim_up/down/left/right) |

---

## 7. Bounce Mechanic

Bullets bounce off level walls. This is a core mechanical identity of the game, not an optional modifier. Bounce count is a base property of the level/bullet type, upgradeable via pilots.

Conditional pilots that trigger **on bounce** are the highest-priority conditional pilot type to design — they create combos unique to this game that no reference title (Brotato, Vampire Survivors, Balatro) has.

---

## 8. Ship System

### 7.1 Ship Base Stats

Each ship has five base stats that define its identity. These are fixed at run start (from meta-unlock level) and can be upgraded mid-run via Energy spend:

| Stat | Description |
|---|---|
| **Hit Points** | Total HP before shield |
| **Speed** | Movement speed |
| **Weapon Slots** | How many weapons can be equipped simultaneously |
| **Armour** | Flat damage reduction per hit |
| **Weapon Bonus** | Flat addition to all weapon damage (feeds into pilot multiplier chain) |

### 7.2 Available Ships (Meta-Unlocked)

8 ships total. Exact stats TBD in spreadsheet — architecture defined here:

| Ship | Style | Unlock |
|---|---|---|
| Interceptor | Balanced starter | Available from run 1 |
| Tank | High HP, low speed, high armour | Pilot Academy |
| Glass Cannon | Max weapon bonus, fragile (low HP) | Pilot Academy |
| Scout | High speed, dodge-focused | Pilot Academy |
| Dreadnought | Slow, maximum weapon slots | Pilot Academy |
| TBD 6 | — | Pilot Academy |
| TBD 7 | — | Pilot Academy |
| TBD 8 | — | Pilot Academy |

Ship selection happens before a run starts. Ship stats influence pilot synergy (e.g. Glass Cannon + conditional damage pilots; Dreadnought + weapon-type pilots across many slots).

### 7.3 Mid-Run Ship Upgrades

Energys collected mid-run can be spent on either:
- **Weapon tier upgrades** — advance a weapon's XP threshold
- **Ship stat upgrades** — increase one of the five ship stats for the remainder of the run

Ship upgrades gained mid-run are run-scoped only — they reset at run end. Permanent ship stat growth is meta-only (Pilot Academy).

---

## 9. Meta Progression (Pilot Academy)

The Pilot Academy is the between-run hub. It is **not a priority until core gameplay loop is complete.**

Three unlock tracks — all gated behind Pilot Academy progress:

| Track | What unlocks |
|---|---|
| **Ships** | 7 ships beyond the starter Interceptor |
| **Weapons** | Additional weapon types added to the run pool |
| **Pilots** | New pilot cards added to the shop pool (100+ total) |

- Run XP persists to the Academy and funds unlocks
- Permanent ship stat upgrades available (small, not run-defining)
- All unlocks carry into every future run
- The active pilot pool in any given run is limited to what has been unlocked so far — early runs have fewer pilots available, increasing build variety as the player progresses

---

## 10. Technical Architecture

### 9.1 Patterns in Use

- **EventBus** — all cross-system communication via signals (do not create direct node references between systems)
- **Autoloads** — GameManager (global state), EventBus (signals)
- **Resource-based data** — weapon and card stats are data-driven, not hardcoded
- **GUT TDD** — write tests before implementing new systems

### 9.2 Key Signals (EventBus)

Add new signals here as they are created. Existing signals include player death, enemy death, XP drop, level up.

### 9.3 Collision Layers

```
Layer 1 — Player
Layer 2 — Enemies  
Layer 4 — Player bullets
Layer 8 — Enemy bullets
```

---

## 11. Settled Design Decisions

These are not open questions. Do not revisit without flagging explicitly:

- Weapons tier up via XP thresholds, not duplicate collection
- "Cards" are called **Pilots** — Global / Weapon Type / Conditional — all three types in the pool
- Order of operations: Flat (incl. ship bonus) → Type × → Conditional × → Combo ×
- 4–6 simultaneous weapon slots (ship-dependent)
- Ante structure: 3 levels per ante, shop between each, boss at end
- Bounce is a base mechanic, not a pilot unlock
- Bounce-conditional pilots are a design priority and a unique game identity
- Pilot UI must show the damage chain visibly (Balatro-style running total)
- Data for weapons, pilots, and ships lives in spreadsheets, not hardcoded in scripts
- Pilots are available **shop only** (between levels) — never mid-run drops
- Energys dropped by enemies can be spent mid-run on **weapon tiers OR ship stats**
- 8 ships total, all (except Interceptor) unlocked via Pilot Academy
- 100+ pilots in pool, unlocked progressively via Pilot Academy
- Weapons also locked/unlocked via Pilot Academy — not all available from run 1

---

## 12. Reference Titles

| Game | What to Borrow |
|---|---|
| Balatro | Order of operations, visible damage chain UI, ante loop structure |
| Brotato | Multi-weapon simultaneous firing, weapon category scaling coefficients |
| Vampire Survivors | XP-driven progression feel, enemy wave escalation |

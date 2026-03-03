# Side Shooter

A roguelike horizontal space shooter built in Godot 4.x. Combines moment-to-moment bullet-bouncing combat with a Balatro-inspired Pilot card system and a Brotato-style multi-weapon loadout.

> For full design decisions see `DESIGN.md`. For current task priorities see `TODO.md`.

---

## Concept

- **Shoot** — move your ship, aim your crosshair, fire up to 6 weapons simultaneously
- **Bounce** — bullets reflect off top/bottom walls; the entire pilot system is built around exploiting this
- **Build** — collect Energy gems to tier up weapons mid-level; spend Energy in the Pilot Academy between levels to acquire Pilot modifier cards, merge weapons, and upgrade ship stats
- **Run** — 3 Antes (~20–25 min). Each Ante is 3 levels, each ending with a boss. Clear all 3 Antes to complete a run

---

## Getting Started

**Requirements:** Godot 4.6 (Forward Plus renderer)

1. Clone the repo
2. Open `project.godot` in Godot 4.6
3. Press F5 or run from the editor — the game starts at the Main Menu

**Testing:** Uses the [GUT](https://github.com/bitwes/Gut) framework. Run tests from the Godot editor via the GUT panel, or via `addons/gut/gut_cmdln.gd`.

---

## Controls

| Action | Keyboard | Mouse | Gamepad |
|---|---|---|---|
| Move | WASD / Arrow keys | — | Left stick / D-pad |
| Aim | — | Mouse position | Right stick |
| Fire | Space | Left click | A button |

Weapons fire automatically on their own timers — there is no manual fire input in normal gameplay.

**Debug shortcuts (in-game):**
- `F5` — skip to boss fight (press again to skip boss → Pilot Academy)

---

## Run Structure

```
RUN (3 Antes)
├── ANTE 1
│     ├── Level 1 → Mini Boss → Pilot Academy
│     ├── Level 2 → Mini Boss → Pilot Academy
│     └── Level 3 → Big Boss → Pilot Academy → Ante 2
├── ANTE 2  (1.5× HP, 1.2× speed)
│     └── ...
└── ANTE 3  (2.5× HP, 1.4× speed)
      └── Level 3 → Big Boss → Pilot Academy → Run Complete
```

Antes 4–8 are meta-unlocked harder difficulties available in future runs.

---

## Core Systems

### Weapons

- Up to 6 slots fire simultaneously and independently on per-slot timers
- 4 weapon types: **ballistic**, **energy**, **missile**, **fire**
- Collecting Energy gems fills weapon XP bars. At threshold: game pauses, player chooses from 3 upgrade options (weapon tier-ups or stat boosts)
- Weapons can also be merged in the Pilot Academy: same type + same tier → next tier (costs Energy)
- Stats are data-driven from `data/weapons.json` (generated from `data/game_data.xlsx`). Tier scaling formula:

```
Tier Damage = Base Damage × (1 + DMG_Scale)^(tier - 1)
```

### Pilots

Pilots are Balatro-style Joker passives — permanent modifiers for the duration of a run, acquired between levels only (never mid-combat drops). Max 5 active.

Three types:

| Type | Scope | Example |
|---|---|---|
| Global | All weapons | Power Surge: +15% attack damage |
| Weapon Type | One category | Ballistic Expert: ×2 ballistic damage |
| Conditional | Trigger-based | Ricochet Artist: ×2 damage on bounced shots |

**Order of operations (fixed):**

```
(Base Damage + Ship Bonus + Pilot Flat) × Type Mult × Conditional Mult × Combo Mult
```

The HUD displays the live damage chain Balatro-style: `12 → ×2 → ×3 = 72`

Some pilot combinations trigger named **Combos** with bonus multipliers (e.g. The Infinite Bouncer).

### Energy Gems

Physical pickups dropped by enemies. Collected by moving over them.

- Fill weapon XP bars → trigger upgrade menu
- Accumulate as Pilot Academy currency

### Ships

5 ships currently available (8 total planned), each with 5 stats:

| Stat | Description |
|---|---|
| Hit Points | Total HP |
| Speed | Movement speed |
| Weapon Slots | Simultaneous weapons (up to 6) |
| Armour | Flat damage reduction per hit |
| Weapon Bonus | Flat addition to all weapon damage (feeds into pilot chain) |

Ships unlock permanently by completing Antes for the first time — no currency cost. Selected before each run via the Ship Select screen.

### Enemies

All enemies share a single `Enemy.gd` / `Enemy.tscn`. Behaviour is entirely data-driven from `data/enemies.json`:

- **Movement types:** straight, sine, swoop, zigzag, dart, homing, stationary
- **Shoot patterns:** none, aimed, spread

`EnemySpawner` picks enemies from a weighted pool via `EnemyDB.get_enemies_for_level(ante, level)` and spawns them in timed waves.

### Bosses

- **Mini Boss** — spawns after Level 1 and Level 2. State machine: ENTERING → PATROL → BURST_FIRE → CHARGE → RECOVER
- **Big Boss** — spawns after Level 3. Three phases with escalating attack patterns and visual tinting (burst → spread+charge → fan+rapid fire)

---

## Architecture

**Engine:** Godot 4.6 / GDScript, Forward Plus renderer, 1920×1080

**Pattern:** EventBus for all cross-system signals. No direct node references between systems.

### Autoloads

| Autoload | Role |
|---|---|
| `EventBus` | All signals (enemy_died, level_started, weapon_upgrade_available, etc.) |
| `GameManager` | XP, run state, level-up logic |
| `LevelManager` | Ante/level state machine, difficulty scaling, wave tracking |
| `WeaponDB` | Weapon definitions loaded from `data/weapons.json` |
| `EnemyDB` | Enemy definitions loaded from `data/enemies.json` |
| `PilotManager` | Pilot roster, damage chain calculation, combo detection |
| `ShipDB` | Ship definitions loaded from `data/ships.json` |

### Collision Layers

```
Layer 1 — Player
Layer 2 — Enemies
Layer 4 — Player bullets
Layer 8 — Enemy bullets
```

### Key Files

```
project.godot                   — Godot project config, autoloads, input map
DESIGN.md                       — Authoritative design spec (read before coding)
TODO.md                         — Development task list

data/
  game_data.xlsx                — Master data source (weapons, pilots, enemies, ships)
  weapons.json                  — Runtime weapon stats (generated from xlsx)
  pilots.json                   — Runtime pilot definitions (generated from xlsx)
  enemies.json                  — Runtime enemy definitions
  ships.json                    — Runtime ship definitions

scenes/
  ui/MainMenu.tscn              — Startup scene
  main.tscn                     — Root game scene
  ui/PilotAcademy.tscn          — Between-level upgrade screen
  ui/WeaponUpgradeUI.tscn       — In-level weapon tier-up choice
  enemies/Enemy.tscn            — Shared enemy scene (data-driven)
  background/parallax.tscn      — 3-layer scrolling background

scripts/
  player/Player.gd              — Movement, HP/shield, firing, weapon slots
  enemies/Enemy.gd              — All enemy logic (movement, shooting, death)
  enemies/EnemySpawner.gd       — Wave spawning
  systems/EventBus.gd           — All signals
  systems/GameManager.gd        — XP, leveling, run state
  systems/LevelManager.gd       — Ante/level state machine
  systems/PilotManager.gd       — Pilot roster, damage chain, combos
  systems/EnemyDB.gd            — Enemy data access
  systems/ShipDB.gd             — Ship data access
  weapons/WeaponDB.gd           — Weapon data + tier scaling
  ui/HUD.gd                     — HP/shield bars, weapon panels, damage chain
  ui/PilotAcademy.gd            — Academy UI (pilot offers, ship upgrades)
  ui/WeaponUpgradeUI.gd         — Weapon tier-up choice menu
  ui/MainMenu.gd                — Title screen, settings, pilot roster

assets/
  shaders/vignette.gdshader     — Radial vignette overlay shader
  backgrounds/                  — Parallax layer sprites
```

---

## Data Pipeline

All game content lives in `data/game_data.xlsx`. The JSON files in `data/` are exported from it and committed to the repo as the runtime source of truth. **Do not hardcode stats in scripts.**

Sheets in the xlsx:
- Weapon Base Stats, Tier Progression, Card Simulator
- Pilots, Card Combos, Rarity Distribution
- JSON Export Guide, Effect Key Reference, Balance Metrics

---

## Implementation Status

| Phase | Description | Status |
|---|---|---|
| Core Gameplay | Movement, shooting, enemies, collision | Complete |
| Progression | XP, level-up stat choices | Complete |
| Bounce Mechanic | Bullet wall reflection, bounce signals | Complete |
| Weapon System | 6 slots, 4 types, XP tier-up, weapon merge | Complete |
| Ante/Level Structure | State machine, waves, boss gating | Complete |
| Pilot Academy | Between-level screen, offers, ship upgrades | Complete |
| Pilot System | Damage chain, weighted offers, combos | Complete |
| Bosses | Mini Boss state machine, Big Boss 3-phase | Complete |
| Ship Selection | Ship select screen, armour, weapon bonus | Complete |
| Meta Progression / Save | Persistent unlocks | Pending |
| UI Redesign | HUD, upgrade menus, pause, game over | Pending |
| Polish | VFX, audio, balance | Pending |

---

## Reference Titles

| Game | Influence |
|---|---|
| Balatro | Order of operations, visible damage chain UI, ante loop |
| Brotato | Multi-weapon simultaneous firing, weapon category scaling |
| Vampire Survivors | XP-driven progression feel, wave escalation |

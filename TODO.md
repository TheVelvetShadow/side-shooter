# Space Shooter — Development TODO

> Cross-reference `DESIGN.md` for settled decisions. Do not deviate without flagging a conflict.

## How to use this file
- Move tasks IN PROGRESS when starting, DONE when complete
- Add notes/blockers inline

---

## 🔴 IN PROGRESS
_(nothing)_

---

## ✅ DESIGN CONFLICTS — RESOLVED

- [x] **Weapon slots: 2 → 4–6 simultaneous** — Player now has MAX_SLOTS=6, all fire independently via per-slot delta timers. `unlocked_slots` starts at 2, expandable.
- [x] **Weapon tier progression: duplicate pickup → XP-driven** — Single global weapon XP bar in GameManager. Threshold → player-choice upgrade menu. Threshold grows ×1.10 per upgrade.
- [x] **Weapon stats: hardcoded → data-driven** — `data/weapons.json` runtime source. WeaponDB loads JSON, scales via `base × (1 + dmg_scale)^(tier-1)`. Master data in `data/game_data.xlsx`.
- [x] **LevelUpUI / card conflation** — LevelUpUI = stat upgrades only. Pilots come from Pilot Academy.
- [x] **Weapon auto-tier → player-choice upgrade menu** — WeaponUpgradeUI pauses game, 3 options, player picks.
- [x] **Shop renamed → Pilot Academy** — Opens after every level (all 3 per ante).
- [x] **Boss every level** — L1 & L2 end with Mini Boss; L3 ends with Big Boss. Placeholders done.
- [x] **Currency: shop_energy → credits** — Gems fill weapon XP bar only. Credits = per-level wage.
- [x] **Weapon types: 4** — ballistic / energy / missile / fire. Fire Specialist pilot planned.
- [x] **Bullet visuals: future AnimatedSprite2D per weapon type** — Current ColorRect is placeholder. `bullet_scene` field to be added to game_data.xlsx when assets ready. No architectural changes needed.

---

## ✅ PHASE A — Bounce Mechanic — COMPLETE

- [x] Bullets bounce off top/bottom walls (reflect Y velocity)
- [x] `bounce_count` / `bounces_done` on Bullet
- [x] Bullets despawn after exceeding bounce_count
- [x] `EventBus.bullet_bounced(bullet, bounce_number)` signal
- [x] `bounce_damage_multiplier` stub — PilotManager populates this
- [x] Bullet uses `velocity: Vector2` (enables Y reflection)

---

## ✅ PHASE B — Ante / Level Structure — COMPLETE

- [x] LevelManager state machine: IDLE → PLAYING → CLEARING → BOSS_FIGHT → COMPLETE
- [x] 20 waves/level (12s apart), EnemySpawner stops on `waves_exhausted`
- [x] BOSS_FIGHT: spawned after all waves + enemies cleared; boss death → Pilot Academy
- [x] 3 levels per ante, ante_completed signal, difficulty scaling per ante
- [x] HUD: Ante/Level label + "LEVEL COMPLETE" overlay + Boss HP bar (top centre)
- [x] Level cleanup: "level_objects" group bulk-freed on `level_started`
- [x] Debug: F5 skips to boss fight; F5 again skips boss → Pilot Academy
- [x] Mini Boss placeholder (500 HP) after L1 & L2
- [x] Big Boss placeholder (2000 HP) after L3

---

## ✅ PHASE C — Pilot Academy — COMPLETE

- [x] Full-screen opaque academy screen after every level
- [x] `await EventBus.pilot_academy_closed` replaces 3-second placeholder
- [x] 3 random pilot card offers from PilotManager pool
- [x] 4 ship stat upgrade rows (HP / Speed / Weapon Slot / Dmg Bonus)
- [x] Credits display + continue button with contextual label
- [x] Active pilot roster shown at bottom
- [ ] Pilot swap — replace active pilot with offer (deferred to Phase D)
- [ ] Weapon merging — same type + tier → next tier, costs credits (deferred to Phase D)

---

## 📋 PHASE D — Pilot System (Full)

> 6 pilots implemented. Full 100+ pool, combos, and damage chain UI still pending.

### Data
- [x] `data/pilots.json` — 6 pilots (power_surge, shield_tech, ballistic_expert, energy_specialist, ricochet_artist, afterburner)
- [x] `data/game_data.xlsx` Pilots sheet — template ready, 6 existing + blank rows for 100+ target
- [ ] Fill pilot pool in game_data.xlsx → import to pilots.json (user fills spreadsheet first)
- [ ] Pilot rarity weights: Common 70% / Rare 25% / Epic 4.5% / Legendary 0.5%
- [ ] Fire Specialist pilot (weapon_type, fire category) — once fire weapon type implemented
- [ ] Pilot unlock tracking (meta-progression)

### Pilot Manager
- [x] `PilotManager` autoload — roster (max 5), apply_pilots(), get_bounce_multiplier(), add_pilot(), reset()
- [ ] Full order of ops: Flat → Type × → Conditional × → Combo ×
- [ ] Combo detection after every roster change

### Pilot Types
- [x] Global — power_surge, shield_tech, afterburner
- [x] Weapon Type — ballistic_expert, energy_specialist
- [x] Conditional — ricochet_artist (bounce ×2)
- [ ] Fire Specialist (weapon_type, fire)
- [ ] Combo pilots

### UI
- [x] Active pilot names shown in HUD
- [ ] **Damage chain UI** — `12 → ×2 (Ballistic) → ×3 (Bounce) = 72` shown per shot

---

## ✅ PHASE E+ — Energy Gem Pickup — COMPLETE

- [x] EnergyGem.tscn — drifts left, magnets to player at 250px
- [x] All enemies drop gems on death
- [x] `EventBus.energy_collected` → fills global weapon XP bar
- [x] Global XP bar in HUD (orange), triggers upgrade menu when full

---

## ✅ PHASE E — Weapon System — COMPLETE

- [x] `data/weapons.json` + WeaponDB — formula-based tier scaling
- [x] 6 slots (MAX_SLOTS=6), all fire simultaneously on independent timers
- [x] Global XP bar → weapon_upgrade_available → WeaponUpgradeUI (3 options)
- [x] HUD: 6 weapon panels with name + tier badge
- [ ] Per-weapon bullet scene (AnimatedSprite2D) — when assets ready, add `bullet_scene` to game_data.xlsx + wire WeaponDB

### 📋 New Weapon Systems Required
> Design complete in game_data.xlsx. Implement systems to unlock these weapons.

- [ ] **Heavy Machine Gun** — no new systems, add to weapons.json now
- [ ] **DOT / Burn** — on hit: apply burn timer, tick = hit_dmg × burn_pct; affects Energy Beam, Missile, Napalm, Nuke
- [ ] **AOE explosion** — on bullet death: damage all enemies in radius; affects Nuke, Cluster Bomb, Napalm
- [ ] **Homing** — bullet steers toward nearest enemy each frame; affects Homing Missile
- [ ] **Split / spawn children** — on trigger: spawn N child bullets at spread angle; affects Cluster Bomb, Nano Bots
- [ ] **Fire type** — 4th weapon type; Fire Specialist pilot; affects Napalm
- [ ] Weapon tier-up visual feedback — polish phase

---

## 📋 PHASE F — Boss Enemies (Placeholders Done)

> L1 & L2 → Mini Boss. L3 → Big Boss.

### ✅ Placeholders Done
- [x] MiniBoss.gd / MiniBoss.tscn — 500 HP, _draw() visuals, patrol, drops 6 gems
- [x] BigBoss.gd / BigBoss.tscn — 2000 HP, _draw() visuals, patrol, drops 16 gems
- [x] Boss HP bar in HUD, boss signals in EventBus, difficulty scaling on spawn

### 📋 Real Boss Designs
- [ ] Mini Boss attack pattern (burst fire / charge)
- [ ] Big Boss multi-phase attack pattern
- [ ] Boss 1: Fortress Station (Ante 1 L3)
- [ ] Boss 2: Battlecruiser (Ante 2 L3)
- [ ] Boss 3: Mothership (Ante 3 L3)
- [ ] 16× Mini Boss variants (L1 & L2 across 8 antes)
- [ ] Boss intro / death animations

---

## 📋 PHASE G — Ship Selection

- [ ] Ship selection screen before run
- [ ] Ship stats: HP, speed, weapon slots, armour, weapon bonus
- [ ] Ship 1 — Interceptor (starter)
- [ ] Ships 2–8 — meta unlocks (Tank, Glass Cannon, Scout, Dreadnought, TBD ×3)
- [ ] Ship weapon bonus → damage formula (flat add before pilot multipliers)

---

## 📋 PHASE H — Meta Progression

> Not a priority until core loop is complete.

- [ ] Pilot Academy hub (between runs)
- [ ] Save system — XP, unlocks persist (Godot ResourceSaver)
- [ ] Ship / weapon / pilot unlock systems
- [ ] Permanent stat upgrades (minor)

---

## 📋 PHASE I — Polish

- [ ] Visual effects — explosions, bullet trails, bounce flash, burn particles
- [ ] Per-weapon AnimatedSprite2D bullets (coordinate with assets)
- [ ] Audio — music, SFX per weapon type, SFX on pilot trigger
- [ ] Main menu
- [ ] Tutorial / onboarding
- [ ] Balance pass — use Card Simulator sheet in game_data.xlsx
- [ ] Achievement system

---

## ✅ DONE

### Project Setup
- [x] Project setup, GUT testing framework, EventBus, GameManager, WeaponDB, LevelManager, PilotManager autoloads

### Phase 1 — Core Gameplay ✅
- [x] Ship movement (WASD + gamepad), crosshair aiming (mouse + gamepad)
- [x] Firing toward crosshair, fire rate timer, HP/Shield system
- [x] 3 enemy types, enemy spawner (3 wave patterns), XP drops
- [x] Bullet collision, enemy bullets, player death → game over

### Phase 2 — Progression ✅
- [x] XP tracking, ship level-up, LevelUpUI (3 stat choices), apply_upgrade()

### Phase 3 — Weapons (reworked as Phase E) ✅
- [x] WeaponDB (3 types, data-driven), WeaponPickup, 30% drop rate

### Phase 7 — Polish (partial)
- [x] Scrolling parallax background, HP/Shield/XP bars, game over screen

---

## 🐛 KNOWN BUGS / BLOCKERS
- [ ] 2193 debug notices on startup — investigate source
- [ ] Shift key weapon slot switch — remove once all slots fire simultaneously by default

---

## 📝 NOTES & DECISIONS
- Weapons tier up via global XP bar → player-choice menu (not duplicate collection)
- Pilots: Global / Type / Conditional / Combo — Joker-style passives only
- Order of ops: Flat → Type × → Conditional × → Combo ×
- 4 weapon types: ballistic / energy / missile / fire
- Bounce is a base mechanic — not a pilot unlock
- Damage chain UI (Balatro-style) is core dopamine loop — high priority in Phase D
- All weapon, pilot, ship data in `data/game_data.xlsx` — never hardcode stats
- `data/weapons.json` and `data/pilots.json` are runtime files generated from xlsx
- Energy gems → weapon XP bar only. Credits = per-level wage → Pilot Academy spend
- 8 ships, 100+ pilots, all unlocked via meta-progression

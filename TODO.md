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
- [x] **Weapon tier progression: duplicate pickup → XP-driven** — Single global weapon XP bar in GameManager (filled by energy gems). Threshold → player-choice upgrade menu. Threshold grows ×1.10 per upgrade.
- [x] **Weapon stats: hardcoded → data-driven** — `data/weapons.json` is source of truth. WeaponDB loads JSON, scales via formula `base × (1 + dmg_scale)^(tier-1)`. Update JSON from xlsx when ready.
- [x] **LevelUpUI / card conflation** — Clarified: LevelUpUI = stat upgrades only. Pilots come from Pilot Academy (Phase C).
- [x] **Weapon auto-tier → player-choice upgrade menu** — WeaponUpgradeUI pauses game and shows 3 options. Player picks → `upgrade_weapon_choice(slot)` applies tier-up.
- [x] **Shop renamed → Pilot Academy** — Appears after every level (all 3), not just between levels.
- [x] **Boss every level** — L1 & L2 end with Mini Boss; L3 ends with Big Boss. Placeholder bosses implemented (Phase F).
- [x] **Currency: shop_energy → credits** — Energy gems fill weapon XP bar only. Credits are earned as a wage at end of each level (`50 + (ante-1)×15 + (level-1)×5`) and spent in Pilot Academy.

---

## ✅ PHASE A — Bounce Mechanic (Core Identity) — COMPLETE

> "Bounce is a base mechanic, not a pilot unlock." — DESIGN.md §10

- [x] Bullets bounce off top and bottom viewport walls (reflect Y velocity)
- [x] Bullets despawn on left wall exit (already works — off-screen check)
- [x] `bounce_count` property on Bullet (starts at 1 by default)
- [x] Bullet tracks how many times it has bounced (`bounces_done`)
- [x] Bullets despawn after exceeding bounce_count
- [x] `EventBus.bullet_bounced(bullet, bounce_number)` emitted on each bounce
- [x] `bounce_damage_multiplier` stub on Bullet — PilotManager populates this
- [x] Bullet switched to `velocity: Vector2` (was scalar speed) — enables Y reflection

---

## ✅ PHASE B — Ante / Level Structure — COMPLETE

- [x] `LevelManager` autoload — state machine: IDLE → PLAYING → CLEARING → BOSS_FIGHT → COMPLETE
- [x] Finite waves: 20 waves/level (12s apart), EnemySpawner stops on `waves_exhausted`, restarts on `level_started`
- [x] Level completion: `active_enemies` tracked via `enemy_spawned`/`enemy_died`; clears → boss fight → completes
- [x] Ante progression: 3 levels per ante, `ante_completed` signal, ante counter increments
- [x] Difficulty scaling: HP/speed multipliers per ante applied to each enemy on spawn
- [x] HUD: Ante/Level label + "LEVEL COMPLETE" overlay
- [x] Level cleanup: all transient nodes (enemies, gems, bullets, pickups) added to "level_objects" group → bulk-freed on `level_started`
- [x] Debug skip: F5 in debug build skips to boss fight; F5 again skips boss → Pilot Academy
- [x] Mini Boss placeholder after L1 & L2 (see Phase F)
- [x] Big Boss placeholder after L3 (see Phase F)

---

## ✅ PHASE C — Pilot Academy Scene — COMPLETE

> "The Pilot Academy opens after every level." — DESIGN.md §2 (revised)

- [x] `PilotAcademy.tscn` + `PilotAcademy.gd` — full-screen opaque dark navy screen after every level
- [x] Replaces 3-second auto-advance placeholder in LevelManager (`await EventBus.pilot_academy_closed`)
- [x] Shows 3 random pilot card offers (from PilotManager.get_available_pilots(), shuffled)
- [x] Ship stat upgrades — 4 fixed rows: +20 HP / +30 Speed / +1 Weapon Slot / +10% Dmg Bonus
- [x] "Continue →" / "Enter Level N →" / "Ante N Complete →" button resumes play
- [x] Funded by credits (per-level wage, not energy gems)
- [x] Active pilot roster shown at bottom of Academy screen
- [x] Credits display in Academy header
- [ ] Pilot swap — replace active pilot with Academy offer (deferred to Phase D)
- [ ] Weapon merging — same type + same tier → next tier, costs credits (deferred to Phase D)

---

## ✅ PHASE D (partial) — Pilot System — IN PROGRESS

> Pilots are Joker-style passives. 6 real pilots implemented. Full 100+ pool is Phase D proper.

### Data ✅
- [x] `data/pilots.json` — 6 pilot definitions (power_surge, shield_tech, ballistic_expert, energy_specialist, ricochet_artist, afterburner)
- [x] Pilot data structure: id, name, type, rarity, cost, desc, effect, value, optional weapon_category
- [ ] Full pilot database from `Card_Database_Spreadsheet.xlsx` — 100+ pilots target
- [ ] Pilot rarity weights: Common 70% / Rare 25% / Epic 4.5% / Legendary 0.5%
- [ ] Pilot unlock tracking (starts small, grows with meta-progression)

### Pilot Manager ✅
- [x] `PilotManager` autoload — holds active roster (max 5), evaluates effects
- [x] `apply_pilots(base_damage, weapon_type)` — flat % then type multipliers
- [x] `get_bounce_multiplier()` — returns product of all bounce_mult pilots
- [x] `add_pilot(pilot_data, player)` — appends to roster, applies one-time stat effects
- [x] `reset()` — called on run start via GameManager.start_run()
- [ ] Combo detection — check active roster against named combo triggers after every change
- [ ] `apply_pilots` with full order of ops: Flat → Type × → Conditional × → Combo ×

### Pilot Types (partial)
- [x] Global pilots — power_surge (+20% dmg), shield_tech (+25 shield), afterburner (+40 speed)
- [x] Weapon Type pilots — ballistic_expert (×1.5 ballistic), energy_specialist (×1.5 energy)
- [x] Conditional pilots — ricochet_artist (×2 on bounced shots)
- [ ] Combo pilots — named multi-pilot combinations (deferred)

### UI
- [x] Active pilot display in HUD (up to 5 slots, names shown)
- [ ] **Damage chain UI** — show running multiplication per shot: `12 → ×2 (Ballistic) → ×3 (Bounce) = 72`

---

## ✅ PHASE E+ — Energy Gem Pickup — COMPLETE

- [x] `scenes/pickups/EnergyGem.tscn` — pulsing diamond, drifts left, magnets to player at 250px range
- [x] Gem carries `xp_value` + `source_weapon_slot` from the kill shot
- [x] All 3 enemy types drop a gem on death (always), passing source_slot through take_damage → die
- [x] Bounce multiplier applied in KamikazeDrone and TurretPlatform area_entered handlers
- [x] `EventBus.energy_collected(amount, weapon_slot)` — fills global weapon XP bar in GameManager
- [x] Global weapon XP bar in HUD (orange, labeled "XP N/N"), triggers upgrade menu when full

---

## ✅ PHASE E — Weapon System Rework — COMPLETE

- [x] `data/weapons.json` — weapon base stats + scale % (replace hardcoded WeaponDB)
- [x] WeaponDB loads from JSON, formula-based tier scaling
- [x] 6 weapon slots (MAX_SLOTS=6), all fire simultaneously on independent delta timers
- [x] Global weapon XP bar — fills from energy gems, triggers `weapon_upgrade_available` when full, threshold ×1.10 per upgrade, resets between levels
- [x] `WeaponUpgradeUI` — pauses game, shows 3 options, player picks → `upgrade_weapon_choice(slot)`
- [x] `EventBus.weapon_upgrade_available` + `weapon_upgrade_chosen` signals added
- [x] HUD: 6 weapon panels built dynamically, each with name label + tier badge
- [x] Removed duplicate-pickup merge mechanic
- [ ] Weapon tier-up visual feedback (flash/particle) — polish phase

### 📋 New Weapon Systems Required
> Weapons designed in game_data.xlsx — implement systems below before those weapons can go live

- [ ] **DOT / Burn system** — on hit, apply burn timer to enemy; tick damage = hit_damage × burn_pct; affects: Energy Beam, Missile, Napalm, Nuke
- [ ] **AOE explosion** — on bullet death, damage all enemies within radius; affects: Nuke, Cluster Bomb, Napalm
- [ ] **Homing system** — bullet steers toward nearest enemy each frame; affects: Homing Missile
- [ ] **Split / spawn children** — on trigger (impact/expiry/bounce), spawn N child bullets at spread angle; affects: Cluster Bomb, Nano Bots
- [ ] **Fire weapon type** — 4th type alongside ballistic/energy/missile; Fire Specialist pilot needed; affects: Napalm

### 📋 Weapons Designed (game_data.xlsx) — Pending Implementation
- [ ] Heavy Machine Gun (ballistic — straightforward, no new systems)
- [ ] Homing Missile (needs homing system)
- [ ] Napalm (needs DOT + AOE + fire type)
- [ ] Nuke (needs DOT + AOE)
- [ ] Cluster Bomb (needs split system)
- [ ] Nano Bots (needs split system — values incomplete in spreadsheet)

---

## 📋 PHASE F — Boss Enemies (Placeholders Done, Full Implementation Pending)

> Required for every level: L1 & L2 end with Mini Boss; L3 ends with Big Boss.

### ✅ Done
- [x] `MiniBoss.gd` / `MiniBoss.tscn` — 500 HP, programmatic _draw() visuals (orange), slides in from right, up/down patrol, drops 6 gems
- [x] `BigBoss.gd` / `BigBoss.tscn` — 2000 HP, programmatic _draw() visuals (purple), same entry pattern, drops 16 gems
- [x] Boss HP bar in HUD — top-center, shows name + red bar on `boss_spawned`, hides on next level
- [x] `EventBus.boss_spawned(boss_name, max_hp)` and `boss_hp_changed(current, maximum)` signals
- [x] BOSS_FIGHT state in LevelManager — spawned after all waves + regular enemies cleared; boss death → Pilot Academy
- [x] Difficulty scaling applied to boss HP and speed on spawn

### 📋 Remaining (real boss designs)
- [ ] Mini Boss real attack pattern (e.g. burst fire, charge)
- [ ] Big Boss real attack pattern (multi-phase)
- [ ] Small Boss variant 1 — Ante 1 L1 & L2 named design
- [ ] Boss 1: Fortress Station (Ante 1 L3)
- [ ] Boss 2: Battlecruiser (Ante 2 L3)
- [ ] Boss 3: Mothership (Ante 3 L3)
- [ ] Boss intro / death animations
- [ ] 16× Mini Boss variants (one per L1 & L2 across 8 antes)

---

## 📋 PHASE G — Ship Selection

- [ ] Ship selection screen before run starts
- [ ] Ship stats system: HP, speed, weapon slots, armour, weapon bonus (flat dmg addition)
- [ ] Ship 1 — Interceptor (starter, always available)
- [ ] Ship 2 — Tank (high HP, high armour, low speed) — meta unlock
- [ ] Ship 3 — Glass Cannon (high weapon bonus, low HP) — meta unlock
- [ ] Ship 4 — Scout (high speed, dodge-focused) — meta unlock
- [ ] Ship 5 — Dreadnought (max weapon slots, slow) — meta unlock
- [ ] Ships 6–8 — TBD — meta unlock
- [ ] Ship weapon bonus feeds into damage formula (flat add before pilot multipliers)

---

## 📋 PHASE H — Meta Progression (Pilot Academy Hub)

> "Not a priority until core gameplay loop is complete." — DESIGN.md §8

- [ ] Pilot Academy hub scene (between runs)
- [ ] XP persists between runs (save system — Godot ResourceSaver)
- [ ] Ship unlock system (7 ships to unlock beyond Interceptor)
- [ ] Weapon type unlock system
- [ ] Pilot unlock system (100+ pilots unlocked progressively)
- [ ] Permanent ship stat upgrades (small, not run-defining)
- [ ] Unlock tracking persists to disk — save/load on Academy open

---

## 📋 PHASE I — Polish

- [ ] Visual effects — explosions, bullet trails, bounce flash
- [ ] Audio — music, SFX per weapon type, SFX on pilot trigger
- [ ] Main menu
- [ ] Tutorial / onboarding
- [ ] Balance pass — use Card Simulator sheet in weapons_prototype.xlsx
- [ ] Achievement system
- [ ] Weapon tier-up visual feedback (flash/particle)

---

## ✅ DONE

### Project Setup
- [x] Project setup and folder structure
- [x] GUT testing framework installed
- [x] EventBus.gd (signal system)
- [x] GameManager.gd (global state)
- [x] Autoloads configured (EventBus, GameManager, WeaponDB, LevelManager, PilotManager)

### Phase 1 — Core Gameplay ✅ COMPLETE
- [x] Ship movement (WASD + gamepad)
- [x] Crosshair aiming (mouse + gamepad right stick)
- [x] Firing mechanic toward crosshair with fire rate timer
- [x] HP / Shield system with damage absorption
- [x] Death signal + game over screen
- [x] Screen boundary clamping
- [x] Bullet scene + script (Bullet.tscn / Bullet.gd)
- [x] Enemy 1 — Scout Fighter (wave movement)
- [x] Enemy 2 — Kamikaze Drone (homing)
- [x] Enemy 3 — Turret Platform (fires enemy bullets)
- [x] Enemy spawner (wave patterns: flock / kamikaze rush / turret line)
- [x] Enemy drops XP on death
- [x] Bullet collision with enemies
- [x] Enemy bullets damage player
- [x] Player death → game over

### Phase 2 — Progression ✅ COMPLETE
- [x] XP drops from enemies, tracked in GameManager (run_xp, ship_xp)
- [x] Ship levels up at XP thresholds
- [x] LevelUpUI — pauses game, offers 3 stat upgrade choices (HP / Shield / Attack / Speed)
- [x] apply_upgrade() on Player applies chosen stat

### Phase 3 — Weapons (partial — reworked as Phase E)
- [x] WeaponDB autoload — 3 types (Ballistic/Energy/Missile), 5-tier scaling (data-driven from JSON)
- [x] WeaponPickup.tscn — diamond pickup, drifts left, collected on player overlap
- [x] 30% weapon drop on enemy death
- [x] Bullet color + speed driven by active weapon

### Phase 7 — Polish (partial)
- [x] Scrolling parallax background
- [x] HP/Shield bars, score display, XP bar
- [x] Game over screen with score + best score + restart

---

## 🐛 KNOWN BUGS / BLOCKERS
- [ ] 2193 debug notices on startup — investigate source
- [ ] Weapon slot switch (Shift) conflicts with design intent — remove once all slots fire simultaneously by default

---

## 📝 NOTES & DECISIONS (from DESIGN.md §10)
- Weapons tier up via global XP bar → player-choice upgrade menu (not duplicate collection)
- **"Cards" are called Pilots** — Global / Type / Conditional — same mechanics, lore rename
- Order of operations: Flat (incl. ship weapon bonus) → Type × → Conditional × → Combo ×
- 4–6 simultaneous weapon slots (determined by ship's weapon slot stat)
- Ante structure: 3 levels per ante, Pilot Academy between each, boss at end of every level
- Bounce is a base mechanic — not a pilot unlock
- Bounce-conditional pilots are a design priority and unique game identity
- Pilot UI must show damage chain visibly (Balatro-style running total)
- Weapon, pilot, and ship data lives in spreadsheets — do not hardcode
- Energy gems mid-run → fill weapon XP bar only (not credits)
- Credits = per-level wage → spent in Pilot Academy on pilots and ship upgrades
- Ships, weapons, and pilots all unlocked via Pilot Academy meta-progression
- 8 ships total, 100+ pilots total

# Space Shooter — Development TODO

> Cross-reference `DESIGN.md` for settled decisions. Do not deviate without flagging a conflict.

## How to use this file
- Move tasks IN PROGRESS when starting, DONE when complete
- Add notes/blockers inline

---

## 🔴 IN PROGRESS
_(nothing — assess design gaps before picking next task)_

---

## ✅ DESIGN CONFLICTS — RESOLVED

- [x] **Weapon slots: 2 → 4–6 simultaneous** — Player now has MAX_SLOTS=6, all fire independently via per-slot delta timers. `unlocked_slots` starts at 2, expandable.
- [x] **Weapon tier progression: duplicate pickup → XP-driven** — Per-slot `weapon_xp[]` tracking. Bullets carry `weapon_slot`, emit `weapon_xp_gained` on kill. Tier-up auto on threshold.
- [x] **Weapon stats: hardcoded → data-driven** — `data/weapons.json` is source of truth. WeaponDB loads JSON, scales via formula `base × (1 + dmg_scale)^(tier-1)`. Update JSON from xlsx when ready.
- [x] **LevelUpUI / card conflation** — Clarified: LevelUpUI = stat upgrades only. Pilots come from Shop (Phase C).

---

## ✅ PHASE A — Bounce Mechanic (Core Identity) — COMPLETE

> "Bounce is a base mechanic, not a pilot unlock." — DESIGN.md §10

- [x] Bullets bounce off top and bottom viewport walls (reflect Y velocity)
- [x] Bullets despawn on left wall exit (already works — off-screen check)
- [x] `bounce_count` property on Bullet (starts at 1 by default)
- [x] Bullet tracks how many times it has bounced (`bounces_done`)
- [x] Bullets despawn after exceeding bounce_count
- [x] `EventBus.bullet_bounced(bullet, bounce_number)` emitted on each bounce
- [x] `bounce_damage_multiplier` stub on Bullet — PilotManager will populate this
- [x] Bullet switched to `velocity: Vector2` (was scalar speed) — enables Y reflection

---

## ✅ PHASE B — Ante / Level Structure — COMPLETE

- [x] `LevelManager` autoload — state machine: IDLE → PLAYING → CLEARING → COMPLETE
- [x] Finite waves: 4 waves/level, EnemySpawner stops on `waves_exhausted`, restarts on `level_started`
- [x] Level completion: `active_enemies` tracked via `enemy_spawned`/`enemy_died`; completes when CLEARING + 0 enemies
- [x] Ante progression: 3 levels per ante, `ante_completed` signal, ante counter increments
- [x] Difficulty scaling: HP/speed multipliers per ante applied to each enemy on spawn
- [x] HUD: Ante/Level label + "LEVEL COMPLETE" overlay
- [x] 3-second auto-advance placeholder (replaced by Shop in Phase C)
- [ ] Boss at Ante end (Phase F)

---

## 📋 PHASE C — Shop Scene

> "The shop appears between every level." — DESIGN.md §2

- [ ] `Shop.tscn` scene — appears between levels
- [ ] Shop offers 3–5 cards to buy (drawn from card pool by rarity)
- [ ] Card swap — player can replace an active card with a shop card
- [ ] Shop also offers weapon slot unlocks (up to 6 slots)
- [ ] Skip button to proceed without buying
- [ ] Shop funded by run XP / currency (design TBD — flag if needed)

---

## 📋 PHASE D — Pilot System (Full)

> "Cards" are called Pilots for lore reasons — same architecture, different name. See DESIGN.md §4. Pilots come from the shop only, never mid-run drops.

### Data
- [ ] Pilot data structure — id, name, type (global/weapon_type/conditional), rarity, effect params
- [ ] Pilot database loaded from `Card_Database_Spreadsheet.xlsx` (rename to `Pilot_Database_Spreadsheet.xlsx`, CSV export) — 6 pilots designed so far, target 100+
- [ ] Pilot rarity weights: Common 70% / Rare 25% / Epic 4.5% / Legendary 0.5%
- [ ] Pilot unlock tracking — which pilots are available in the current run's pool (starts small, grows with Pilot Academy unlocks)

### Pilot Manager
- [ ] `PilotManager` autoload — holds active pilot roster (max ~5), evaluates effects
- [ ] `apply_pilots(base_damage, weapon_type, trigger_context)` → returns final damage
- [ ] Order of operations (fixed, per DESIGN.md §4.4):
  1. Base damage (weapon tier stat + ship weapon bonus)
  2. + Flat additions (global stat pilots)
  3. × Type multiplier (weapon category pilots)
  4. × Conditional multiplier (trigger pilots — bounce, pierce, etc.)
  5. × Combo bonus (named combos)
- [ ] Pilot acquisition adds pilot to active roster; triggers combo detection
- [ ] Combo detection: check active roster against combo trigger conditions after every change

### Pilot Types
- [ ] **Global pilots** — e.g. "Power Surge: +15% all damage" (always useful, baseline)
- [ ] **Weapon Type pilots** — e.g. "Ballistic ×2 Damage" (build-shapers, reward category commitment)
- [ ] **Conditional pilots** — trigger-based, e.g. "×3 damage on bounced shots" (unique to this game — highest priority to design)
- [ ] **Combo pilots** — named multi-pilot combinations with bonus multiplier (tracked in Card Combos sheet)

### UI
- [ ] Active pilot display (up to 5 pilots shown on HUD)
- [ ] **Damage chain UI** — when a shot fires, show running multiplication: `12 → ×2 (Ballistic) → ×3 (Bounce) = 72` (Balatro-style — this is the core dopamine loop)

---

## ✅ PHASE E — Weapon System Rework — COMPLETE

- [x] `data/weapons.json` — weapon base stats + scale % (replace hardcoded WeaponDB)
- [x] WeaponDB loads from JSON, formula-based tier scaling
- [x] 6 weapon slots (MAX_SLOTS=6), all fire simultaneously on independent delta timers
- [x] Per-slot weapon XP — bullets carry weapon_slot, emit weapon_xp_gained on kill
- [x] Auto tier-up at XP thresholds, weapon_tiered_up signal emitted
- [x] HUD: 6 weapon panels built dynamically, each with name label + XP progress bar
- [x] Removed duplicate-pickup merge mechanic
- [ ] Weapon tier-up visual feedback (flash/particle) — polish phase

---

## 📋 PHASE F — Boss Enemies

- [ ] Boss base class — high HP, multiple attack phases
- [ ] Boss 1: Fortress Station (Ante 1 finale)
- [ ] Boss 2: Battlecruiser (Ante 2 finale)
- [ ] Boss 3: Mothership (Ante 3 finale)
- [ ] Boss health bar HUD element
- [ ] Boss death → ante clear → unlock next ante

---

## 📋 PHASE G — Ship Selection

- [ ] Ship selection screen before run starts
- [ ] Ship stats system: HP, speed, weapon slots, armour, weapon bonus (flat dmg addition)
- [ ] Ship 1 — Interceptor (starter, always available)
- [ ] Ship 2 — Tank (high HP, high armour, low speed) — Pilot Academy unlock
- [ ] Ship 3 — Glass Cannon (high weapon bonus, low HP) — Pilot Academy unlock
- [ ] Ship 4 — Scout (high speed, dodge-focused) — Pilot Academy unlock
- [ ] Ship 5 — Dreadnought (max weapon slots, slow) — Pilot Academy unlock
- [ ] Ship 6 — TBD — Pilot Academy unlock
- [ ] Ship 7 — TBD — Pilot Academy unlock
- [ ] Ship 8 — TBD — Pilot Academy unlock
- [ ] Ship weapon bonus feeds into damage formula (flat add before pilot multipliers)

---

## 📋 PHASE H — Meta Progression (Pilot Academy)

> "Not a priority until core gameplay loop is complete." — DESIGN.md §8

- [ ] Pilot Academy hub scene (between runs)
- [ ] XP persists between runs (save system — Godot ResourceSaver)
- [ ] Ship unlock system (7 ships to unlock beyond Interceptor)
- [ ] Weapon type unlock system (weapons locked until unlocked; locked weapons cannot appear in runs)
- [ ] Pilot unlock system (100+ pilots unlocked progressively; unlocked pilots added to run pool)
- [ ] Permanent ship stat upgrades (small, not run-defining)
- [ ] Unlock tracking persists to disk — save/load on Academy open

---

## 📋 PHASE I — Polish

- [ ] Visual effects — explosions, bullet trails, bounce flash
- [ ] Audio — music, SFX per weapon type, SFX on card trigger
- [ ] Main menu
- [ ] Tutorial / onboarding
- [ ] Balance pass — use Card Simulator sheet in weapons_prototype.xlsx
- [ ] Achievement system

---

## ✅ DONE

### Project Setup
- [x] Project setup and folder structure
- [x] GUT testing framework installed
- [x] EventBus.gd (signal system)
- [x] GameManager.gd (global state)
- [x] Autoloads configured (EventBus, GameManager, WeaponDB)

### Phase 1 — Core Gameplay ✅ COMPLETE
- [x] Ship movement (WASD)
- [x] Firing mechanic with fire rate timer
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

### Phase 2 — Progression ✅ COMPLETE (stat upgrades — see conflict note on cards)
- [x] XP drops from enemies, tracked in GameManager (run_xp, ship_xp)
- [x] Ship levels up at XP thresholds
- [x] LevelUpUI — pauses game, offers 3 stat upgrade choices (HP / Shield / Attack / Speed)
- [x] apply_upgrade() on Player applies chosen stat

### Phase 3 — Weapons (partial — see ⚠️ conflicts above)
- [x] WeaponDB autoload — 3 types (Ballistic/Energy/Missile), 5-tier scaling (hardcoded — needs fix)
- [x] WeaponPickup.tscn — diamond pickup, drifts left, collected on player overlap
- [x] 30% weapon drop on enemy death (all 3 enemy types)
- [x] Bullet color + speed driven by active weapon
- [x] EventBus: weapon_equipped, weapon_slot_switched, upgrade_chosen signals
- [x] HUD weapon slot display, upgrade card slots, XP bar + level label

### Phase 7 — Polish (partial)
- [x] Scrolling parallax background
- [x] HP/Shield bars, score display, XP bar
- [x] Game over screen with score + best score + restart

---

## 🐛 KNOWN BUGS / BLOCKERS
- [ ] 2193 debug notices on startup — investigate source
- [ ] Weapon slot switch (Shift) conflicts with design intent — Shift should not be needed once all slots fire simultaneously

---

## 📝 NOTES & DECISIONS (from DESIGN.md §10)
- Weapons tier up via XP thresholds — not duplicate collection
- **"Cards" are called Pilots** — Global / Type / Conditional — same mechanics, lore rename
- Order of operations: Flat (incl. ship weapon bonus) → Type × → Conditional × → Combo ×
- 4–6 simultaneous weapon slots (determined by ship's weapon slot stat)
- Ante structure: 3 levels per ante, shop between each, boss at end
- Bounce is a base mechanic — not a pilot unlock
- Bounce-conditional pilots are a design priority and unique game identity
- Pilot UI must show damage chain visibly (Balatro-style running total)
- Weapon, pilot, and ship data lives in spreadsheets — do not hardcode
- XP gems mid-run → spend on weapon tier upgrades OR ship stat upgrades (run-scoped only)
- Ships, weapons, and pilots all unlocked via Pilot Academy meta-progression
- 8 ships total, 100+ pilots total

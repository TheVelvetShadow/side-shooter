# Space Shooter — Development TODO

> Cross-reference `DESIGN.md` for settled decisions. Do not deviate without flagging a conflict.

## How to use this file
- Move tasks IN PROGRESS when starting, DONE when complete
- Add notes/blockers inline

---

## 🔴 IN PROGRESS

### 🗂 game_data.xlsx — FILLING IN PROGRESS (user)
All of the below is blocked on spreadsheet completion:
- [ ] **Weapon merge table** — which weapon + weapon → new weapon (new weapon types/tiers unlocked via merging)
- [ ] **Pilot pool** — 100+ pilots across all rarities, types, effects
- [ ] **Enemy roster** — all enemy types with stats, movement, shoot patterns, spawn weights, per-ante availability
- [ ] **Level composition** — which enemies appear in which ante/level, wave counts, difficulty curve
- [ ] **Boss designs** — 3 Big Boss variants (Fortress Station, Battlecruiser, Mothership) + 16 Mini Boss variants

### 🎨 UI Redesign — NEXT UP
Design confirmed (Classic layout). All builds pending:
- [ ] **HUD redesign** — HP/shield top-left with styled bars, boss bar top-centre (wider/dramatic), weapon slots bottom strip, pilot tags below HP bars, damage chain top-right
- [ ] **WeaponUpgradeUI redesign** — fully programmatic rebuild; larger cards with type-colour header, icon area, name/desc/stat rows
- [ ] **LevelUpUI redesign** — same treatment as WeaponUpgradeUI
- [ ] **Pause menu** — new; ESC key; Resume / Settings / Quit to Menu; process_mode=ALWAYS
- [ ] **Game Over screen redesign** — full-screen THE VOID aesthetic, score, run stats
- [ ] **Run summary screen** — new; shown after clearing all 3 antes

### 🔍 Content audit — planned after spreadsheet
Go through each entity one by one to verify correct visuals, animations, movement, spawning:
- [ ] Each enemy type — movement, attack pattern, sprite/visual, spawn behaviour
- [ ] Each weapon — stats, bullet visual, fire pattern, special behaviour (AOE, homing, burn, split)
- [ ] Each ship — portrait, stats correct, armour/bonus working
- [ ] Each boss — phases, attack patterns, visual, entry/death

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
- [x] Pilot swap — "Swap" button when roster full; overlay shows active roster to replace
- [ ] Weapon merging — blocked on game_data.xlsx merge table (which weapons combine into which new weapons)

---

## 📋 PHASE D — Pilot System (Full)

> 8 pilots implemented. Full 100+ pool still pending (user fills spreadsheet). Combos and damage chain UI complete.

### Data
- [x] `data/pilots.json` — 8 pilots (power_surge, shield_tech, ballistic_expert, energy_specialist, fire_specialist, ricochet_artist, bounce_master, afterburner)
- [x] `data/game_data.xlsx` Pilots sheet — template ready, 6 existing + blank rows for 100+ target
- [ ] Fill pilot pool in game_data.xlsx → import to pilots.json (user fills spreadsheet first)
- [x] Pilot rarity weights: Common 70% / Rare 25% / Epic 4.5% / Legendary 0.5%
- [x] Fire Specialist pilot — weapon_type / fire / rare / ×1.5
- [ ] Pilot unlock tracking (meta-progression — deferred to Phase H)

### Pilot Manager
- [x] `PilotManager` autoload — roster (max 5), apply_pilots(), get_bounce_multiplier(), add_pilot(), reset()
- [x] Full order of ops: Flat → Type × → Conditional × → Combo × (combo stub, no combos defined yet)
- [x] get_damage_chain() returns step-by-step chain dict; get_bounce_chain_steps() appends at hit time
- [x] get_weighted_offers(n) — rarity-weighted sampling (common 70 / rare 25 / epic 4.5 / legendary 0.5)
- [x] replace_pilot(index, new_pilot, player) — for swap in Academy
- [x] Combo detection after every roster change (active_combos updated on add/replace/reset)

### Pilot Types
- [x] Global — power_surge, shield_tech, afterburner
- [x] Weapon Type — ballistic_expert, energy_specialist, fire_specialist
- [x] Conditional — ricochet_artist (bounce ×2), bounce_master (bounce ×3)
- [x] Combo — The Infinite Bouncer (ricochet_artist + bounce_master → ×1.5 extra on bounced shots)

### UI
- [x] Active pilot names shown in HUD
- [x] **Damage chain UI** — `10 → +20% (Power Surge) → ×1.5 (Ballistic Expert) = 18` top-right HUD, fades after 2s
- [x] Pilot portrait images on Academy cards (Pilot_1/2/3.png by rarity)
- [x] Pilot swap — "Swap" button when roster full; overlay shows active roster to replace

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

- [x] **Heavy Machine Gun** — added to weapons.json (ballistic, dmg 14, rate 0.25, speed 700, silver)
- [x] **DOT / Burn** — BurnComponent dynamically attached on hit; ticks hit_dmg × burn_pct every 0.5s; orange tint visual; Energy Beam (10%/1s) + Missile (2%/1s) live now
- [x] **AOE explosion** — ExplosionEffect visual (expanding ring); damage falloff 100%→50% from centre to edge; burn applied to all AOE targets; Energy (80px), Missile (120px), Nuke (350px) live now
- [x] **Homing** — bullet steers toward nearest enemy each frame; affects Homing Missile
- [x] **Split / spawn children** — on trigger: spawn N child bullets at spread angle; affects Cluster Bomb, Nano Bots
- [x] **Fire type** — 4th weapon type; Napalm weapon live; Fire Specialist pilot deferred to Phase D
- [ ] Weapon tier-up visual feedback — polish phase

---

## 📋 PHASE F — Boss Enemies (Placeholders Done)

> L1 & L2 → Mini Boss. L3 → Big Boss.

### ✅ Placeholders Done
- [x] MiniBoss.gd / MiniBoss.tscn — 500 HP, _draw() visuals, patrol, drops 6 gems
- [x] BigBoss.gd / BigBoss.tscn — 2000 HP, _draw() visuals, patrol, drops 16 gems
- [x] Boss HP bar in HUD, boss signals in EventBus, difficulty scaling on spawn

### ✅ Real Boss Designs
- [x] Mini Boss attack pattern: ENTERING → PATROL → BURST_FIRE (3 shots) → CHARGE → RECOVER state machine
- [x] Big Boss 3-phase: Phase 1 burst×3, Phase 2 (50% HP) spread×5+charge, Phase 3 (25% HP) fan×7+rapid fire+visual tint
- [ ] Boss 1: Fortress Station (Ante 1 L3)
- [ ] Boss 2: Battlecruiser (Ante 2 L3)
- [ ] Boss 3: Mothership (Ante 3 L3)
- [ ] 16× Mini Boss variants (L1 & L2 across 8 antes)
- [ ] Boss intro / death animations

---

## ✅ PHASE G — Ship Selection

- [x] Ship selection screen before run (ShipSelectUI.gd — full-screen overlay, ship cards with portraits + stats)
- [x] Ship stats: HP, speed, weapon_slots, armour, weapon_bonus — all wired to Player
- [x] Ships 1–5 — Interceptor (always), Tank, Glass Cannon, Scout, Dreadnought (all unlocked for now)
- [x] Ship weapon_bonus → flat addition to base_damage before pilot chain
- [x] Player.armour → flat reduction per hit (minimum 1 damage)
- [x] data/ships.json + ShipDB autoload
- [ ] Ships 6–8 — TBD stats (deferred)
- [ ] Lock/unlock gating against Phase H save system

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
- [ ] Tutorial / onboarding
- [ ] Balance pass — use Card Simulator sheet in game_data.xlsx
- [ ] Achievement system

### 💡 Atmospherics & Lighting (Limbo / Hollow Knight style)
Goal: deep dark space with reactive dynamic lighting. Most of this is visual-feedback driven — iterate with user after each step.

**Step 1 — Background & WorldEnvironment (do first)**
- [x] **Parallax colour tinting** — far layer deep blue-purple `Color(0.5, 0.6, 0.9)`, mid purple-magenta `Color(0.4, 0.35, 0.7)`, near silhouette `Color(0.15, 0.12, 0.25)` — tweak to taste
- [x] **WorldEnvironment** — add to main.tscn; `glow_enabled=true`, `glow_bloom=0.1`, `glow_hdr_threshold=0.7`, dark ambient `Color(0.02, 0.02, 0.05)`. Forward Plus renderer so this works in 2D automatically.
- [x] **Vignette shader overlay** — CanvasLayer (layer 98) with full-rect ColorRect + `assets/shaders/vignette.gdshader`. Shader: UV→centred coords, radial dot product, pow curve, outputs black with alpha = (1-vignette). Strength param ~1.2.

**Step 2 — Reactive lighting (visual-feedback phase)**
- [ ] **CanvasLight2D on player** — soft ambient glow around ship (blob texture, energy ~0.8, cyan/blue)
- [ ] **CanvasLight2D on bullets** — small point light per bullet in flight; colour matches weapon type; profile performance (one light per live bullet — may need pooling)
- [ ] **CanvasLight2D on explosions** — flash on AOE/death; Tween energy 2.0→0 over ~0.3s
- [ ] **Ambient dust particles** — GPUParticles2D, ~30 particles, tiny 2-4px dots, slow leftward drift. Subtle depth vibe.
- [ ] **LightOccluder2D** — try on solid game elements; only if shadow casting looks good in testing

**Notes:**
- `CanvasLight2D` needs `item_cull_mask` to match sprite `light_mask` (both default to layer 1 — should work)
- For bullet lights: consider only lighting bullets of high-tier weapons to control draw calls
- Fog bands (horizontal gradient overlays) are optional — only add if space feels too clean after Step 1

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
- [x] 2193 debug notices on startup — resolved
- [ ] Shift key weapon slot switch — remove once all slots fire simultaneously by default
- [x] Double-damage bug on KamikazeDrone + TurretPlatform — removed redundant area_entered bullet handlers; Bullet.gd is sole authority for bullet hit detection

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

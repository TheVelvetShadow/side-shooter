# Space Shooter - Development TODO

## How to use this file
- Move tasks from TODO → IN PROGRESS when you start them
- Move to DONE when complete
- Add notes/blockers inline as you go

---

## 🔴 IN PROGRESS
- [ ] Phase 3 - Weapon system

---

## 📋 PHASE 3 - Weapons

---

## 📋 PHASE 3 - Weapons

### Weapon System
- [ ] Weapon data structure (JSON)
- [ ] Multiple weapon types (Ballistic, Energy, Missile)
- [ ] Weapon pickup from enemy drops
- [ ] Weapon slots on ship (2 default)
- [ ] Switch between weapons

### Weapon Merging
- [ ] Merge tier system (Tier 1-5)
- [ ] Merge prompt on duplicate pickup
- [ ] Damage/fire rate scaling per tier
- [ ] Visual change per tier

---

## 📋 PHASE 4 - Card System

### Cards
- [ ] Card data structure
- [ ] Card offered after boss/every 2-3 levels
- [ ] Choose 1 of 3 cards
- [ ] Card rarity tiers (Common/Rare/Epic)
- [ ] Max 5 active cards

### Card Types
- [ ] Stat modification cards
- [ ] Weapon enhancement cards
- [ ] Synergy cards
- [ ] Risk/reward cards

---

## 📋 PHASE 5 - Meta Progression

### Pilot Academy
- [ ] Main hub scene
- [ ] XP persists between runs (save system)
- [ ] Ship unlock system
- [ ] Weapon unlock system
- [ ] Card unlock system
- [ ] Permanent stat upgrades

### Ships
- [ ] Ship 1 - Interceptor (starter) ✅ base done
- [ ] Ship 2 - Tank
- [ ] Ship 3 - Glass Cannon
- [ ] Ship 4 - Scout
- [ ] Ship 5 - Dreadnought

---

## 📋 PHASE 6 - Levels & Enemies

### Levels
- [ ] Level 1 complete
- [ ] Level 2 + first boss
- [ ] Levels 3-5
- [ ] Level 5 mid-point boss
- [ ] Levels 6-10
- [ ] Level 10 final boss

### Boss Enemies
- [ ] Boss 1 - Fortress Station (Level 2)
- [ ] Boss 2 - Battlecruiser (Level 5)
- [ ] Boss 3 - Mothership (Level 10)

---

## 📋 PHASE 7 - Polish

- [ ] Visual effects (explosions, bullet trails)
- [ ] Audio - music
- [ ] Audio - SFX per weapon
- [ ] UI - XP bar (shows progress to next level)
- [ ] UI - Active cards display
- [ ] UI - Weapon slots display
- [ ] Main menu
- [ ] Tutorial / onboarding
- [ ] Achievement system
- [ ] Balance pass

---

## ✅ DONE

### Project Setup
- [x] Project setup and folder structure
- [x] GUT testing framework installed
- [x] EventBus.gd (signal system)
- [x] GameManager.gd (global state)
- [x] Autoloads configured

### Phase 1 - Core Gameplay (MVP) ✅ COMPLETE
- [x] Ship movement (WASD)
- [x] Basic firing mechanic
- [x] HP / Shield system
- [x] Death signal
- [x] Screen boundary clamping
- [x] Bullet scene and script (Bullet.tscn / Bullet.gd)
- [x] Fire rate working end to end (FireTimer)
- [x] Enemy 1 - Scout Fighter (wave movement, Enemy.tscn)
- [x] Enemy 2 - Kamikaze Drone (homing, KamikazeDrone.tscn)
- [x] Enemy 3 - Turret Platform (shoots bullets, TurretPlatform.tscn)
- [x] Enemy spawner system (waves: flock / kamikaze rush / turret line)
- [x] Enemy drops XP on death (GameManager._on_enemy_died)
- [x] Bullet hits enemy (collision detection)
- [x] Enemy takes damage and dies
- [x] Enemy bullets damage player (EnemyBullet.gd)
- [x] Player death triggers game over
- [x] Player.tscn
- [x] Bullet.tscn
- [x] Enemy1.tscn (Scout Fighter)
- [x] Main.tscn (playable level)

### Phase 2 - Progression ✅ COMPLETE
- [x] XP drops from enemies
- [x] XP counter in GameManager (run_xp, ship_xp)
- [x] Ship levels up at XP thresholds (_check_level_up)
- [x] Level up offers 3 stat upgrade choices (LevelUpUI.tscn, pauses game)
- [x] HP upgrade (+20 max HP, restores HP)
- [x] Shield upgrade (+15 max shield, full restore)
- [x] Attack multiplier upgrade (+20% damage per bullet)
- [x] Speed upgrade (+30 move speed)

### Phase 7 - Polish (partial)
- [x] Scrolling parallax background
- [x] UI - HP/Shield bars (HUD.tscn)
- [x] UI - Score display
- [x] UI - XP bar with level display (bottom-left HUD)
- [x] Game over screen with score + best score + restart

---

## 🐛 KNOWN BUGS / BLOCKERS
- [ ] 2193 debug notices on startup - investigate source

---

## 📝 NOTES & DECISIONS
- Using Godot 4.x / GDScript
- GUT framework for TDD
- EventBus pattern for decoupled signals
- ui_left/right/up/down replaced with custom move_ actions
- Bullet firing uses spacebar (fire action)
- Collision layers: 1=Player, 2=Enemies, 4=Player bullets, 8=Enemy bullets

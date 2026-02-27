# Space Shooter - Development TODO

## How to use this file
- Move tasks from TODO → IN PROGRESS when you start them
- Move to DONE when complete
- Add notes/blockers inline as you go

---

## 🔴 IN PROGRESS
- [ ] Enemy 1 - multiple spawns with movement

---

## 📋 PHASE 1 - Core Gameplay (MVP)

### Player
- [x] Ship movement (WASD)
- [x] Basic firing mechanic
- [x] HP / Shield system
- [x] Death signal
- [ ] Screen boundary clamping (clamp_to_screen wired up)
- [ ] Bullet scene and script
- [ ] Fire rate working end to end

### Enemies
- [ ] Enemy 1 - Scout Fighter (basic, moves left across screen)
- [ ] Enemy 2 - Kamikaze Drone (flies directly at player)
- [ ] Enemy 3 - Turret Platform (stationary, shoots at player)
- [ ] Enemy spawner system (waves, timing)
- [ ] Enemy drops XP on death

### Combat
- [ ] Bullet hits enemy (collision detection)
- [ ] Enemy takes damage and dies
- [ ] Enemy bullets damage player
- [ ] Player death triggers game over

### Scene Structure
- [x] Player.tscn
- [ ] Bullet.tscn
- [ ] Enemy1.tscn (Scout Fighter)
- [ ] Main.tscn (playable level)

---

## 📋 PHASE 2 - Progression

### XP & Levelling
- [ ] XP drops from enemies
- [ ] XP counter in GameManager
- [ ] Ship levels up at XP thresholds
- [ ] Level up offers 3 stat upgrade choices

### Stat Upgrades
- [ ] HP upgrade
- [ ] Shield upgrade
- [ ] Attack multiplier upgrade
- [ ] Speed upgrade

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
- [ ] UI - HP/Shield bars
- [ ] UI - XP counter
- [ ] UI - Active cards display
- [ ] UI - Weapon slots display
- [ ] Main menu
- [ ] Tutorial / onboarding
- [ ] Achievement system
- [ ] Balance pass

---

## ✅ DONE
- [x] Project setup and folder structure
- [x] GUT testing framework installed
- [x] EventBus.gd (signal system)
- [x] GameManager.gd (global state)
- [x] Player.gd (movement, HP/shield, death)
- [x] Input mapping (WASD)
- [x] Autoloads configured

---

## 🐛 KNOWN BUGS / BLOCKERS
- [ ] 2193 debug notices on startup - investigate source
- [ ] clamp_to_screen() not called in _physics_process yet

---

## 📝 NOTES & DECISIONS
- Using Godot 4.x / GDScript
- GUT framework for TDD
- EventBus pattern for decoupled signals
- ui_left/right/up/down replaced with custom move_ actions
- Bullet firing uses spacebar (fire action)

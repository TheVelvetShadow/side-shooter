extends Node

# --- Run State ---
var run_active: bool = false
var current_ship_id: String = "interceptor"

# --- XP ---
var meta_xp: int = 0        # Permanent, survives death
var run_xp: int = 0         # Lost on death, used for score
var high_score: int = 0

# --- Credits (wage paid at end of each level, spent in Pilot Academy) ---
var credits: int = 0

# --- Weapon XP (global upgrade bar, filled by energy gems) ---
var weapon_xp: int = 0
var weapon_xp_threshold: int = 100
var upgrades_enabled: bool = true   # debug toggle — skip upgrade cards when false

# --- Ship level (in-run, drives LevelUpUI stat upgrades) ---
var ship_level: int = 1
var ship_xp: int = 0
var ship_xp_thresholds: Array[int] = [100, 250, 500, 1000, 2000]

func _ready() -> void:
	EventBus.enemy_died.connect(_on_enemy_died)
	EventBus.player_died.connect(_on_player_died)
	EventBus.run_xp_gained.connect(_on_run_xp_gained)
	EventBus.energy_collected.connect(_on_energy_collected)
	EventBus.level_started.connect(_on_level_started)

func _on_level_started(_ante: int, _level: int) -> void:
	weapon_xp = 0
	EventBus.weapon_xp_bar_updated.emit(weapon_xp, weapon_xp_threshold)

func start_run(ship_id: String) -> void:
	current_ship_id = ship_id
	run_active = true
	run_xp = 0
	ship_level = 1
	ship_xp = 0
	credits = 0
	weapon_xp = 0
	weapon_xp_threshold = 100
	PilotManager.reset()

func award_level_wage(ante: int, level_in_ante: int) -> void:
	# Base 50 + 15 per ante above 1 — scales gently with difficulty
	var wage: int = 50 + (ante - 1) * 15 + (level_in_ante - 1) * 5
	credits += wage
	EventBus.credits_changed.emit(credits)

func spend_credits(amount: int) -> bool:
	if credits < amount:
		return false
	credits -= amount
	EventBus.credits_changed.emit(credits)
	return true

func end_run(victory: bool) -> void:
	run_active = false
	if run_xp > high_score:
		high_score = run_xp
	if victory:
		EventBus.run_completed.emit()
	else:
		EventBus.game_over.emit()

func _on_enemy_died(enemy_id: String, xp_value: int) -> void:
	meta_xp += xp_value
	_add_run_xp(xp_value)

func _on_run_xp_gained(amount: int) -> void:
	_add_run_xp(amount)

func _add_run_xp(amount: int) -> void:
	run_xp += amount
	ship_xp += amount
	EventBus.xp_gained.emit(amount)
	_check_level_up()

func _check_level_up() -> void:
	if ship_level > ship_xp_thresholds.size():
		return
	var threshold: int = ship_xp_thresholds[ship_level - 1]
	if ship_xp >= threshold:
		ship_xp -= threshold
		ship_level += 1
		EventBus.ship_levelled_up.emit(ship_level)

func _on_energy_collected(amount: int, _slot: int) -> void:
	# Gems feed the weapon XP bar only — credits come from level wages
	weapon_xp += amount
	EventBus.weapon_xp_bar_updated.emit(weapon_xp, weapon_xp_threshold)
	_check_weapon_upgrade()

func _check_weapon_upgrade() -> void:
	if weapon_xp < weapon_xp_threshold:
		return
	weapon_xp -= weapon_xp_threshold
	weapon_xp_threshold = int(weapon_xp_threshold * 1.10)
	if upgrades_enabled:
		EventBus.weapon_upgrade_available.emit(0)
	EventBus.weapon_xp_bar_updated.emit(weapon_xp, weapon_xp_threshold)

func _on_player_died() -> void:
	end_run(false)

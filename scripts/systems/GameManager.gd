extends Node

# --- Run State ---
var current_level: int = 1
var run_active: bool = false
var current_ship_id: String = "interceptor"

# --- XP ---
var meta_xp: int = 0        # Permanent, survives death
var run_xp: int = 0         # Lost on death, used for in-run levels
var high_score: int = 0

# --- Ship level (in-run) ---
var ship_level: int = 1
var ship_xp: int = 0
var ship_xp_thresholds: Array[int] = [100, 250, 500, 1000, 2000]

func _ready() -> void:
	EventBus.enemy_died.connect(_on_enemy_died)
	EventBus.player_died.connect(_on_player_died)
	EventBus.run_xp_gained.connect(_on_run_xp_gained)

func start_run(ship_id: String) -> void:
	current_ship_id = ship_id
	run_active = true
	run_xp = 0
	ship_level = 1
	ship_xp = 0
	current_level = 1
	EventBus.level_started.emit(current_level)

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

func _on_player_died() -> void:
	end_run(false)

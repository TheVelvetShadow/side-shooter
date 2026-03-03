extends Node
class_name EnemySpawner

const _ENEMY_SCENE = preload("res://scenes/enemies/Enemy.tscn")

@export var time_between_waves: float = 12.0
@export var first_wave_delay:   float = 1.0
@export var duplicate_lines:    int   = 2      # how many vertical lines per wave
@export var line_x_gap:         float = 80.0   # horizontal gap between lines

@onready var wave_timer: Timer = $WaveTimer

var _current_ante: int  = 1
var _current_level: int = 1
var _wave_index: int    = 0
var _exhausted: bool    = false
var _formation_wave_count: Dictionary = {}   # enemy_id → how many formation waves spawned this level


func _ready() -> void:
	wave_timer.wait_time = time_between_waves
	wave_timer.one_shot = true
	wave_timer.timeout.connect(_on_wave_timer_timeout)
	EventBus.level_started.connect(_on_level_started)
	EventBus.waves_exhausted.connect(_on_waves_exhausted)


func _on_level_started(ante: int, level: int) -> void:
	_current_ante  = ante
	_current_level = level
	_wave_index    = 0
	_exhausted     = false
	_formation_wave_count.clear()
	wave_timer.wait_time = first_wave_delay   # short delay before first wave
	wave_timer.start()


func _on_waves_exhausted() -> void:
	_exhausted = true
	wave_timer.stop()


func _on_wave_timer_timeout() -> void:
	var pool := EnemyDB.get_enemies_for_level(_current_ante, _current_level)
	if pool.is_empty():
		push_warning("EnemySpawner: no enemies available for ante=%d level=%d" % [_current_ante, _current_level])
	else:
		var data := _weighted_pick(pool)
		_spawn_group(data)
	EventBus.wave_spawned.emit(_wave_index)
	_wave_index += 1
	if not _exhausted:
		wave_timer.wait_time = time_between_waves   # back to regular interval
		wave_timer.start()


func _weighted_pick(pool: Array) -> Dictionary:
	var total_weight: int = 0
	for entry in pool:
		total_weight += int(entry.get("spawn_weight", 1))
	var roll: int = randi() % maxi(total_weight, 1)
	var running := 0
	for entry in pool:
		running += int(entry.get("spawn_weight", 1))
		if roll < running:
			return entry
	return pool[pool.size() - 1]


func _spawn_group(data: Dictionary) -> void:
	var amount: int    = int(data.get("spawn_amount", 1))
	var vp             := get_viewport().get_visible_rect().size
	var spawn_x: float = vp.x + 64.0
	var margin: float  = vp.y * 0.25   # 25% top and bottom = 50% usable band

	# For formation enemies, track how many waves have spawned so each parks further left
	var enemy_id: String = data.get("enemy_id", "")
	var formation_line := 0
	if data.get("movement_type", "") == "formation_sine":
		formation_line = _formation_wave_count.get(enemy_id, 0)
		_formation_wave_count[enemy_id] = formation_line + 1

	var behaviour: String = data.get("spawn_behaviour", "solo")

	if behaviour == "v_formation":
		# Leader at tip, two wings set back and spread vertically
		var center_y: float = randf_range(vp.y * 0.25, vp.y * 0.75)
		var positions: Array[Vector2] = [
			Vector2(spawn_x,          center_y),          # leader
			Vector2(spawn_x + 80.0,   center_y - 65.0),  # upper wing
			Vector2(spawn_x + 80.0,   center_y + 65.0),  # lower wing
		]
		for i in positions.size():
			_spawn_enemy(data, positions[i], i, positions.size())
		return

	# Spawn duplicate_lines vertical columns, each offset further right.
	# Within each column, enemies are evenly distributed across the 50% band.
	for line in duplicate_lines:
		var x_base: float = spawn_x + line * line_x_gap
		var base_phase := randf() * TAU   # randomise Y-slot base per line so waves don't stack
		for i in amount:
			var t    := (float(i) + 0.5) / float(amount)
			var y: float = lerp(margin, vp.y - margin, t) + randf_range(-20.0, 20.0)
			var x: float = x_base + randf_range(0.0, 25.0)
			_spawn_enemy(data, Vector2(x, y), i, amount, base_phase, formation_line)


func _spawn_enemy(data: Dictionary, pos: Vector2, index: int, total: int, base_phase: float = 0.0, formation_line: int = 0) -> void:
	var enemy := _ENEMY_SCENE.instantiate()
	enemy.enemy_id = data.get("enemy_id", "")
	enemy.load_from_db()
	_apply_difficulty(enemy)
	# Stagger wave_phase_offset for sine/swoop flocks
	if total > 1:
		enemy.wave_phase_offset = base_phase + index * (TAU / total)
	enemy.formation_line = formation_line
	enemy.global_position = pos
	get_tree().root.add_child(enemy)


func _apply_difficulty(enemy: Node) -> void:
	var diff := LevelManager.get_difficulty()
	if "max_hp" in enemy:
		enemy.max_hp = int(enemy.max_hp * diff["hp_mult"])
	if "speed" in enemy:
		enemy.speed = enemy.speed * diff["speed_mult"]
	if "contact_damage" in enemy:
		enemy.contact_damage = int(enemy.contact_damage * diff["hp_mult"])

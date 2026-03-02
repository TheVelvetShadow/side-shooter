extends Node
class_name EnemySpawner

const _ENEMY_SCENE = preload("res://scenes/enemies/Enemy.tscn")

@export var time_between_waves: float = 12.0

@onready var wave_timer: Timer = $WaveTimer

var _current_ante: int  = 1
var _current_level: int = 1
var _wave_index: int    = 0
var _exhausted: bool    = false


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
	var behaviour: String = data.get("spawn_behaviour", "solo")
	var amount: int       = int(data.get("spawn_amount", 1))
	var vp                := get_viewport().get_visible_rect().size
	var spawn_x: float    = vp.x + 64.0

	match behaviour:
		"solo":
			var pos := Vector2(spawn_x, randf_range(100.0, vp.y - 100.0))
			_spawn_enemy(data, pos, 0, amount)

		"pack":
			var spread := 120.0
			var center_y := randf_range(spread * 0.5, vp.y - spread * 0.5)
			for i in amount:
				var step := spread / maxf(amount - 1, 1)
				var offset_y := (i - (amount - 1) * 0.5) * step
				_spawn_enemy(data, Vector2(spawn_x, center_y + offset_y), i, amount)

		"swarm":
			var spread := vp.y * 0.7
			var center_y := vp.y * 0.5
			for i in amount:
				var step := spread / maxf(amount - 1, 1)
				var offset_y := (i - (amount - 1) * 0.5) * step
				var jitter_x := randf_range(0.0, 80.0)
				_spawn_enemy(data, Vector2(spawn_x + jitter_x, center_y + offset_y), i, amount)

		_:
			var pos := Vector2(spawn_x, randf_range(100.0, vp.y - 100.0))
			_spawn_enemy(data, pos, 0, amount)


func _spawn_enemy(data: Dictionary, pos: Vector2, index: int, total: int) -> void:
	var enemy := _ENEMY_SCENE.instantiate()
	enemy.enemy_id = data.get("enemy_id", "")
	enemy.load_from_db()
	_apply_difficulty(enemy)
	# Stagger wave_phase_offset for sine/swoop flocks
	if total > 1:
		enemy.wave_phase_offset = index * (TAU / total)
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

extends Node
class_name EnemySpawner

@export var enemy_scene: PackedScene
@export var kamikaze_scene: PackedScene
@export var turret_scene: PackedScene
@export var enemy_bullet_scene: PackedScene
@export var flock_size: int = 5
@export var flock_spread: float = 120.0
@export var time_between_waves: float = 12.0

@onready var wave_timer: Timer = $WaveTimer

var _wave_index: int = 0

func _ready() -> void:
	wave_timer.wait_time = time_between_waves
	wave_timer.one_shot = true
	wave_timer.timeout.connect(_on_wave_timer_timeout)
	EventBus.level_started.connect(_on_level_started)
	EventBus.waves_exhausted.connect(_on_waves_exhausted)

func _on_level_started(_ante: int, _level: int) -> void:
	_wave_index = 0
	wave_timer.start()

func _on_waves_exhausted() -> void:
	wave_timer.stop()

func _on_wave_timer_timeout() -> void:
	match _wave_index % 3:
		0: _spawn_flock()
		1: _spawn_kamikaze_rush()
		2: _spawn_turret_line()
	EventBus.wave_spawned.emit(_wave_index)
	_wave_index += 1
	wave_timer.start()

func _apply_difficulty(enemy: Node) -> void:
	var diff := LevelManager.get_difficulty()
	if "max_hp" in enemy:
		enemy.max_hp = int(enemy.max_hp * diff["hp_mult"])
	if "speed" in enemy:
		enemy.speed = enemy.speed * diff["speed_mult"]
	if "contact_damage" in enemy:
		enemy.contact_damage = int(enemy.contact_damage * diff["hp_mult"])

func _spawn_flock() -> void:
	if enemy_scene == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var center_y := randf_range(flock_spread * 0.5, viewport_size.y - flock_spread * 0.5)
	var spawn_x := viewport_size.x + 64.0
	for i in flock_size:
		var enemy := enemy_scene.instantiate()
		enemy.global_position = Vector2(spawn_x, center_y + (i - (flock_size - 1) / 2.0) * (flock_spread / flock_size))
		enemy.wave_phase_offset = i * (TAU / flock_size)
		_apply_difficulty(enemy)
		get_tree().root.add_child(enemy)

func _spawn_kamikaze_rush() -> void:
	if kamikaze_scene == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var spawn_x := viewport_size.x + 64.0
	for i in 3:
		var drone := kamikaze_scene.instantiate()
		drone.global_position = Vector2(spawn_x, viewport_size.y * 0.5 + (i - 1) * 150.0)
		_apply_difficulty(drone)
		get_tree().root.add_child(drone)

func _spawn_turret_line() -> void:
	if turret_scene == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var spawn_x := viewport_size.x + 64.0
	for i in 2:
		var turret := turret_scene.instantiate()
		turret.global_position = Vector2(spawn_x + i * 200.0, viewport_size.y * 0.25 + i * (viewport_size.y * 0.5))
		turret.bullet_scene = enemy_bullet_scene
		_apply_difficulty(turret)
		get_tree().root.add_child(turret)

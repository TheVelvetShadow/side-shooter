extends Node
class_name EnemySpawner

@export var enemy_scene: PackedScene
@export var kamikaze_scene: PackedScene
@export var turret_scene: PackedScene
@export var enemy_bullet_scene: PackedScene
@export var flock_size: int = 5
@export var flock_spread: float = 120.0
@export var time_between_waves: float = 6.0

@onready var wave_timer: Timer = $WaveTimer

var _wave_index: int = 0

func _ready() -> void:
	wave_timer.wait_time = time_between_waves
	wave_timer.timeout.connect(_on_wave_timer_timeout)
	wave_timer.start()

func _on_wave_timer_timeout() -> void:
	match _wave_index % 3:
		0: _spawn_flock()
		1: _spawn_kamikaze_rush()
		2: _spawn_turret_line()
	_wave_index += 1

func _spawn_flock() -> void:
	if enemy_scene == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var center_y := randf_range(flock_spread * 0.5, viewport_size.y - flock_spread * 0.5)
	var spawn_x := viewport_size.x + 64.0
	for i in flock_size:
		var enemy := enemy_scene.instantiate()
		var offset_y := (i - (flock_size - 1) / 2.0) * (flock_spread / flock_size)
		enemy.global_position = Vector2(spawn_x, center_y + offset_y)
		enemy.wave_phase_offset = i * (TAU / flock_size)
		get_tree().root.add_child(enemy)

func _spawn_kamikaze_rush() -> void:
	if kamikaze_scene == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var center_y := viewport_size.y * 0.5
	var spawn_x := viewport_size.x + 64.0
	for i in 3:
		var drone := kamikaze_scene.instantiate()
		var offset_y := (i - 1) * 150.0
		drone.global_position = Vector2(spawn_x, center_y + offset_y)
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
		get_tree().root.add_child(turret)

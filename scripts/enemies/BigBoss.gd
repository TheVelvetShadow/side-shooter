extends Area2D
class_name BigBoss

const _GEM_SCENE = preload("res://scenes/pickups/EnergyGem.tscn")

const BOSS_NAME    := "DREADNOUGHT PRIME"
const RADIUS       := 72.0
const ENTRY_SPEED  := 100.0
const PATROL_SPEED := 40.0
const CONTACT_DMG  := 40

@export var max_hp: int = 2000
@export var xp_value: int = 500
@export var speed: float = PATROL_SPEED

var current_hp: int
var _entered: bool = false
var _target_x: float
var _patrol_dir: float = 1.0

func _ready() -> void:
	current_hp = max_hp
	add_to_group("level_objects")
	var vp := get_viewport().get_visible_rect()
	_target_x = vp.size.x * 0.68
	body_entered.connect(_on_body_entered)
	EventBus.enemy_spawned.emit("big_boss")
	EventBus.boss_spawned.emit(BOSS_NAME, max_hp)
	EventBus.boss_hp_changed.emit(current_hp, max_hp)

func _draw() -> void:
	# Outer body
	draw_circle(Vector2.ZERO, RADIUS, Color(0.35, 0.1, 0.55, 1.0))
	# Ring detail
	draw_arc(Vector2.ZERO, RADIUS,       0.0, TAU, 64, Color(0.75, 0.2, 1.0,  1.0), 4.0)
	draw_arc(Vector2.ZERO, RADIUS * 0.7, 0.0, TAU, 48, Color(0.55, 0.1, 0.85, 1.0), 2.0)
	# Core
	draw_circle(Vector2.ZERO, RADIUS * 0.3, Color(1.0, 0.5, 1.0, 1.0))
	# Eyes
	for ex in [-22.0, 22.0]:
		draw_circle(Vector2(ex, -16), 13.0, Color(1.0, 0.8, 0.0, 1.0))
		draw_circle(Vector2(ex, -16), 6.0,  Color(0.05, 0.0, 0.1, 1.0))

func _process(delta: float) -> void:
	var vp := get_viewport().get_visible_rect()

	if not _entered:
		global_position.x -= ENTRY_SPEED * delta
		if global_position.x <= _target_x:
			global_position.x = _target_x
			_entered = true
		return

	global_position.y += _patrol_dir * speed * delta
	var margin := RADIUS + 20.0
	if global_position.y > vp.size.y - margin:
		global_position.y = vp.size.y - margin
		_patrol_dir = -1.0
	elif global_position.y < margin:
		global_position.y = margin
		_patrol_dir = 1.0

func take_damage(amount: int, _source_slot: int = -1) -> void:
	current_hp -= amount
	EventBus.boss_hp_changed.emit(maxi(current_hp, 0), max_hp)
	if current_hp <= 0:
		die()

func die() -> void:
	EventBus.enemy_died.emit("big_boss", xp_value)
	for i in 16:
		var gem = _GEM_SCENE.instantiate()
		gem.xp_value = xp_value / 16
		gem.global_position = global_position + Vector2(randf_range(-80, 80), randf_range(-80, 80))
		get_tree().root.add_child(gem)
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.take_damage(CONTACT_DMG)

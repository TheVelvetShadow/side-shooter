extends Area2D
class_name MiniBoss

const _GEM_SCENE = preload("res://scenes/pickups/EnergyGem.tscn")

const BOSS_NAME    := "INTERCEPTOR ALPHA"
const RADIUS       := 44.0
const ENTRY_SPEED  := 180.0
const PATROL_SPEED := 60.0
const CONTACT_DMG  := 25

@export var max_hp: int = 500
@export var xp_value: int = 100
@export var speed: float = PATROL_SPEED

var current_hp: int
var _entered: bool = false
var _target_x: float
var _patrol_dir: float = 1.0
var _patrol_timer: float = 0.0

func _ready() -> void:
	current_hp = max_hp
	add_to_group("level_objects")
	var vp := get_viewport().get_visible_rect()
	_target_x = vp.size.x * 0.72
	body_entered.connect(_on_body_entered)
	EventBus.enemy_spawned.emit("mini_boss")
	EventBus.boss_spawned.emit(BOSS_NAME, max_hp)
	EventBus.boss_hp_changed.emit(current_hp, max_hp)

func _draw() -> void:
	# Body
	draw_circle(Vector2.ZERO, RADIUS, Color(0.75, 0.2, 0.1, 1.0))
	# Outline
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 48, Color(1.0, 0.55, 0.1, 1.0), 3.0)
	# Eye
	draw_circle(Vector2(-12, -8), 10.0, Color(1.0, 0.85, 0.0, 1.0))
	draw_circle(Vector2(-12, -8), 5.0,  Color(0.1, 0.05, 0.0, 1.0))
	draw_circle(Vector2(12, -8),  10.0, Color(1.0, 0.85, 0.0, 1.0))
	draw_circle(Vector2(12, -8),  5.0,  Color(0.1, 0.05, 0.0, 1.0))

func _process(delta: float) -> void:
	var vp := get_viewport().get_visible_rect()

	if not _entered:
		# Slide into screen from right
		global_position.x -= ENTRY_SPEED * delta
		if global_position.x <= _target_x:
			global_position.x = _target_x
			_entered = true
		return

	# Simple up/down patrol at target_x
	_patrol_timer += delta
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
	EventBus.enemy_died.emit("mini_boss", xp_value)
	# Drop a cluster of gems
	for i in 6:
		var gem = _GEM_SCENE.instantiate()
		gem.xp_value = xp_value / 6
		gem.global_position = global_position + Vector2(randf_range(-40, 40), randf_range(-40, 40))
		get_tree().root.add_child(gem)
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.take_damage(CONTACT_DMG)

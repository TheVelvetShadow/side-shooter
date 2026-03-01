extends Node2D

const DRIFT_SPEED   := 50.0
const MAGNET_RANGE  := 250.0
const ATTRACT_SPEED := 500.0
const COLLECT_RANGE := 18.0
const LIFETIME      := 12.0
const GEM_COLOR     := Color(0.2, 1.0, 0.85, 1.0)

var xp_value: int = 10
var source_weapon_slot: int = -1

var _player: Node2D = null
var _lifetime: float = 0.0

func _ready() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player = players[0]

func _process(delta: float) -> void:
	_lifetime += delta
	if _lifetime >= LIFETIME:
		queue_free()
		return

	if _player == null or not is_instance_valid(_player):
		position.x -= DRIFT_SPEED * delta
		if global_position.x < -64:
			queue_free()
		return

	var dist := global_position.distance_to(_player.global_position)

	if dist < COLLECT_RANGE:
		_collect()
		return

	if dist < MAGNET_RANGE:
		global_position += (_player.global_position - global_position).normalized() * ATTRACT_SPEED * delta
	else:
		position.x -= DRIFT_SPEED * delta
		if global_position.x < -64:
			queue_free()

	queue_redraw()

func _collect() -> void:
	EventBus.energy_collected.emit(xp_value, source_weapon_slot)
	queue_free()

func _draw() -> void:
	var pulse := 1.0 + sin(_lifetime * 4.0) * 0.15
	var s := 6.0 * pulse
	var points := PackedVector2Array([
		Vector2(0, -s), Vector2(s, 0), Vector2(0, s), Vector2(-s, 0)
	])
	draw_colored_polygon(points, GEM_COLOR)
	draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]),
		Color(1, 1, 1, 0.5), 1.0)

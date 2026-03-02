extends Area2D
class_name MiniBoss

const _GEM_SCENE    = preload("res://scenes/pickups/EnergyGem.tscn")
const _BULLET_SCENE = preload("res://scenes/enemies/EnemyBullet.tscn")

const BOSS_NAME    := "INTERCEPTOR ALPHA"
const RADIUS       := 44.0
const ENTRY_SPEED  := 180.0
const PATROL_SPEED := 70.0
const CONTACT_DMG  := 25
const BULLET_DMG   := 12
const BULLET_SPEED := 340.0

@export var max_hp: int = 500
@export var xp_value: int = 100
@export var speed: float = PATROL_SPEED

var current_hp: int

enum State { ENTERING, PATROL, BURST_FIRE, CHARGE, RECOVER }
var _state: State = State.ENTERING

var _target_x: float
var _patrol_dir: float = 1.0

# Timers
var _patrol_timer: float = 0.0
var _burst_timer: float  = 0.0
var _burst_count: int    = 0
var _burst_cycle: int    = 0    # increments each full burst; every 3 → charge
var _charge_timer: float = 0.0

const PATROL_DURATION := 3.5   # seconds in patrol before firing
const BURST_INTERVAL  := 0.28  # seconds between shots in a burst
const BURST_SHOTS     := 3
const CHARGE_SPEED    := 480.0
const RECOVER_SPEED   := 200.0
const CHARGE_DURATION := 0.5

var _charge_dir: Vector2 = Vector2.ZERO
var _recover_target: Vector2 = Vector2.ZERO
var _player: Node2D = null

func _ready() -> void:
	current_hp = max_hp
	add_to_group("level_objects")
	var vp := get_viewport().get_visible_rect()
	_target_x = vp.size.x * 0.72
	body_entered.connect(_on_body_entered)
	EventBus.enemy_spawned.emit("mini_boss")
	EventBus.boss_spawned.emit(BOSS_NAME, max_hp)
	EventBus.boss_hp_changed.emit(current_hp, max_hp)
	call_deferred("_find_player")

func _find_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player = players[0]

func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, Color(0.75, 0.2, 0.1, 1.0))
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 48, Color(1.0, 0.55, 0.1, 1.0), 3.0)
	draw_circle(Vector2(-12, -8), 10.0, Color(1.0, 0.85, 0.0, 1.0))
	draw_circle(Vector2(-12, -8), 5.0,  Color(0.1, 0.05, 0.0, 1.0))
	draw_circle(Vector2(12, -8),  10.0, Color(1.0, 0.85, 0.0, 1.0))
	draw_circle(Vector2(12, -8),  5.0,  Color(0.1, 0.05, 0.0, 1.0))

func _process(delta: float) -> void:
	match _state:
		State.ENTERING:   _update_entering(delta)
		State.PATROL:     _update_patrol(delta)
		State.BURST_FIRE: _update_burst(delta)
		State.CHARGE:     _update_charge(delta)
		State.RECOVER:    _update_recover(delta)

# ── State: ENTERING ───────────────────────────────────────────────────────────

func _update_entering(delta: float) -> void:
	global_position.x -= ENTRY_SPEED * delta
	if global_position.x <= _target_x:
		global_position.x = _target_x
		_state = State.PATROL
		_patrol_timer = 0.0

# ── State: PATROL ─────────────────────────────────────────────────────────────

func _update_patrol(delta: float) -> void:
	var vp := get_viewport().get_visible_rect()
	var margin := RADIUS + 20.0
	global_position.y += _patrol_dir * speed * delta
	if global_position.y > vp.size.y - margin:
		global_position.y = vp.size.y - margin
		_patrol_dir = -1.0
	elif global_position.y < margin:
		global_position.y = margin
		_patrol_dir = 1.0

	_patrol_timer += delta
	if _patrol_timer >= PATROL_DURATION:
		_patrol_timer = 0.0
		_start_burst()

# ── State: BURST_FIRE ─────────────────────────────────────────────────────────

func _start_burst() -> void:
	_state = State.BURST_FIRE
	_burst_count = 0
	_burst_timer = 0.0
	_fire_burst_shot()

func _update_burst(delta: float) -> void:
	_burst_timer += delta
	if _burst_timer >= BURST_INTERVAL:
		_burst_timer = 0.0
		_burst_count += 1
		if _burst_count < BURST_SHOTS:
			_fire_burst_shot()
		else:
			_burst_cycle += 1
			if _burst_cycle >= 3:
				_burst_cycle = 0
				_start_charge()
			else:
				_state = State.PATROL

func _fire_burst_shot() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var dir := (_player.global_position - global_position).normalized()
	var b := _BULLET_SCENE.instantiate()
	b.global_position = global_position
	b.direction = dir
	b.speed = BULLET_SPEED
	b.damage = BULLET_DMG
	get_tree().root.add_child(b)

# ── State: CHARGE ─────────────────────────────────────────────────────────────

func _start_charge() -> void:
	_state = State.CHARGE
	_charge_timer = 0.0
	if _player != null and is_instance_valid(_player):
		_charge_dir = Vector2(-1.0, sign(_player.global_position.y - global_position.y))
		_charge_dir = _charge_dir.normalized()
	else:
		_charge_dir = Vector2.LEFT
	_recover_target = Vector2(_target_x, global_position.y)

func _update_charge(delta: float) -> void:
	var vp := get_viewport().get_visible_rect()
	global_position += _charge_dir * CHARGE_SPEED * delta
	_charge_timer += delta
	# Clamp to screen
	global_position.y = clampf(global_position.y, RADIUS + 10.0, vp.size.y - RADIUS - 10.0)
	global_position.x = clampf(global_position.x, vp.size.x * 0.1, vp.size.x + RADIUS)
	if _charge_timer >= CHARGE_DURATION:
		_recover_target = Vector2(_target_x, global_position.y)
		_state = State.RECOVER

# ── State: RECOVER ────────────────────────────────────────────────────────────

func _update_recover(delta: float) -> void:
	var diff := _recover_target - global_position
	if diff.length() < RECOVER_SPEED * delta:
		global_position = _recover_target
		_patrol_timer = 0.0
		_state = State.PATROL
	else:
		global_position += diff.normalized() * RECOVER_SPEED * delta

# ── Damage / death ────────────────────────────────────────────────────────────

func take_damage(amount: int, _source_slot: int = -1) -> void:
	current_hp -= amount
	EventBus.boss_hp_changed.emit(maxi(current_hp, 0), max_hp)
	if current_hp <= 0:
		die()

func die() -> void:
	EventBus.enemy_died.emit("mini_boss", xp_value)
	for i in 6:
		var gem = _GEM_SCENE.instantiate()
		gem.xp_value = xp_value / 6
		gem.global_position = global_position + Vector2(randf_range(-40, 40), randf_range(-40, 40))
		get_tree().root.add_child(gem)
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.take_damage(CONTACT_DMG)

extends Area2D
class_name BigBoss

const _GEM_SCENE    = preload("res://scenes/pickups/EnergyGem.tscn")
const _BULLET_SCENE = preload("res://scenes/enemies/EnemyBullet.tscn")

const BOSS_NAME    := "DREADNOUGHT PRIME"
const RADIUS       := 72.0
const ENTRY_SPEED  := 100.0
const CONTACT_DMG  := 40
const BULLET_DMG   := 18
const BULLET_SPEED := 300.0

@export var max_hp: int = 2000
@export var xp_value: int = 500
@export var speed: float = 40.0

var current_hp: int
var _phase: int = 1   # 1, 2, or 3

enum State { ENTERING, PATROL, CHARGE, RECOVER }
var _state: State = State.ENTERING

var _target_x: float
var _patrol_dir: float = 1.0

# Timers
var _fire_timer: float  = 0.0
var _charge_timer: float = 0.0

# Phase thresholds (% of max_hp)
const PHASE2_THRESHOLD := 0.50
const PHASE3_THRESHOLD := 0.25

# Per-phase fire config
var _fire_interval: float  = 3.5
var _fire_count: int       = 3
var _fire_spread: float    = 0.0   # fan spread in degrees; 0 = aimed

# Charge config
const CHARGE_SPEED    := 350.0
const RECOVER_SPEED   := 150.0
const CHARGE_DURATION := 0.6
var _charge_dir: Vector2  = Vector2.ZERO
var _recover_target: Vector2 = Vector2.ZERO
var _fire_cycles_since_charge: int = 0

var _player: Node2D = null

# Flash state for phase transition
var _flash_timer: float = 0.0
const FLASH_DURATION    := 0.8

func _ready() -> void:
	current_hp = max_hp
	add_to_group("level_objects")
	var vp := get_viewport().get_visible_rect()
	_target_x = vp.size.x * 0.68
	body_entered.connect(_on_body_entered)
	EventBus.enemy_spawned.emit("big_boss")
	EventBus.boss_spawned.emit(BOSS_NAME, max_hp)
	EventBus.boss_hp_changed.emit(current_hp, max_hp)
	call_deferred("_find_player")

func _find_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player = players[0]

func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, Color(0.35, 0.1, 0.55, 1.0))
	draw_arc(Vector2.ZERO, RADIUS,       0.0, TAU, 64, Color(0.75, 0.2, 1.0,  1.0), 4.0)
	draw_arc(Vector2.ZERO, RADIUS * 0.7, 0.0, TAU, 48, Color(0.55, 0.1, 0.85, 1.0), 2.0)
	draw_circle(Vector2.ZERO, RADIUS * 0.3, Color(1.0, 0.5, 1.0, 1.0))
	for ex in [-22.0, 22.0]:
		draw_circle(Vector2(ex, -16), 13.0, Color(1.0, 0.8, 0.0, 1.0))
		draw_circle(Vector2(ex, -16), 6.0,  Color(0.05, 0.0, 0.1, 1.0))

func _process(delta: float) -> void:
	# Phase flash fade
	if _flash_timer > 0.0:
		_flash_timer -= delta
		var t := _flash_timer / FLASH_DURATION
		modulate = Color(1.0 + t * 0.8, 1.0 - t * 0.4, 1.0 - t * 0.6, 1.0)
		if _flash_timer <= 0.0:
			modulate = _phase_tint()

	match _state:
		State.ENTERING: _update_entering(delta)
		State.PATROL:   _update_patrol(delta)
		State.CHARGE:   _update_charge(delta)
		State.RECOVER:  _update_recover(delta)

func _phase_tint() -> Color:
	match _phase:
		2: return Color(1.1, 0.7, 0.5, 1.0)
		3: return Color(1.2, 0.4, 0.4, 1.0)
		_: return Color(1.0, 1.0, 1.0, 1.0)

# ── Phase transitions ─────────────────────────────────────────────────────────

func _check_phase_transition() -> void:
	var pct := float(current_hp) / float(max_hp)
	if _phase == 1 and pct <= PHASE2_THRESHOLD:
		_enter_phase(2)
	elif _phase == 2 and pct <= PHASE3_THRESHOLD:
		_enter_phase(3)

func _enter_phase(new_phase: int) -> void:
	_phase = new_phase
	_flash_timer = FLASH_DURATION
	match new_phase:
		2:
			speed *= 1.5
			_fire_interval = 2.5
			_fire_count    = 5
			_fire_spread   = 40.0
		3:
			speed *= 1.5  # stacks with phase 2 multiplier
			_fire_interval = 1.5
			_fire_count    = 7
			_fire_spread   = 70.0

# ── State: ENTERING ───────────────────────────────────────────────────────────

func _update_entering(delta: float) -> void:
	global_position.x -= ENTRY_SPEED * delta
	if global_position.x <= _target_x:
		global_position.x = _target_x
		_state = State.PATROL
		_fire_timer = 0.0

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

	_fire_timer += delta
	if _fire_timer >= _fire_interval:
		_fire_timer = 0.0
		_start_firing()

# ── State: FIRING ─────────────────────────────────────────────────────────────

func _start_firing() -> void:
	if _player == null or not is_instance_valid(_player):
		_state = State.PATROL
		return

	var base_dir := (_player.global_position - global_position).normalized()

	if _fire_count == 1 or _fire_spread == 0.0:
		_spawn_bullet(base_dir)
	else:
		var half := _fire_spread * 0.5
		for i in _fire_count:
			var t := float(i) / float(_fire_count - 1)
			var angle := deg_to_rad(-half + _fire_spread * t)
			_spawn_bullet(base_dir.rotated(angle))

	_fire_cycles_since_charge += 1

	# Phase 2+: charge every 4 fire cycles
	if _phase >= 2 and _fire_cycles_since_charge >= 4:
		_fire_cycles_since_charge = 0
		_start_charge()
	else:
		_state = State.PATROL

func _spawn_bullet(dir: Vector2) -> void:
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
		_charge_dir = (_player.global_position - global_position).normalized()
	else:
		_charge_dir = Vector2.LEFT

func _update_charge(delta: float) -> void:
	var vp := get_viewport().get_visible_rect()
	global_position += _charge_dir * CHARGE_SPEED * delta
	_charge_timer += delta
	global_position.y = clampf(global_position.y, RADIUS + 10.0, vp.size.y - RADIUS - 10.0)
	global_position.x = clampf(global_position.x, vp.size.x * 0.05, vp.size.x + RADIUS)
	if _charge_timer >= CHARGE_DURATION:
		_recover_target = Vector2(_target_x, global_position.y)
		_state = State.RECOVER

# ── State: RECOVER ────────────────────────────────────────────────────────────

func _update_recover(delta: float) -> void:
	var diff := _recover_target - global_position
	if diff.length() < RECOVER_SPEED * delta:
		global_position = _recover_target
		_fire_timer = 0.0
		_state = State.PATROL
	else:
		global_position += diff.normalized() * RECOVER_SPEED * delta

# ── Damage / death ────────────────────────────────────────────────────────────

func take_damage(amount: int, _source_slot: int = -1) -> void:
	current_hp -= amount
	EventBus.boss_hp_changed.emit(maxi(current_hp, 0), max_hp)
	_check_phase_transition()
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

extends Area2D
class_name Enemy

const _PICKUP_SCENE = preload("res://scenes/weapons/WeaponPickup.tscn")
const _GEM_SCENE    = preload("res://scenes/pickups/EnergyGem.tscn")
const _BULLET_SCENE = preload("res://scenes/enemies/EnemyBullet.tscn")

@export var enemy_id: String = ""

# Stats — overwritten by load_from_db()
var enemy_type: String           = "fighter"
var movement_type: String        = "straight"
var spawn_behaviour: String      = "solo"
var max_hp: int                  = 30
var xp_value: int                = 10
var gem_count: int               = 1
var weapon_drop_chance: float    = 0.1
var speed: float                 = 150.0
var contact_damage: int          = 10
var wave_amplitude: float        = 0.0
var wave_frequency: float        = 2.0
var dart_interval: float         = 0.0
var dart_speed_mult: float       = 0.0
var fire_interval: float         = 0.0
var bullet_speed: float          = 200.0
var shoot_pattern: String        = "none"
var enemy_bullet_strength: int   = 8
var hp_scale: float              = 1.3
var damage_scale: float          = 1.2
var armor_type: String           = "mechanical"

# Runtime state
var wave_phase_offset: float = 0.0   # set by spawner for staggered flocks
var current_hp: int

var _db_loaded: bool  = false
var _viewport_w: float = 0.0
var _start_y: float    = 0.0
var _time: float       = 0.0
var _player: Node2D    = null

# Shooting
var _shoot_timer: float = 0.0

# Dart / zigzag movement
var _dart_timer: float  = 0.0
var _dart_active: bool  = false
var _dart_dir: Vector2  = Vector2.LEFT
var _zigzag_dir: float  = 1.0   # +1 or -1 for zigzag y-direction


func _ready() -> void:
	load_from_db()
	current_hp = max_hp
	_start_y = global_position.y
	_viewport_w = get_viewport().get_visible_rect().size.x
	body_entered.connect(_on_body_entered)
	add_to_group("level_objects")
	EventBus.enemy_spawned.emit(enemy_id)
	call_deferred("_find_player")


func load_from_db() -> void:
	if _db_loaded or enemy_id.is_empty():
		return
	_db_loaded = true
	var data := EnemyDB.get_enemy(enemy_id)
	if data.is_empty():
		push_error("Enemy: no data for id '%s'" % enemy_id)
		return
	enemy_type            = data.get("enemy_type",            enemy_type)
	movement_type         = data.get("movement_type",         movement_type)
	spawn_behaviour       = data.get("spawn_behaviour",       spawn_behaviour)
	max_hp                = int(data.get("hp",                max_hp))
	xp_value              = int(data.get("xp_value",          xp_value))
	gem_count             = int(data.get("gem_count",         gem_count))
	weapon_drop_chance    = float(data.get("weapon_drop_chance", weapon_drop_chance))
	speed                 = float(data.get("speed",           speed))
	contact_damage        = int(data.get("contact_damage",    contact_damage))
	wave_amplitude        = float(data.get("wave_amplitude",  wave_amplitude))
	wave_frequency        = float(data.get("wave_frequency",  wave_frequency))
	dart_interval         = float(data.get("dart_interval",   dart_interval))
	dart_speed_mult       = float(data.get("dart_speed_mult", dart_speed_mult))
	fire_interval         = float(data.get("fire_interval",   fire_interval))
	bullet_speed          = float(data.get("bullet_speed",    bullet_speed))
	shoot_pattern         = data.get("shoot_pattern",         shoot_pattern)
	enemy_bullet_strength = int(data.get("enemy_bullet_strength", enemy_bullet_strength))
	hp_scale              = float(data.get("hp_scale",        hp_scale))
	damage_scale          = float(data.get("damage_scale",    damage_scale))
	armor_type            = data.get("armor_type",            armor_type)


func _find_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player = players[0]


func _process(delta: float) -> void:
	_time += delta
	_move(delta)
	if fire_interval > 0.0:
		_shoot_timer += delta
		if _shoot_timer >= fire_interval:
			_shoot_timer = 0.0
			_fire_bullet()
	if global_position.x < -64.0:
		EventBus.enemy_died.emit(enemy_id, 0)  # decrement active_enemies; 0 XP for off-screen escape
		queue_free()


func _move(delta: float) -> void:
	match movement_type:
		"straight":
			position.x -= speed * delta

		"sine":
			position.x -= speed * delta
			position.y = _start_y + sin(_time * wave_frequency + wave_phase_offset) * wave_amplitude

		"swoop":
			# Amplitude fades to zero as enemy crosses to the left half of the viewport
			var blend := clampf(global_position.x / _viewport_w, 0.0, 1.0)
			position.x -= speed * delta
			position.y = _start_y + sin(_time * 1.0 + wave_phase_offset) * wave_amplitude * blend

		"zigzag":
			position.x -= speed * delta
			if dart_interval > 0.0:
				_dart_timer += delta
				if _dart_timer >= dart_interval:
					_dart_timer = 0.0
					_zigzag_dir = -_zigzag_dir
			position.y += _zigzag_dir * wave_amplitude * delta

		"dart":
			if not _dart_active:
				position.x -= speed * delta
				_dart_timer += delta
				if dart_interval > 0.0 and _dart_timer >= dart_interval:
					_dart_timer = 0.0
					_dart_active = true
					if _player != null and is_instance_valid(_player):
						_dart_dir = (_player.global_position - global_position).normalized()
					else:
						_dart_dir = Vector2.LEFT
			else:
				position += _dart_dir * speed * dart_speed_mult * delta
				_dart_timer += delta
				if _dart_timer >= 0.4:
					_dart_active = false
					_dart_timer = 0.0

		"homing":
			if _player != null and is_instance_valid(_player):
				var dir := (_player.global_position - global_position).normalized()
				position += dir * speed * delta
			else:
				position.x -= speed * delta

		"stationary":
			position.x -= speed * delta   # slow drift left


func _fire_bullet() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	match shoot_pattern:
		"aimed":
			_spawn_bullet((_player.global_position - global_position).normalized())
		"spread":
			var base_dir := (_player.global_position - global_position).normalized()
			for angle in [-20.0, 0.0, 20.0]:
				_spawn_bullet(base_dir.rotated(deg_to_rad(angle)))


func _spawn_bullet(dir: Vector2) -> void:
	var b := _BULLET_SCENE.instantiate()
	b.global_position = global_position
	b.direction = dir
	b.speed = bullet_speed if bullet_speed > 0.0 else 200.0
	b.damage = enemy_bullet_strength if enemy_bullet_strength > 0 else 8
	get_tree().root.add_child(b)


func take_damage(amount: int, source_slot: int = -1) -> void:
	current_hp -= amount
	if current_hp <= 0:
		die(source_slot)


func die(source_slot: int = -1) -> void:
	EventBus.enemy_died.emit(enemy_id, xp_value)
	for i in gem_count:
		_drop_gem(source_slot)
	_try_drop_weapon()
	queue_free()


func _drop_gem(source_slot: int) -> void:
	var gem = _GEM_SCENE.instantiate()
	gem.xp_value = xp_value
	gem.source_weapon_slot = source_slot
	gem.global_position = global_position
	get_tree().root.add_child(gem)


func _try_drop_weapon() -> void:
	if randf() < weapon_drop_chance:
		var pickup = _PICKUP_SCENE.instantiate()
		pickup.weapon_type = WeaponDB.random_weapon()["type"]
		pickup.global_position = global_position
		get_tree().root.add_child(pickup)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.take_damage(contact_damage)
		if movement_type == "homing":
			die()

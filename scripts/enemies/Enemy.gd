extends Area2D
class_name Enemy

const _PICKUP_SCENE     = preload("res://scenes/weapons/WeaponPickup.tscn")
const _GEM_SCENE        = preload("res://scenes/pickups/EnergyGem.tscn")
const _BULLET_SCENE     = preload("res://scenes/enemies/EnemyBullet.tscn")
const _EXPLOSION_SCRIPT = preload("res://scripts/fx/Explosion.gd")
const _ENEMY_SCENE      = preload("res://scenes/enemies/Enemy.tscn")

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
var entry_speed: float           = 0.0    # fast entry speed; 0 = no entry phase
var entry_depth: float           = 0.0    # viewport fraction where entry ends (e.g. 0.6)
var separation_radius: float     = 0.0    # push away from same-type enemies within this distance; 0 = off
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
var ph_size_override: float      = 0.0    # 0 = use type default; >0 = override placeholder size
var splits_into: String          = ""     # enemy_id to spawn on death (asteroid-style split)
var split_count: int             = 0      # how many children to spawn on death
var rotation_speed: float        = 0.0   # radians/sec; applied every frame

# Runtime state
var display_name: String = ""
var wave_phase_offset: float = 0.0   # set by spawner for staggered flocks
var current_hp: int
var formation_line: int  = 0         # which wave index this enemy belongs to (0 = first wave)
var _entered: bool = false           # false until entry phase completes
var _formed: bool  = false           # false until formation phase completes
var _formation_y: float = 0.0        # target y slot assigned during entry
var _formed_time: float = 0.0        # wall-clock second when forming completed

var _burst_vel: Vector2 = Vector2.ZERO   # outward velocity applied on split, decays to zero

var _db_loaded: bool   = false
var _has_image: bool   = false   # false = draw procedural placeholder
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

# Flock (boids) movement
var _flock_velocity: Vector2 = Vector2.ZERO


func _ready() -> void:
	load_from_db()
	current_hp = max_hp
	if movement_type == "flock":
		_flock_velocity = Vector2(-speed * 0.6, randf_range(-speed * 0.25, speed * 0.25))
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
	display_name          = data.get("name",                  enemy_id)
	enemy_type            = data.get("enemy_type",            enemy_type)
	movement_type         = data.get("movement_type",         movement_type)
	spawn_behaviour       = data.get("spawn_behaviour",       spawn_behaviour)
	max_hp                = int(data.get("hp",                max_hp))
	xp_value              = int(data.get("xp_value",          xp_value))
	gem_count             = int(data.get("gem_count",         gem_count))
	weapon_drop_chance    = float(data.get("weapon_drop_chance", weapon_drop_chance))
	speed                 = float(data.get("speed",           speed))
	entry_speed           = float(data.get("entry_speed",     entry_speed))
	entry_depth           = float(data.get("entry_depth",     entry_depth))
	separation_radius     = float(data.get("separation_radius", separation_radius))
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
	ph_size_override      = float(data.get("ph_size",         ph_size_override))
	splits_into           = data.get("splits_into",          splits_into)
	split_count           = int(data.get("split_count",      split_count))
	armor_type            = data.get("armor_type",            armor_type)
	# Runtime sprite swap — if the entry has an "image" field, override the scene default.
	var img_path: String = data.get("image", "")
	if img_path != "":
		var tex := load(img_path) as Texture2D
		if tex:
			var frames := SpriteFrames.new()
			frames.add_frame("default", tex)
			var spr := get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
			if spr:
				spr.sprite_frames = frames
				spr.play("default")
				var s: float = float(data.get("sprite_scale", 0.13))
				spr.scale = Vector2(s, s)
			_has_image = true
	# No image → hide the scene sprite and draw a procedural placeholder instead.
	if not _has_image:
		var spr := get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
		if spr:
			spr.hide()
		queue_redraw()


func _find_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player = players[0]


func _process(delta: float) -> void:
	_time += delta
	if rotation_speed != 0.0:
		rotation += rotation_speed * delta
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
	if _burst_vel.length_squared() > 1.0:
		position += _burst_vel * delta
		_burst_vel = _burst_vel.move_toward(Vector2.ZERO, _burst_vel.length() * 3.0 * delta)
	if not _entered:
		if entry_speed <= 0.0 or entry_depth <= 0.0:
			_entered = true   # no entry phase configured — skip straight to normal behaviour
		else:
			position.x -= entry_speed * delta
			if global_position.x <= _viewport_w * entry_depth:
				_entered = true
				_start_y = global_position.y   # anchor sine/swoop to where entry ended
				if movement_type == "formation_sine":
					# fmod keeps slot in [0,1) even when base_phase pushes offset > TAU
					var slot := fmod(wave_phase_offset, TAU) / TAU
					var vp_h := get_viewport().get_visible_rect().size.y
					# 15%–85% keeps amplitude-90 oscillation fully on screen
					_formation_y = vp_h * 0.15 + slot * vp_h * 0.70
		return

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

		"flock":
			_flock_steer(delta)
			position += _flock_velocity * delta

		"formation_sine":
			if not _formed:
				# Slide vertically into assigned slot
				var dy := _formation_y - position.y
				if absf(dy) < 3.0:
					position.y = _formation_y
					_formed = true
					_formed_time = Time.get_ticks_msec() * 0.001
				else:
					position.y += signf(dy) * 180.0 * delta
			else:
				# Slow straight drift left after forming — exits off-screen naturally
				position.x -= speed * delta

	if separation_radius > 0.0:
		_apply_separation()


func _apply_separation() -> void:
	for node in get_tree().get_nodes_in_group("level_objects"):
		if node == self or not (node is Enemy):
			continue
		var peer := node as Enemy
		if peer.enemy_id != enemy_id:
			continue
		var diff := global_position - peer.global_position
		var dist := diff.length()
		if dist < separation_radius and dist > 0.001:
			position += diff.normalized() * (separation_radius - dist) * 0.5


func _flock_steer(delta: float) -> void:
	var sep       := Vector2.ZERO
	var align     := Vector2.ZERO
	var center    := Vector2.ZERO
	var n_count   := 0
	var sep_count := 0

	for node in get_tree().get_nodes_in_group("level_objects"):
		if node == self or not (node is Enemy) or node.movement_type != "flock":
			continue
		var peer := node as Enemy
		var diff := global_position - peer.global_position
		var dist := diff.length()
		if dist > GameManager.flock_radius:
			continue
		# Separation — inverse-distance weighted push
		if dist < GameManager.flock_sep_radius and dist > 0.001:
			sep += diff / (dist * dist)
			sep_count += 1
		# Alignment & cohesion
		align  += peer._flock_velocity
		center += peer.global_position
		n_count += 1

	var desired := Vector2.ZERO

	if sep_count > 0:
		desired += sep.normalized() * speed * GameManager.flock_sep_w

	if n_count > 0:
		desired += (align  / n_count).normalized()                     * speed * GameManager.flock_align_w
		desired += ((center / n_count) - global_position).normalized() * speed * GameManager.flock_cohesion_w

	# Seek player
	if _player != null and is_instance_valid(_player):
		desired += (_player.global_position - global_position).normalized() * speed * GameManager.flock_seek_w
	else:
		desired += Vector2.LEFT * speed * GameManager.flock_seek_w

	# Blend toward desired velocity
	if desired.length() > 0.001:
		_flock_velocity = _flock_velocity.lerp(desired.normalized() * speed, delta * GameManager.flock_steer_rate)
	if _flock_velocity.length() > speed:
		_flock_velocity = _flock_velocity.normalized() * speed


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
	_flash_hit()
	EventBus.camera_shake.emit(2.5, 0.10)
	if current_hp <= 0:
		die(source_slot)


func _flash_hit() -> void:
	var tween := create_tween()
	# Instantly brighten then fade back to normal
	tween.tween_property(self, "modulate", Color(2.0, 2.0, 2.0, 1.0), 0.0)
	tween.tween_property(self, "modulate", Color.WHITE, 0.15)


func die(source_slot: int = -1) -> void:
	EventBus.enemy_died.emit(enemy_id, xp_value)
	EventBus.camera_shake.emit(_death_shake_strength(), 0.25)
	_spawn_explosion()
	for i in gem_count:
		_drop_gem(source_slot)
	_try_drop_weapon()
	_spawn_splits()
	queue_free()


func _spawn_splits() -> void:
	if splits_into.is_empty() or split_count <= 0:
		return
	var spread := maxf(ph_size_override * 0.5, 20.0)
	var axis := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
	var burst := ph_size_override * 4.0
	for i in split_count:
		var child := _ENEMY_SCENE.instantiate()
		child.enemy_id = splits_into
		var dir := axis if i % 2 == 0 else -axis
		child.global_position = global_position + dir * spread
		child._burst_vel = dir * burst
		child.rotation_speed = randf_range(2.5, 5.0) * (1.0 if randf() > 0.5 else -1.0)
		get_tree().root.add_child(child)


func _death_shake_strength() -> float:
	match enemy_type:
		"boss_big":   return 18.0
		"boss_small": return 12.0
		"heavy":      return 8.0
		"elite":      return 7.0
		_:            return 5.0


func _spawn_explosion() -> void:
	var exp := Node2D.new()
	exp.set_script(_EXPLOSION_SCRIPT)
	exp.set("max_radius", _ph_size() * 2.5)
	exp.global_position = global_position
	get_tree().root.add_child(exp)


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


# ── Procedural placeholder rendering ─────────────────────────────────────────

func _draw() -> void:
	if not _has_image:
		_draw_shape(_ph_color(), _ph_size())
	if OS.is_debug_build() and GameManager.show_enemy_labels and not display_name.is_empty():
		var font  := ThemeDB.fallback_font
		var y_off := -(_ph_size() + 6.0)
		draw_string(font, Vector2(0.0, y_off - 12.0), display_name,
				HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color(1.0, 1.0, 0.2, 0.9))
		draw_string(font, Vector2(0.0, y_off),        "[%s]" % enemy_id,
				HORIZONTAL_ALIGNMENT_CENTER, -1, 9,  Color(0.7, 0.7, 0.7, 0.6))

func _ph_color() -> Color:
	match enemy_type:
		"boss_big":   return Color(1.0, 0.15, 0.15)
		"boss_small": return Color(1.0, 0.45, 0.1)
		"elite":      return Color(0.75, 0.35, 1.0)
		"heavy":      return Color(1.0, 0.55, 0.15)
		"drone":      return Color(0.25, 1.0, 0.75)
		_:            return Color(0.9, 1.0, 0.25)   # fighter

func _ph_size() -> float:
	if ph_size_override > 0.0:
		return ph_size_override
	match enemy_type:
		"boss_big":   return 64.0
		"boss_small": return 40.0
		"heavy":      return 24.0
		"elite":      return 20.0
		"drone":      return 10.0
		_:            return 16.0   # fighter

func _draw_shape(color: Color, r: float) -> void:
	var outline := Color(1.0, 1.0, 1.0, 0.35)
	match enemy_type:
		"drone":
			draw_circle(Vector2.ZERO, r, color)
			draw_arc(Vector2.ZERO, r, 0.0, TAU, 24, outline, 1.5)

		"heavy":
			var pts := PackedVector2Array([
				Vector2(-r,       -r * 0.55),
				Vector2( r * 0.4, -r * 0.55),
				Vector2( r * 0.4,  r * 0.55),
				Vector2(-r,        r * 0.55),
			])
			draw_colored_polygon(pts, color)
			draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]), outline, 1.5)

		"elite":
			var pts := PackedVector2Array([
				Vector2(-r,        0.0),
				Vector2(-r * 0.2, -r),
				Vector2( r * 0.7, -r * 0.4),
				Vector2( r * 0.7,  r * 0.4),
				Vector2(-r * 0.2,  r),
			])
			draw_colored_polygon(pts, color)
			draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[4], pts[0]]), outline, 1.5)

		"boss_small", "boss_big":
			var sides := 6 if enemy_type == "boss_small" else 8
			var pts := PackedVector2Array()
			for i in sides:
				var angle := i * TAU / sides - PI / 2.0
				pts.append(Vector2(cos(angle), sin(angle)) * r)
			draw_colored_polygon(pts, color)
			pts.append(pts[0])   # close the outline loop
			draw_polyline(pts, Color(1.0, 1.0, 1.0, 0.45), 2.0)

		_:  # fighter — arrow pointing left (direction of travel)
			var pts := PackedVector2Array([
				Vector2(-r,        0.0),
				Vector2( r * 0.5, -r * 0.7),
				Vector2( r * 0.2, -r * 0.25),
				Vector2( r * 0.6,  0.0),
				Vector2( r * 0.2,  r * 0.25),
				Vector2( r * 0.5,  r * 0.7),
			])
			draw_colored_polygon(pts, color)
			draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[4], pts[5], pts[0]]), outline, 1.5)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.take_damage(contact_damage)
		if movement_type == "homing":
			die()

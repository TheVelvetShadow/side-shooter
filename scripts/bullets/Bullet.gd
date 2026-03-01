extends Area2D
class_name Bullet

@export var speed: float = 800.0
@export var damage: int = 10
@export var bullet_color: Color = Color(1.0, 0.9, 0.1, 1.0)
@export var bounce_count: int = 1

var velocity: Vector2 = Vector2.ZERO
var bounces_done: int = 0
var weapon_slot: int = -1
var bounce_damage_multiplier: float = 1.0
var burn_pct: float = 0.0
var burn_duration: float = 0.0
var aoe_radius: float = 0.0
var homing: bool = false
var homing_strength: float = 2.5   # lerp factor — higher = tighter turns
var split_count: int = 0
var split_spread: float = 45.0     # total fan angle in degrees
var split_child_damage: int = -1   # -1 = inherit parent damage
var is_child: bool = false         # children never split

func _ready() -> void:
	$Visual.color = bullet_color
	velocity = Vector2(speed, 0.0)
	area_entered.connect(_on_area_entered)
	add_to_group("level_objects")

func _process(delta: float) -> void:
	if homing:
		_home(delta)
	position += velocity * delta
	_check_wall_bounce()
	var vp_x := get_viewport_rect().size.x
	if global_position.x > vp_x + 64.0 or global_position.x < -64.0:
		queue_free()

func _home(delta: float) -> void:
	var target := _find_nearest_enemy()
	if target == null:
		return
	var desired := (target.global_position - global_position).normalized() * speed
	velocity = velocity.lerp(desired, homing_strength * delta)
	velocity = velocity.normalized() * speed   # keep speed constant

func _find_nearest_enemy() -> Node:
	var nearest: Node = null
	var nearest_dist := INF
	for node in get_tree().get_nodes_in_group("level_objects"):
		if not node.has_method("take_damage"):
			continue
		var dist := global_position.distance_to(node.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = node
	return nearest

func _check_wall_bounce() -> void:
	var vp_height := get_viewport_rect().size.y
	if global_position.y <= 0.0 and velocity.y < 0.0:
		global_position.y = 0.0
		_on_wall_hit()
	elif global_position.y >= vp_height and velocity.y > 0.0:
		global_position.y = vp_height
		_on_wall_hit()

func _on_wall_hit() -> void:
	if bounces_done >= bounce_count:
		queue_free()
		return
	velocity.y = -velocity.y
	bounces_done += 1
	EventBus.bullet_bounced.emit(self, bounces_done)

func _on_area_entered(area: Area2D) -> void:
	if area.has_method("take_damage"):
		var final_damage := damage
		if bounces_done > 0:
			final_damage = int(damage * bounce_damage_multiplier)
		area.take_damage(final_damage, weapon_slot)
		if burn_pct > 0.0:
			BurnComponent.apply_to(area, final_damage, burn_pct, burn_duration)
		if aoe_radius > 0.0:
			_aoe_explode(final_damage, area)
		if split_count > 0 and not is_child:
			_spawn_split_bullets(final_damage)
		queue_free()

func _spawn_split_bullets(parent_damage: int) -> void:
	var child_damage := split_child_damage if split_child_damage >= 0 else parent_damage
	var total_spread := deg_to_rad(split_spread)
	var base_angle := velocity.angle()
	for i in split_count:
		var t := float(i) / float(split_count - 1) if split_count > 1 else 0.5
		var angle := base_angle - total_spread * 0.5 + total_spread * t
		var child: Bullet = duplicate() as Bullet
		child.damage = child_damage
		child.velocity = Vector2(speed, 0.0).rotated(angle)
		child.is_child = true
		child.homing = false
		child.global_position = global_position
		child.bounces_done = 0
		get_tree().root.add_child(child)

func _aoe_explode(dmg: int, direct_hit: Node) -> void:
	var effect := ExplosionEffect.new()
	effect.radius = aoe_radius
	effect.explosion_color = bullet_color
	effect.global_position = global_position
	get_tree().root.add_child(effect)

	for node in get_tree().get_nodes_in_group("level_objects"):
		if node == direct_hit or node == self:
			continue
		if not node.has_method("take_damage"):
			continue
		var dist := node.global_position.distance_to(global_position)
		if dist <= aoe_radius:
			var falloff := lerpf(1.0, 0.5, dist / aoe_radius)
			var aoe_dmg := int(dmg * falloff)
			node.take_damage(aoe_dmg, weapon_slot)
			if burn_pct > 0.0:
				BurnComponent.apply_to(node, aoe_dmg, burn_pct, burn_duration)

extends Area2D
class_name Bullet

@export var speed: float = 800.0
@export var damage: int = 10
@export var bullet_color: Color = Color(1.0, 0.9, 0.1, 1.0)
@export var bounce_count: int = 1  # max wall bounces allowed (default 1)

var velocity: Vector2 = Vector2.ZERO
var bounces_done: int = 0
var weapon_slot: int = -1
var bounce_damage_multiplier: float = 1.0
var burn_pct: float = 0.0
var burn_duration: float = 0.0
var aoe_radius: float = 0.0

func _ready() -> void:
	$Visual.color = bullet_color
	velocity = Vector2(speed, 0.0)
	area_entered.connect(_on_area_entered)
	add_to_group("level_objects")

func _process(delta: float) -> void:
	position += velocity * delta
	_check_wall_bounce()
	if global_position.x > get_viewport_rect().size.x + 64.0:
		queue_free()

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
		queue_free()

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

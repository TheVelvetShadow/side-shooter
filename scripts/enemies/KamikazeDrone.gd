extends Area2D
class_name KamikazeDrone

const _PICKUP_SCENE = preload("res://scenes/weapons/WeaponPickup.tscn")
const _GEM_SCENE    = preload("res://scenes/pickups/EnergyGem.tscn")

@export var enemy_id: String = "kamikaze"
@export var max_hp: int = 15
@export var xp_value: int = 15
@export var speed: float = 220.0
@export var contact_damage: int = 25

var current_hp: int
var _player: Node2D = null

func _ready() -> void:
	current_hp = max_hp
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	EventBus.enemy_spawned.emit(enemy_id)
	call_deferred("_find_player")

func _find_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player = players[0]

func _process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		position.x -= speed * delta
		if global_position.x < -64:
			queue_free()
		return
	var dir := (_player.global_position - global_position).normalized()
	position += dir * speed * delta
	if global_position.x < -64:
		queue_free()

func take_damage(amount: int, source_slot: int = -1) -> void:
	current_hp -= amount
	if current_hp <= 0:
		die(source_slot)

func die(source_slot: int = -1) -> void:
	EventBus.enemy_died.emit(enemy_id, xp_value)
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
	if randf() < 0.3:
		var pickup = _PICKUP_SCENE.instantiate()
		pickup.weapon_type = WeaponDB.random_weapon()["type"]
		pickup.global_position = global_position
		get_tree().root.add_child(pickup)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.take_damage(contact_damage)
		die()

func _on_area_entered(area: Area2D) -> void:
	if area is Bullet:
		var b := area as Bullet
		var dmg: int = b.damage
		if b.bounces_done > 0:
			dmg = int(dmg * b.bounce_damage_multiplier)
		take_damage(dmg, b.weapon_slot)
		area.queue_free()

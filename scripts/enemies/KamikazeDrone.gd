extends Area2D
class_name KamikazeDrone

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

func take_damage(amount: int) -> void:
	current_hp -= amount
	if current_hp <= 0:
		die()

func die() -> void:
	EventBus.enemy_died.emit(enemy_id, xp_value)
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.take_damage(contact_damage)
		die()

func _on_area_entered(area: Area2D) -> void:
	if area is Bullet:
		take_damage(area.damage)
		area.queue_free()

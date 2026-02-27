extends Area2D
class_name TurretPlatform

@export var enemy_id: String = "turret"
@export var max_hp: int = 50
@export var xp_value: int = 20
@export var speed: float = 40.0
@export var contact_damage: int = 5
@export var fire_interval: float = 2.0
@export var bullet_scene: PackedScene

var current_hp: int
var _player: Node2D = null
@onready var fire_timer: Timer = $FireTimer

func _ready() -> void:
	current_hp = max_hp
	fire_timer.wait_time = fire_interval
	fire_timer.timeout.connect(_on_fire_timer)
	fire_timer.start()
	area_entered.connect(_on_area_entered)
	EventBus.enemy_spawned.emit(enemy_id)
	call_deferred("_find_player")

func _find_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player = players[0]

func _process(delta: float) -> void:
	position.x -= speed * delta
	if global_position.x < -64:
		queue_free()

func _on_fire_timer() -> void:
	if _player == null or not is_instance_valid(_player) or bullet_scene == null:
		return
	var b := bullet_scene.instantiate()
	b.global_position = global_position
	b.direction = (_player.global_position - global_position).normalized()
	get_tree().root.add_child(b)

func take_damage(amount: int) -> void:
	current_hp -= amount
	if current_hp <= 0:
		die()

func die() -> void:
	EventBus.enemy_died.emit(enemy_id, xp_value)
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area is Bullet:
		take_damage(area.damage)
		area.queue_free()

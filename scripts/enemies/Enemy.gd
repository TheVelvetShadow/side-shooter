extends Area2D
class_name Enemy

@export var enemy_id: String = "basic_enemy"
@export var max_hp: int = 30
@export var xp_value: int = 10

var current_hp: int

func _ready() -> void:
	current_hp = max_hp
	EventBus.enemy_spawned.emit(enemy_id)

func take_damage(amount: int) -> void:
	current_hp -= amount
	if current_hp <= 0:
		die()

func die() -> void:
	EventBus.enemy_died.emit(enemy_id, xp_value)
	queue_free()

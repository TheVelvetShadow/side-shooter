extends Area2D
class_name Enemy

@export var enemy_id: String = "basic_enemy"
@export var max_hp: int = 30
@export var xp_value: int = 10
@export var speed: float = 150.0
@export var wave_amplitude: float = 60.0
@export var wave_frequency: float = 2.0
@export var wave_phase_offset: float = 0.0
@export var contact_damage: int = 10

var current_hp: int
var _start_y: float
var _time: float = 0.0

func _ready() -> void:
	current_hp = max_hp
	_start_y = global_position.y
	body_entered.connect(_on_body_entered)
	EventBus.enemy_spawned.emit(enemy_id)

func _process(delta: float) -> void:
	_time += delta
	position.x -= speed * delta
	position.y = _start_y + sin(_time * wave_frequency + wave_phase_offset) * wave_amplitude
	if global_position.x < -64.0:
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

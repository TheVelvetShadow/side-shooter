extends Area2D
class_name EnemyBullet

@export var speed: float = 400.0
@export var damage: int = 8
var direction: Vector2 = Vector2.LEFT

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	position += direction * speed * delta
	var vp := get_viewport_rect().size
	if global_position.x < -64 or global_position.x > vp.x + 64 \
			or global_position.y < -64 or global_position.y > vp.y + 64:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.take_damage(damage)
		queue_free()

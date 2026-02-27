extends Area2D
class_name Bullet

@export var speed: float = 800.0
@export var damage: int = 10

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _process(delta: float) -> void:
	position.x += speed * delta
	if global_position.x > get_viewport_rect().size.x + 64.0:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area is Enemy:
		area.take_damage(damage)
		queue_free()

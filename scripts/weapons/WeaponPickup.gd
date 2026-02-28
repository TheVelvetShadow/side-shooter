extends Area2D

@export var weapon_type: String = "ballistic"
@export var tier: int = 1
@export var drift_speed: float = 60.0

var _weapon_data: Dictionary = {}

func _ready() -> void:
	_weapon_data = WeaponDB.get_weapon(weapon_type, tier)
	$Visual.color = _weapon_data["color"]
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	position.x -= drift_speed * delta
	if global_position.x < -64:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("equip_weapon"):
		body.equip_weapon(_weapon_data)
		queue_free()

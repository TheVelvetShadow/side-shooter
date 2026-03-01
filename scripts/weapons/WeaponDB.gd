extends Node

var _weapons: Dictionary = {}

func _ready() -> void:
	var file := FileAccess.open("res://data/weapons.json", FileAccess.READ)
	if file == null:
		push_error("WeaponDB: cannot open res://data/weapons.json")
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		push_error("WeaponDB: JSON parse error — %s" % json.get_error_message())
		return
	_weapons = json.data
	file.close()

func get_weapon(type: String, tier: int) -> Dictionary:
	if not _weapons.has(type):
		push_error("WeaponDB: unknown type '%s'" % type)
		return {}
	var base: Dictionary = _weapons[type]
	var t := clampi(tier - 1, 0, 4)
	var dmg_scale := float(base.get("dmg_scale", 0.44))
	var rate_scale := float(base.get("rate_scale", 0.16))
	var ca: Array = base.get("color", [1.0, 1.0, 1.0, 1.0])
	return {
		"type": type,
		"tier": tier,
		"name": "%s T%d" % [base["name"], tier],
		"damage": int(float(base["base_damage"]) * pow(1.0 + dmg_scale, t)),
		"fire_rate": float(base["base_fire_rate"]) * pow(1.0 - rate_scale, t),
		"bullet_speed": float(base["bullet_speed"]),
		"color": Color(ca[0], ca[1], ca[2], ca[3]),
		"xp_thresholds": base.get("xp_thresholds", [50, 150, 300, 500]),
	}

func random_weapon(max_tier: int = 1) -> Dictionary:
	var types := _weapons.keys()
	if types.is_empty():
		return {}
	return get_weapon(types[randi() % types.size()], randi_range(1, max_tier))

func get_all_types() -> Array:
	return _weapons.keys()

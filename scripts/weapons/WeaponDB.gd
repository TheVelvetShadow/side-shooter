extends Node

const WEAPON_TYPES: Dictionary = {
	"ballistic": {
		"name": "Ballistic",
		"base_damage": 10,
		"base_fire_rate": 0.20,
		"bullet_speed": 900.0,
		"color": Color(1.0, 1.0, 0.2, 1.0),
	},
	"energy": {
		"name": "Energy",
		"base_damage": 18,
		"base_fire_rate": 0.38,
		"bullet_speed": 1100.0,
		"color": Color(0.2, 0.8, 1.0, 1.0),
	},
	"missile": {
		"name": "Missile",
		"base_damage": 35,
		"base_fire_rate": 0.75,
		"bullet_speed": 500.0,
		"color": Color(1.0, 0.35, 0.1, 1.0),
	},
}

const TIER_DMG:  Array[float] = [1.0, 1.5, 2.2, 3.0, 4.0]
const TIER_RATE: Array[float] = [1.0, 0.85, 0.72, 0.60, 0.50]

func get_weapon(type: String, tier: int) -> Dictionary:
	var base = WEAPON_TYPES[type]
	var t = clampi(tier - 1, 0, 4)
	return {
		"type": type,
		"tier": tier,
		"name": "%s T%d" % [base["name"], tier],
		"damage": int(base["base_damage"] * TIER_DMG[t]),
		"fire_rate": base["base_fire_rate"] * TIER_RATE[t],
		"bullet_speed": base["bullet_speed"],
		"color": base["color"],
	}

func random_weapon(max_tier: int = 1) -> Dictionary:
	var types = WEAPON_TYPES.keys()
	var type: String = types[randi() % types.size()]
	var tier: int = randi_range(1, max_tier)
	return get_weapon(type, tier)

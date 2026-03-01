extends Node

const MAX_PILOTS := 5
const DATA_PATH := "res://data/pilots.json"

var _all_pilots: Dictionary = {}
var active_pilots: Array[Dictionary] = []

func _ready() -> void:
	_load_pilots()

func _load_pilots() -> void:
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("PilotManager: cannot open %s" % DATA_PATH)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		_all_pilots = parsed
	else:
		push_error("PilotManager: failed to parse pilots.json")

func get_all_pilots() -> Dictionary:
	return _all_pilots

func get_available_pilots() -> Array[Dictionary]:
	var active_ids: Array[String] = []
	for p in active_pilots:
		active_ids.append(p["id"])
	var result: Array[Dictionary] = []
	for id in _all_pilots:
		if id not in active_ids:
			result.append(_all_pilots[id])
	return result

func apply_pilots(base_damage: int, weapon_type: String) -> int:
	var dmg := float(base_damage)
	# 1. Flat % additions (global damage)
	for p in active_pilots:
		if p.get("effect") == "damage_flat_pct":
			dmg += float(base_damage) * p["value"]
	# 2. Weapon type multipliers
	for p in active_pilots:
		if p.get("effect") == "weapon_type_mult" and p.get("weapon_category") == weapon_type:
			dmg *= p["value"]
	return int(dmg)

func get_bounce_multiplier() -> float:
	var mult := 1.0
	for p in active_pilots:
		if p.get("effect") == "bounce_mult":
			mult *= p["value"]
	return mult

func add_pilot(pilot_data: Dictionary, player: Node) -> void:
	if active_pilots.size() >= MAX_PILOTS:
		return
	active_pilots.append(pilot_data)
	# Apply one-time stat effects immediately
	match pilot_data.get("effect", ""):
		"speed_boost":
			player.move_speed += pilot_data["value"]
		"shield_boost":
			player.max_shield += int(pilot_data["value"])
			player.current_shield = player.max_shield
			EventBus.player_shield_changed.emit(player.current_shield, player.max_shield)

func reset() -> void:
	active_pilots.clear()

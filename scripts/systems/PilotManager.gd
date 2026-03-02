extends Node

const MAX_PILOTS := 5
const DATA_PATH := "res://data/pilots.json"

const RARITY_WEIGHTS := {
	"common": 70.0,
	"rare": 25.0,
	"epic": 4.5,
	"legendary": 0.5,
}

# Each combo: requires (Array of pilot IDs all active), effect, value, name
# bounce_combo effects are applied in get_bounce_chain_steps()
const COMBOS: Array[Dictionary] = [
	{
		"id": "infinite_bouncer",
		"name": "The Infinite Bouncer",
		"requires": ["ricochet_artist", "bounce_master"],
		"effect": "bounce_combo_mult",
		"value": 1.5,
		"desc": "Ricochet + Bounce Master: bounced shots deal ×1.5 extra"
	},
]

var _all_pilots: Dictionary = {}
var active_pilots: Array[Dictionary] = []
var active_combos: Array[Dictionary] = []

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

# Rarity-weighted offer selection without replacement.
func get_weighted_offers(count: int) -> Array[Dictionary]:
	var pool := get_available_pilots()
	var result: Array[Dictionary] = []
	for _i in count:
		if pool.is_empty():
			break
		var pick := _weighted_pick(pool)
		result.append(pick)
		pool.erase(pick)
	return result

func _weighted_pick(pool: Array) -> Dictionary:
	var total := 0.0
	for p in pool:
		total += RARITY_WEIGHTS.get(p.get("rarity", "common"), 70.0)
	var roll := randf() * total
	var cumulative := 0.0
	for p in pool:
		cumulative += RARITY_WEIGHTS.get(p.get("rarity", "common"), 70.0)
		if roll <= cumulative:
			return p
	return pool[-1]

# ── Combo detection ───────────────────────────────────────────────────────────

func _detect_combos() -> void:
	active_combos.clear()
	var active_ids: Array[String] = []
	for p in active_pilots:
		active_ids.append(p["id"])
	for combo in COMBOS:
		var all_present := true
		for req_id in combo["requires"]:
			if req_id not in active_ids:
				all_present = false
				break
		if all_present:
			active_combos.append(combo)

# ── Damage calculation ────────────────────────────────────────────────────────

# Returns {steps: Array[Dictionary], final: int}
# Covers: Base → flat global additions → weapon-type multipliers → (non-bounce) combo multipliers
# Bounce conditionals appended at hit time via get_bounce_chain_steps().
func get_damage_chain(base_damage: int, weapon_type: String) -> Dictionary:
	var steps: Array[Dictionary] = []
	var value := float(base_damage)

	steps.append({"label": "Base", "value": int(value), "op": ""})

	# 1. Flat % additions (global pilots)
	for p in active_pilots:
		if p.get("effect") == "damage_flat_pct":
			var added := float(base_damage) * float(p["value"])
			value += added
			steps.append({
				"label": p["name"],
				"value": int(value),
				"op": "+%d%%" % int(float(p["value"]) * 100.0)
			})

	# 2. Weapon-type multipliers
	for p in active_pilots:
		if p.get("effect") == "weapon_type_mult" and p.get("weapon_category") == weapon_type:
			value *= float(p["value"])
			steps.append({
				"label": p["name"],
				"value": int(value),
				"op": "×%.1f" % float(p["value"])
			})

	# 3. Non-bounce combo multipliers (none currently, stub for future)

	return {"steps": steps, "final": int(value)}

# Returns extra chain steps for bounce conditionals + bounce combos, starting from pre_bounce_damage.
func get_bounce_chain_steps(pre_bounce_damage: int) -> Array[Dictionary]:
	var steps: Array[Dictionary] = []
	var value := float(pre_bounce_damage)

	# Bounce-conditional pilot multipliers
	for p in active_pilots:
		if p.get("effect") == "bounce_mult":
			value *= float(p["value"])
			steps.append({
				"label": p["name"],
				"value": int(value),
				"op": "×%.1f" % float(p["value"])
			})

	# Bounce combo multipliers
	for combo in active_combos:
		if combo.get("effect") == "bounce_combo_mult":
			value *= float(combo["value"])
			steps.append({
				"label": combo["name"],
				"value": int(value),
				"op": "×%.1f" % float(combo["value"])
			})

	return steps

# Convenience wrapper — apply damage chain and return final int.
func apply_pilots(base_damage: int, weapon_type: String) -> int:
	return get_damage_chain(base_damage, weapon_type)["final"]

func get_bounce_multiplier() -> float:
	var mult := 1.0
	for p in active_pilots:
		if p.get("effect") == "bounce_mult":
			mult *= float(p["value"])
	for combo in active_combos:
		if combo.get("effect") == "bounce_combo_mult":
			mult *= float(combo["value"])
	return mult

# ── Roster management ─────────────────────────────────────────────────────────

func add_pilot(pilot_data: Dictionary, player: Node) -> void:
	if active_pilots.size() >= MAX_PILOTS:
		return
	active_pilots.append(pilot_data)
	_apply_immediate_effects(pilot_data, player)
	_detect_combos()

func replace_pilot(index: int, new_pilot: Dictionary, player: Node) -> void:
	if index < 0 or index >= active_pilots.size():
		return
	active_pilots[index] = new_pilot
	_apply_immediate_effects(new_pilot, player)
	_detect_combos()

func _apply_immediate_effects(pilot_data: Dictionary, player: Node) -> void:
	match pilot_data.get("effect", ""):
		"speed_boost":
			player.move_speed += float(pilot_data["value"])
		"shield_boost":
			player.max_shield += int(pilot_data["value"])
			player.current_shield = player.max_shield
			EventBus.player_shield_changed.emit(player.current_shield, player.max_shield)

func reset() -> void:
	active_pilots.clear()
	active_combos.clear()

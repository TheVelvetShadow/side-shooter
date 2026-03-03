extends Node

var _enemies: Dictionary = {}
var _disabled: Dictionary = {}   # enemy_id -> true when excluded from spawn pool

func _ready() -> void:
	var file := FileAccess.open("res://data/enemies.json", FileAccess.READ)
	if file == null:
		push_error("EnemyDB: cannot open res://data/enemies.json")
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		push_error("EnemyDB: JSON parse error — %s" % json.get_error_message())
		return
	_enemies = json.data
	file.close()

func get_all_ids() -> Array:
	return _enemies.keys()

func get_enemy(enemy_id: String) -> Dictionary:
	return _enemies.get(enemy_id, {})

func get_enemies_for_level(ante: int, level: int) -> Array:
	var result: Array = []
	for enemy_id in _enemies:
		if _disabled.has(enemy_id):
			continue
		var data: Dictionary = _enemies[enemy_id]
		var etype: String = data.get("enemy_type", "")
		if etype == "boss_small" or etype == "boss_big":
			continue
		if int(data.get("first_ante", 1)) <= ante and int(data.get("first_level", 1)) <= level:
			var entry := data.duplicate()
			entry["enemy_id"] = enemy_id
			result.append(entry)
	return result

# ── Debug helpers ─────────────────────────────────────────────────────────────

func is_enabled(enemy_id: String) -> bool:
	return not _disabled.has(enemy_id)

func set_enabled(enemy_id: String, enabled: bool) -> void:
	if enabled:
		_disabled.erase(enemy_id)
	else:
		_disabled[enemy_id] = true

func enable_only(enemy_id: String) -> void:
	_disabled.clear()
	for id in _enemies:
		if id != enemy_id:
			_disabled[id] = true

func enable_all() -> void:
	_disabled.clear()

func disable_all_non_boss() -> void:
	for id in _enemies:
		var etype: String = _enemies[id].get("enemy_type", "")
		if etype != "boss_small" and etype != "boss_big":
			_disabled[id] = true

extends Node

var _enemies: Dictionary = {}

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

func get_enemy(enemy_id: String) -> Dictionary:
	return _enemies.get(enemy_id, {})

func get_enemies_for_level(ante: int, level: int) -> Array:
	var result: Array = []
	for enemy_id in _enemies:
		var data: Dictionary = _enemies[enemy_id]
		var etype: String = data.get("enemy_type", "")
		if etype == "boss_small" or etype == "boss_big":
			continue
		if int(data.get("first_ante", 1)) <= ante and int(data.get("first_level", 1)) <= level:
			var entry := data.duplicate()
			entry["enemy_id"] = enemy_id
			result.append(entry)
	return result

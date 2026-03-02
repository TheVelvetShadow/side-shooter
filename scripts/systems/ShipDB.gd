extends Node

const DATA_PATH := "res://data/ships.json"

var _ships: Dictionary = {}

func _ready() -> void:
	_load()

func _load() -> void:
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("ShipDB: cannot open %s" % DATA_PATH)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		_ships = parsed
	else:
		push_error("ShipDB: failed to parse ships.json")

func get_ship(id: String) -> Dictionary:
	return _ships.get(id, {})

func get_all_ships() -> Dictionary:
	return _ships

# Ordered list for display (keeps ships in a consistent order)
func get_ordered_ships() -> Array[Dictionary]:
	var order := ["interceptor", "tank", "glass_cannon", "scout", "dreadnought"]
	var result: Array[Dictionary] = []
	for id in order:
		if _ships.has(id):
			result.append(_ships[id])
	return result

extends Node

const CrosshairScript  := preload("res://scripts/ui/Crosshair.gd")
const ShipSelectScript := preload("res://scripts/ui/ShipSelectUI.gd")

func _ready() -> void:
	EventBus.game_over.connect(_on_game_over)
	EventBus.level_started.connect(_on_level_started)

	if OS.is_debug_build() and GameManager.skip_ship_select:
		var ship_data := ShipDB.get_ship(GameManager.debug_default_ship)
		_on_ship_selected(GameManager.debug_default_ship, ship_data)
		return

	var ship_select := CanvasLayer.new()
	ship_select.set_script(ShipSelectScript)
	ship_select.connect("ship_selected", _on_ship_selected)
	add_child(ship_select)

# ship_data is the full ship Dictionary emitted by ShipSelectUI — no ShipDB lookup needed.
func _on_ship_selected(ship_id: String, ship_data: Dictionary) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.apply_ship(ship_data)
	GameManager.start_run(ship_id)
	LevelManager.start_run()

	var crosshair := Node2D.new()
	crosshair.set_script(CrosshairScript)
	add_child(crosshair)

func _on_level_started(_ante: int, _level: int) -> void:
	for node in get_tree().get_nodes_in_group("level_objects"):
		node.queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F5:
			LevelManager.debug_skip_level()

func _on_game_over() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/GameOver.tscn")

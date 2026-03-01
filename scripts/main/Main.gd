extends Node

const CrosshairScript := preload("res://scripts/ui/Crosshair.gd")

func _ready() -> void:
	EventBus.game_over.connect(_on_game_over)
	EventBus.level_started.connect(_on_level_started)
	var crosshair := Node2D.new()
	crosshair.set_script(CrosshairScript)
	add_child(crosshair)
	GameManager.start_run("interceptor")
	LevelManager.start_run()

func _on_level_started(_ante: int, _level: int) -> void:
	# Clear all transient level objects so each level starts clean
	for node in get_tree().get_nodes_in_group("level_objects"):
		node.queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F5:
			_debug_skip_level()

func _debug_skip_level() -> void:
	LevelManager.debug_skip_level()

func _on_game_over() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/GameOver.tscn")

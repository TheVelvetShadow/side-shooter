extends Node

const CrosshairScript := preload("res://scripts/ui/Crosshair.gd")

func _ready() -> void:
	EventBus.game_over.connect(_on_game_over)
	var crosshair := Node2D.new()
	crosshair.set_script(CrosshairScript)
	add_child(crosshair)

func _on_game_over() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/GameOver.tscn")

extends CanvasLayer

func _ready() -> void:
	$Panel/VBoxContainer/ScoreLabel.text = "Score: %d" % GameManager.run_xp
	$Panel/VBoxContainer/HighScoreLabel.text = "Best: %d" % GameManager.high_score
	$Panel/VBoxContainer/RestartButton.pressed.connect(_on_restart)
	$Panel/VBoxContainer/QuitButton.pressed.connect(_on_quit)

func _on_restart() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")

func _on_quit() -> void:
	get_tree().quit()

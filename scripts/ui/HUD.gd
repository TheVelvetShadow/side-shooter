extends CanvasLayer

func _ready() -> void:
	EventBus.xp_gained.connect(_on_xp_gained)
	EventBus.player_hp_changed.connect(_on_player_hp_changed)
	EventBus.player_shield_changed.connect(_on_player_shield_changed)

func _on_xp_gained(_amount: int) -> void:
	$ScoreLabel.text = "Score: %d" % GameManager.run_xp

func _on_player_hp_changed(current: int, maximum: int) -> void:
	$HPBar.max_value = maximum
	$HPBar.value = current

func _on_player_shield_changed(current: int, maximum: int) -> void:
	$ShieldBar.max_value = maximum
	$ShieldBar.value = current

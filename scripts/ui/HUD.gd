extends CanvasLayer

const UPGRADE_DISPLAY: Dictionary = {
	"hp":     {"label": "HP+\n+20 HP",  "color": Color(0.2, 0.9, 0.3, 1.0)},
	"shield": {"label": "SHD+\n+15",    "color": Color(0.2, 0.6, 1.0, 1.0)},
	"attack": {"label": "ATK+\n×1.2",   "color": Color(1.0, 0.5, 0.1, 1.0)},
	"speed":  {"label": "SPD+\n+30",    "color": Color(1.0, 0.85, 0.1, 1.0)},
}

var _filled_slots: int = 0
var _slots: Array[Panel] = []

func _ready() -> void:
	EventBus.xp_gained.connect(_on_xp_gained)
	EventBus.player_hp_changed.connect(_on_player_hp_changed)
	EventBus.player_shield_changed.connect(_on_player_shield_changed)
	EventBus.ship_levelled_up.connect(_on_ship_levelled_up)
	EventBus.upgrade_chosen.connect(_on_upgrade_chosen)
	for child in $CardSlots.get_children():
		_slots.append(child as Panel)

func _on_xp_gained(_amount: int) -> void:
	$ScoreLabel.text = "Score: %d" % GameManager.run_xp
	_update_xp_bar()

func _on_player_hp_changed(current: int, maximum: int) -> void:
	$HPBar.max_value = maximum
	$HPBar.value = current

func _on_player_shield_changed(current: int, maximum: int) -> void:
	$ShieldBar.max_value = maximum
	$ShieldBar.value = current

func _on_ship_levelled_up(new_level: int) -> void:
	$LevelLabel.text = "Lv. %d" % new_level
	_update_xp_bar()

func _on_upgrade_chosen(upgrade_id: String) -> void:
	if _filled_slots >= _slots.size():
		return
	var slot = _slots[_filled_slots]
	var display = UPGRADE_DISPLAY.get(upgrade_id, {"label": upgrade_id, "color": Color.WHITE})
	slot.modulate = display["color"]
	slot.get_node("Label").text = display["label"]
	_filled_slots += 1

func _update_xp_bar() -> void:
	var level_index = GameManager.ship_level - 1
	if level_index < GameManager.ship_xp_thresholds.size():
		var threshold = GameManager.ship_xp_thresholds[level_index]
		$XPBar.max_value = threshold
		$XPBar.value = GameManager.ship_xp
	else:
		$XPBar.max_value = 1
		$XPBar.value = 1

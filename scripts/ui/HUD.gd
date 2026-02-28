extends CanvasLayer

const UPGRADE_DISPLAY: Dictionary = {
	"hp":     {"label": "HP+\n+20 HP",  "color": Color(0.2, 0.9, 0.3, 1.0)},
	"shield": {"label": "SHD+\n+15",    "color": Color(0.2, 0.6, 1.0, 1.0)},
	"attack": {"label": "ATK+\n×1.2",   "color": Color(1.0, 0.5, 0.1, 1.0)},
	"speed":  {"label": "SPD+\n+30",    "color": Color(1.0, 0.85, 0.1, 1.0)},
}

var _filled_slots: int = 0
var _upgrade_slot_panels: Array[Panel] = []

var _weapon_data: Array = [null, null]
var _active_weapon_slot: int = 0
var _weapon_panels: Array[Panel] = []

func _ready() -> void:
	EventBus.xp_gained.connect(_on_xp_gained)
	EventBus.player_hp_changed.connect(_on_player_hp_changed)
	EventBus.player_shield_changed.connect(_on_player_shield_changed)
	EventBus.ship_levelled_up.connect(_on_ship_levelled_up)
	EventBus.upgrade_chosen.connect(_on_upgrade_chosen)
	EventBus.weapon_equipped.connect(_on_weapon_equipped)
	EventBus.weapon_slot_switched.connect(_on_weapon_slot_switched)
	for child in $CardSlots.get_children():
		_upgrade_slot_panels.append(child as Panel)
	for child in $WeaponSlots.get_children():
		_weapon_panels.append(child as Panel)

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
	if _filled_slots >= _upgrade_slot_panels.size():
		return
	var slot = _upgrade_slot_panels[_filled_slots]
	var display = UPGRADE_DISPLAY.get(upgrade_id, {"label": upgrade_id, "color": Color.WHITE})
	slot.modulate = display["color"]
	slot.get_node("Label").text = display["label"]
	_filled_slots += 1

func _on_weapon_equipped(slot: int, weapon_data: Dictionary) -> void:
	_weapon_data[slot] = weapon_data
	_refresh_weapon_slots()

func _on_weapon_slot_switched(active_slot: int) -> void:
	_active_weapon_slot = active_slot
	_refresh_weapon_slots()

func _refresh_weapon_slots() -> void:
	for i in 2:
		var panel = _weapon_panels[i]
		var label = panel.get_node("Label")
		var weapon = _weapon_data[i]
		var is_active = (i == _active_weapon_slot)
		if weapon == null:
			label.text = "[ empty ]"
			panel.modulate = Color(0.7, 0.7, 0.7, 0.8 if is_active else 0.4)
		else:
			label.text = weapon["name"]
			var c: Color = weapon["color"]
			panel.modulate = Color(c.r, c.g, c.b, 1.0 if is_active else 0.55)

func _update_xp_bar() -> void:
	var level_index = GameManager.ship_level - 1
	if level_index < GameManager.ship_xp_thresholds.size():
		var threshold = GameManager.ship_xp_thresholds[level_index]
		$XPBar.max_value = threshold
		$XPBar.value = GameManager.ship_xp
	else:
		$XPBar.max_value = 1
		$XPBar.value = 1

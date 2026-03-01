extends CanvasLayer

const UPGRADE_DISPLAY: Dictionary = {
	"hp":     {"label": "HP+\n+20 HP",  "color": Color(0.2, 0.9, 0.3, 1.0)},
	"shield": {"label": "SHD+\n+15",    "color": Color(0.2, 0.6, 1.0, 1.0)},
	"attack": {"label": "ATK+\n×1.2",   "color": Color(1.0, 0.5, 0.1, 1.0)},
	"speed":  {"label": "SPD+\n+30",    "color": Color(1.0, 0.85, 0.1, 1.0)},
}

const SLOT_W := 100
const SLOT_H := 36

var _filled_slots: int = 0
var _upgrade_slot_panels: Array[Panel] = []
var _weapon_panels: Array[Panel] = []   # one per MAX_SLOTS

func _ready() -> void:
	EventBus.xp_gained.connect(_on_xp_gained)
	EventBus.player_hp_changed.connect(_on_player_hp_changed)
	EventBus.player_shield_changed.connect(_on_player_shield_changed)
	EventBus.ship_levelled_up.connect(_on_ship_levelled_up)
	EventBus.upgrade_chosen.connect(_on_upgrade_chosen)
	EventBus.weapon_equipped.connect(_on_weapon_equipped)
	EventBus.weapon_xp_updated.connect(_on_weapon_xp_updated)
	EventBus.level_started.connect(_on_level_started)
	EventBus.level_completed.connect(_on_level_completed)
	for child in $CardSlots.get_children():
		_upgrade_slot_panels.append(child as Panel)
	_build_weapon_panels()

func _build_weapon_panels() -> void:
	# Clear any scene-defined children (old 2-slot setup)
	for child in $WeaponSlots.get_children():
		child.queue_free()
	for i in Player.MAX_SLOTS:
		var panel := Panel.new()
		panel.custom_minimum_size = Vector2(SLOT_W, SLOT_H)
		panel.modulate = Color(0.5, 0.5, 0.5, 0.35)

		var name_label := Label.new()
		name_label.name = "NameLabel"
		name_label.anchor_right = 1.0
		name_label.anchor_bottom = 0.6
		name_label.text = "[ empty ]"
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 10)
		panel.add_child(name_label)

		var xp_bar := ProgressBar.new()
		xp_bar.name = "XPBar"
		xp_bar.anchor_top = 0.65
		xp_bar.anchor_right = 1.0
		xp_bar.anchor_bottom = 1.0
		xp_bar.show_percentage = false
		xp_bar.max_value = 1
		xp_bar.value = 0
		xp_bar.modulate = Color(0.6, 1.0, 0.4, 0.9)
		panel.add_child(xp_bar)

		$WeaponSlots.add_child(panel)
		_weapon_panels.append(panel)

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
	var slot := _upgrade_slot_panels[_filled_slots]
	var display := UPGRADE_DISPLAY.get(upgrade_id, {"label": upgrade_id, "color": Color.WHITE})
	slot.modulate = display["color"]
	slot.get_node("Label").text = display["label"]
	_filled_slots += 1

func _on_weapon_equipped(slot: int, weapon_data) -> void:
	if slot >= _weapon_panels.size():
		return
	var panel := _weapon_panels[slot]
	var name_label := panel.get_node("NameLabel") as Label
	var xp_bar := panel.get_node("XPBar") as ProgressBar
	if weapon_data == null:
		name_label.text = "[ empty ]"
		panel.modulate = Color(0.5, 0.5, 0.5, 0.35)
		xp_bar.value = 0
		xp_bar.max_value = 1
	else:
		name_label.text = weapon_data["name"]
		var c: Color = weapon_data["color"]
		panel.modulate = Color(c.r, c.g, c.b, 0.85)
		xp_bar.value = 0
		var thresholds: Array = weapon_data.get("xp_thresholds", [50, 150, 300, 500])
		var tier: int = weapon_data["tier"]
		xp_bar.max_value = thresholds[tier - 1] if tier <= 4 else 1

func _on_weapon_xp_updated(slot: int, current_xp: int, max_xp: int) -> void:
	if slot >= _weapon_panels.size():
		return
	var xp_bar := _weapon_panels[slot].get_node("XPBar") as ProgressBar
	xp_bar.max_value = max_xp
	xp_bar.value = current_xp

func _on_level_started(ante: int, level_in_ante: int) -> void:
	$AnteLabel.text = "Ante %d  •  Level %d" % [ante, level_in_ante]
	$LevelCompleteLabel.hide()

func _on_level_completed(ante: int, level_in_ante: int) -> void:
	$LevelCompleteLabel.text = "ANTE %d  LEVEL %d\nCOMPLETE" % [ante, level_in_ante]
	$LevelCompleteLabel.show()

func _update_xp_bar() -> void:
	var level_index := GameManager.ship_level - 1
	if level_index < GameManager.ship_xp_thresholds.size():
		$XPBar.max_value = GameManager.ship_xp_thresholds[level_index]
		$XPBar.value = GameManager.ship_xp
	else:
		$XPBar.max_value = 1
		$XPBar.value = 1

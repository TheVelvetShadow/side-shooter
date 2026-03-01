extends CanvasLayer

var _panel: PanelContainer
var _god_btn: Button
var god_mode: bool = false

func _ready() -> void:
	layer = 100
	process_mode = PROCESS_MODE_ALWAYS
	_build_ui()
	_panel.visible = false
	EventBus.player_damaged.connect(_on_player_damaged)

func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F12:
			_panel.visible = not _panel.visible
			get_viewport().set_input_as_handled()

func _on_player_damaged(amount: int) -> void:
	if not god_mode:
		return
	var player := get_tree().get_first_node_in_group("player") as Player
	if player:
		player.heal(amount)

# ---------------------------------------------------------------------------
# UI construction
# ---------------------------------------------------------------------------

func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_panel.offset_left  = -330
	_panel.offset_right = -8
	_panel.offset_top   = 8
	_panel.offset_bottom = 700

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   8)
	margin.add_theme_constant_override("margin_right",  8)
	margin.add_theme_constant_override("margin_top",    6)
	margin.add_theme_constant_override("margin_bottom", 6)
	_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "DEBUG MENU  [F12]"
	title.add_theme_color_override("font_color", Color(1.0, 1.0, 0.2))
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	# Weapons section
	var wlabel := Label.new()
	wlabel.text = "EQUIP WEAPON"
	wlabel.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	vbox.add_child(wlabel)

	for type: String in WeaponDB.get_all_types():
		vbox.add_child(_make_weapon_row(type))

	vbox.add_child(HSeparator.new())

	# Actions section
	var alabel := Label.new()
	alabel.text = "QUICK ACTIONS"
	alabel.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	vbox.add_child(alabel)

	var row1 := HBoxContainer.new()
	vbox.add_child(row1)

	var credits_btn := Button.new()
	credits_btn.text = "+500 Credits"
	credits_btn.pressed.connect(_add_credits)
	row1.add_child(credits_btn)

	var xp_btn := Button.new()
	xp_btn.text = "Trigger Upgrade"
	xp_btn.pressed.connect(_trigger_weapon_upgrade)
	row1.add_child(xp_btn)

	var row2 := HBoxContainer.new()
	vbox.add_child(row2)

	_god_btn = Button.new()
	_god_btn.text = "God Mode: OFF"
	_god_btn.pressed.connect(_toggle_god_mode)
	row2.add_child(_god_btn)

	var unlock_btn := Button.new()
	unlock_btn.text = "Unlock All Slots"
	unlock_btn.pressed.connect(_unlock_all_slots)
	row2.add_child(unlock_btn)

	var kill_btn := Button.new()
	kill_btn.text = "Kill All Enemies"
	kill_btn.pressed.connect(_kill_all_enemies)
	row2.add_child(kill_btn)

	add_child(_panel)

func _make_weapon_row(type: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)

	var lbl := Label.new()
	lbl.text = type.replace("_", " ").capitalize()
	lbl.custom_minimum_size.x = 130
	lbl.add_theme_font_size_override("font_size", 11)
	row.add_child(lbl)

	for tier in range(1, 6):
		var btn := Button.new()
		btn.text = "T%d" % tier
		btn.custom_minimum_size = Vector2(32, 22)
		btn.add_theme_font_size_override("font_size", 11)
		btn.pressed.connect(_equip_weapon.bind(type, tier))
		row.add_child(btn)

	return row

# ---------------------------------------------------------------------------
# Actions
# ---------------------------------------------------------------------------

func _equip_weapon(type: String, tier: int) -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null:
		return
	var weapon := WeaponDB.get_weapon(type, tier)
	# Find an empty slot
	for i in player.unlocked_slots:
		if player.weapon_slots[i] == null:
			player.weapon_slots[i] = weapon
			player.weapon_xp[i] = 0
			player.slot_timers[i] = 0.0
			EventBus.weapon_equipped.emit(i, weapon)
			return
	# All current slots full — unlock next one if available
	if player.unlocked_slots < Player.MAX_SLOTS:
		player.unlock_slot()
		var slot := player.unlocked_slots - 1
		player.weapon_slots[slot] = weapon
		player.weapon_xp[slot] = 0
		player.slot_timers[slot] = 0.0
		EventBus.weapon_equipped.emit(slot, weapon)
		return
	# All 6 slots full — overwrite slot 0 (debug, no tier check)
	player.weapon_slots[0] = weapon
	player.weapon_xp[0] = 0
	player.slot_timers[0] = 0.0
	EventBus.weapon_equipped.emit(0, weapon)

func _unlock_all_slots() -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null:
		return
	while player.unlocked_slots < Player.MAX_SLOTS:
		player.unlock_slot()

func _add_credits() -> void:
	GameManager.credits += 500
	EventBus.credits_changed.emit(GameManager.credits)

func _trigger_weapon_upgrade() -> void:
	GameManager.weapon_xp = GameManager.weapon_xp_threshold
	GameManager._check_weapon_upgrade()

func _toggle_god_mode() -> void:
	god_mode = not god_mode
	_god_btn.text = "God Mode: ON" if god_mode else "God Mode: OFF"
	_god_btn.add_theme_color_override(
		"font_color", Color(0.2, 1.0, 0.2) if god_mode else Color(1.0, 1.0, 1.0)
	)

func _kill_all_enemies() -> void:
	for node in get_tree().get_nodes_in_group("level_objects"):
		var n := node as Node
		if n == null or n.is_in_group("player"):
			continue
		if n.has_method("take_damage"):
			n.call("take_damage", 999999, -1)

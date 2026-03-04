extends CanvasLayer

var _panel: PanelContainer
var _god_btn: Button
var _reload_btn: Button
var _enemy_vbox: VBoxContainer

# Tracks the CheckButton for each enemy so Solo can refresh them all
var _enemy_checks: Dictionary = {}   # enemy_id -> CheckButton

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
	if not GameManager.god_mode:
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

	var row3 := HBoxContainer.new()
	vbox.add_child(row3)

	_reload_btn = Button.new()
	_reload_btn.text = "Reload Enemy Data"
	_reload_btn.pressed.connect(_reload_enemy_data)
	row3.add_child(_reload_btn)

	vbox.add_child(HSeparator.new())

	# Flock params
	var flock_label := Label.new()
	flock_label.text = "FLOCK PARAMS"
	flock_label.add_theme_color_override("font_color", Color(0.6, 1.0, 0.7))
	vbox.add_child(flock_label)

	var flock_params := [
		["Radius",      "flock_radius",     1.0,  10.0, 400.0],
		["Sep radius",  "flock_sep_radius", 1.0,  5.0,  200.0],
		["Sep weight",  "flock_sep_w",      0.1,  0.0,  10.0 ],
		["Align weight","flock_align_w",    0.1,  0.0,  10.0 ],
		["Cohesion",    "flock_cohesion_w", 0.1,  0.0,  10.0 ],
		["Seek weight", "flock_seek_w",     0.1,  0.0,  10.0 ],
		["Steer rate",  "flock_steer_rate", 0.1,  0.1,  20.0 ],
	]
	for p in flock_params:
		vbox.add_child(_make_spinbox_row(p[0], p[1], p[2], p[3], p[4]))

	vbox.add_child(HSeparator.new())

	# Upgrades toggle
	vbox.add_child(HSeparator.new())
	var upgrades_label := Label.new()
	upgrades_label.text = "UPGRADES"
	upgrades_label.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	vbox.add_child(upgrades_label)

	var upgrades_check := CheckButton.new()
	upgrades_check.text = "Weapon upgrade cards"
	upgrades_check.button_pressed = GameManager.upgrades_enabled
	upgrades_check.add_theme_font_size_override("font_size", 11)
	upgrades_check.toggled.connect(func(on: bool) -> void:
		GameManager.upgrades_enabled = on)
	vbox.add_child(upgrades_check)

	var labels_check := CheckButton.new()
	labels_check.text = "Show enemy labels"
	labels_check.button_pressed = GameManager.show_enemy_labels
	labels_check.add_theme_font_size_override("font_size", 11)
	labels_check.toggled.connect(func(on: bool) -> void:
		GameManager.show_enemy_labels = on
		for node in get_tree().get_nodes_in_group("level_objects"):
			if node.has_method("queue_redraw"):
				node.queue_redraw())
	vbox.add_child(labels_check)

	var ship_skip_check := CheckButton.new()
	ship_skip_check.text = "Skip ship select (next run)"
	ship_skip_check.button_pressed = GameManager.skip_ship_select
	ship_skip_check.add_theme_font_size_override("font_size", 11)
	ship_skip_check.toggled.connect(func(on: bool) -> void:
		GameManager.skip_ship_select = on)
	vbox.add_child(ship_skip_check)

	# Lighting section
	vbox.add_child(HSeparator.new())
	var light_label := Label.new()
	light_label.text = "LIGHTING"
	light_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
	vbox.add_child(light_label)

	var ship_light_sub := Label.new()
	ship_light_sub.text = "Ship Light"
	ship_light_sub.add_theme_font_size_override("font_size", 10)
	ship_light_sub.modulate = Color(0.8, 0.8, 0.8)
	vbox.add_child(ship_light_sub)

	var light_toggle := CheckButton.new()
	light_toggle.text = "Enabled"
	light_toggle.button_pressed = true
	light_toggle.add_theme_font_size_override("font_size", 11)
	light_toggle.toggled.connect(func(on: bool) -> void:
		var l := _get_ship_light()
		if l: l.enabled = on)
	vbox.add_child(light_toggle)

	vbox.add_child(_make_cb_spinbox_row("Energy", 0.1, 0.0, 8.0, 1.5,
		func(v: float) -> void:
			var l := _get_ship_light()
			if l: l.energy = v))
	vbox.add_child(_make_cb_spinbox_row("Range", 0.1, 0.1, 8.0, 2.5,
		func(v: float) -> void:
			var l := _get_ship_light()
			if l: l.texture_scale = v))

	var vig_sub := Label.new()
	vig_sub.text = "Vignette"
	vig_sub.add_theme_font_size_override("font_size", 10)
	vig_sub.modulate = Color(0.8, 0.8, 0.8)
	vbox.add_child(vig_sub)

	vbox.add_child(_make_cb_spinbox_row("Strength", 0.05, 0.0, 3.0, 1.2,
		func(v: float) -> void:
			var vig := _get_vignette()
			if vig: vig.set_params(v, vig.opacity)))
	vbox.add_child(_make_cb_spinbox_row("Opacity", 0.05, 0.0, 1.0, 0.85,
		func(v: float) -> void:
			var vig := _get_vignette()
			if vig: vig.set_params(vig.strength, v)))

	# Enemy spawn / pool section
	vbox.add_child(HSeparator.new())
	var elabel := Label.new()
	elabel.text = "ENEMY POOL  +  SPAWN"
	elabel.add_theme_color_override("font_color", Color(1.0, 0.7, 0.4))
	vbox.add_child(elabel)

	# Enable All / Disable All
	var pool_row := HBoxContainer.new()
	pool_row.add_theme_constant_override("separation", 4)
	vbox.add_child(pool_row)

	var enable_all_btn := Button.new()
	enable_all_btn.text = "Enable All"
	enable_all_btn.add_theme_font_size_override("font_size", 10)
	enable_all_btn.pressed.connect(_enable_all_enemies)
	pool_row.add_child(enable_all_btn)

	var disable_all_btn := Button.new()
	disable_all_btn.text = "Disable All"
	disable_all_btn.add_theme_font_size_override("font_size", 10)
	disable_all_btn.pressed.connect(_disable_all_enemies)
	pool_row.add_child(disable_all_btn)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 280)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	_enemy_vbox = VBoxContainer.new()
	_enemy_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_enemy_vbox.add_theme_constant_override("separation", 2)
	scroll.add_child(_enemy_vbox)

	for enemy_id in EnemyDB.get_all_ids():
		var data := EnemyDB.get_enemy(enemy_id)
		var etype: String = data.get("enemy_type", "")
		if etype == "boss_small" or etype == "boss_big":
			continue   # bosses are not in the spawn pool
		_enemy_vbox.add_child(_make_enemy_row(enemy_id, etype))

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
	GameManager.god_mode = not GameManager.god_mode
	_god_btn.text = "God Mode: ON" if GameManager.god_mode else "God Mode: OFF"
	_god_btn.add_theme_color_override(
		"font_color", Color(0.2, 1.0, 0.2) if GameManager.god_mode else Color(1.0, 1.0, 1.0)
	)

func _make_enemy_row(enemy_id: String, enemy_type: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)

	# Pool toggle checkbox
	var check := CheckButton.new()
	check.button_pressed = EnemyDB.is_enabled(enemy_id)
	check.custom_minimum_size = Vector2(36, 20)
	check.toggled.connect(func(on: bool) -> void:
		EnemyDB.set_enabled(enemy_id, on))
	row.add_child(check)
	_enemy_checks[enemy_id] = check

	# Label — show display name with id in smaller text
	var lbl := Label.new()
	var display_name: String = EnemyDB.get_enemy(enemy_id).get("name", enemy_id)
	lbl.text = "%s  [%s]" % [display_name, enemy_id]
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 10)
	match enemy_type:
		"elite":  lbl.modulate = Color(0.8, 0.6, 1.0)
		"heavy":  lbl.modulate = Color(0.6, 0.8, 1.0)
		"drone":  lbl.modulate = Color(0.6, 1.0, 0.7)
		_:        lbl.modulate = Color(0.85, 0.85, 0.85)
	row.add_child(lbl)

	# Solo button — disables all others, enables only this one
	var solo_btn := Button.new()
	solo_btn.text = "Solo"
	solo_btn.custom_minimum_size = Vector2(36, 20)
	solo_btn.add_theme_font_size_override("font_size", 10)
	solo_btn.pressed.connect(_solo_enemy.bind(enemy_id))
	row.add_child(solo_btn)

	# Spawn button — manual one-off spawn regardless of pool state
	var spawn_btn := Button.new()
	spawn_btn.text = "Spawn"
	spawn_btn.custom_minimum_size = Vector2(44, 20)
	spawn_btn.add_theme_font_size_override("font_size", 10)
	spawn_btn.pressed.connect(_spawn_enemy.bind(enemy_id))
	row.add_child(spawn_btn)

	return row

func _spawn_enemy(enemy_id: String) -> void:
	var enemy_scene := load("res://scenes/enemies/Enemy.tscn") as PackedScene
	if enemy_scene == null:
		return
	var enemy := enemy_scene.instantiate()
	enemy.enemy_id = enemy_id
	var vp := get_viewport().get_visible_rect().size
	enemy.global_position = Vector2(vp.x * 0.65, vp.y * 0.5)
	get_tree().root.add_child(enemy)

func _enable_all_enemies() -> void:
	EnemyDB.enable_all()
	for enemy_id in _enemy_checks:
		_enemy_checks[enemy_id].button_pressed = true

func _disable_all_enemies() -> void:
	EnemyDB.disable_all_non_boss()
	for enemy_id in _enemy_checks:
		_enemy_checks[enemy_id].button_pressed = false

func _solo_enemy(enemy_id: String) -> void:
	EnemyDB.enable_only(enemy_id)
	for id in _enemy_checks:
		_enemy_checks[id].button_pressed = (id == enemy_id)

func _make_spinbox_row(label_text: String, property: String, step: float, min_val: float, max_val: float) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size.x = 90
	lbl.add_theme_font_size_override("font_size", 10)
	row.add_child(lbl)

	var spin := SpinBox.new()
	spin.min_value = min_val
	spin.max_value = max_val
	spin.step = step
	spin.value = GameManager.get(property)
	spin.custom_minimum_size.x = 80
	spin.add_theme_font_size_override("font_size", 10)
	spin.value_changed.connect(func(v: float) -> void:
		GameManager.set(property, v))
	row.add_child(spin)

	return row


func _reload_enemy_data() -> void:
	EnemyDB.reload()
	_enemy_checks.clear()
	for child in _enemy_vbox.get_children():
		child.queue_free()
	for enemy_id in EnemyDB.get_all_ids():
		var data := EnemyDB.get_enemy(enemy_id)
		var etype: String = data.get("enemy_type", "")
		if etype == "boss_small" or etype == "boss_big":
			continue
		_enemy_vbox.add_child(_make_enemy_row(enemy_id, etype))
	_reload_btn.text = "Reloaded  ✓"
	await get_tree().create_timer(1.5).timeout
	_reload_btn.text = "Reload Enemy Data"


func _kill_all_enemies() -> void:
	for node in get_tree().get_nodes_in_group("level_objects"):
		var n := node as Node
		if n == null or n.is_in_group("player"):
			continue
		if n.has_method("take_damage"):
			n.call("take_damage", 999999, -1)

func _get_ship_light() -> PointLight2D:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return null
	return player.get_node_or_null("ShipLight") as PointLight2D

func _get_vignette() -> Node:
	return get_parent().get_node_or_null("VignetteOverlay")

func _make_cb_spinbox_row(label_text: String, step: float, min_val: float, max_val: float, default_val: float, setter: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size.x = 90
	lbl.add_theme_font_size_override("font_size", 10)
	row.add_child(lbl)

	var spin := SpinBox.new()
	spin.min_value = min_val
	spin.max_value = max_val
	spin.step = step
	spin.value = default_val
	spin.custom_minimum_size.x = 80
	spin.add_theme_font_size_override("font_size", 10)
	spin.value_changed.connect(setter)
	row.add_child(spin)

	return row

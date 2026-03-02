extends CanvasLayer

const SLOT_W := 100

# Overlay refs (static nodes in .tscn)
@onready var _ante_label: Label = $AnteLabel
@onready var _level_complete_label: Label = $LevelCompleteLabel

# Dashboard refs built in _ready()
var _hp_bar: ProgressBar
var _shield_bar: ProgressBar
var _weapon_slots_hbox: HBoxContainer
var _weapon_panels: Array[Panel] = []
var _xp_bar: ProgressBar
var _xp_label: Label
var _pilot_labels: Array[Label] = []
var _score_label: Label
var _boss_bar_container: Control
var _boss_bar: ProgressBar
var _boss_name_label: Label

var _chain_label: Label
var _chain_bg: Panel
var _chain_timer: float = 0.0
const CHAIN_DISPLAY_DURATION := 2.0
const CHAIN_THROTTLE := 1.5  # don't replace a chain that's still fresh

func _ready() -> void:
	_build_dashboard()
	_build_boss_bar()
	EventBus.player_hp_changed.connect(_on_player_hp_changed)
	EventBus.player_shield_changed.connect(_on_player_shield_changed)
	EventBus.xp_gained.connect(func(_a): _score_label.text = "Score  %d" % GameManager.run_xp)
	EventBus.weapon_equipped.connect(_on_weapon_equipped)
	EventBus.weapon_xp_bar_updated.connect(_on_weapon_xp_bar_updated)
	EventBus.level_started.connect(func(a, l): _ante_label.text = "Ante %d  •  Level %d" % [a, l]; _level_complete_label.hide(); _boss_bar_container.hide())
	EventBus.level_completed.connect(func(a, l): _level_complete_label.text = "ANTE %d  LEVEL %d\nCOMPLETE" % [a, l]; _level_complete_label.show())
	EventBus.pilot_academy_closed.connect(_refresh_pilots)
	EventBus.boss_spawned.connect(_on_boss_spawned)
	EventBus.boss_hp_changed.connect(_on_boss_hp_changed)
	EventBus.damage_chain_shown.connect(_on_damage_chain_shown)
	_build_chain_display()

func _build_dashboard() -> void:
	# Full-width panel pinned to the bottom of the screen
	var panel := PanelContainer.new()
	panel.anchor_left   = 0.0
	panel.anchor_right  = 1.0
	panel.anchor_top    = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_top    = -76.0
	panel.offset_bottom = 0.0
	add_child(panel)

	var mc := MarginContainer.new()
	mc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		mc.add_theme_constant_override(side, 6)
	panel.add_child(mc)

	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 14)
	mc.add_child(row)

	# ── HP / Shield ─────────────────────────────────────────────────────────
	var health_col := VBoxContainer.new()
	health_col.custom_minimum_size = Vector2(200, 0)
	health_col.add_theme_constant_override("separation", 4)
	row.add_child(health_col)

	_hp_bar = _make_bar_row(health_col, "HP", Color(0.2, 1.0, 0.35, 1.0), 100)
	_shield_bar = _make_bar_row(health_col, "SHD", Color(0.25, 0.65, 1.0, 1.0), 50)

	row.add_child(VSeparator.new())

	# ── Weapon slots ─────────────────────────────────────────────────────────
	_weapon_slots_hbox = HBoxContainer.new()
	_weapon_slots_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_weapon_slots_hbox.add_theme_constant_override("separation", 4)
	row.add_child(_weapon_slots_hbox)
	_build_weapon_panels()

	row.add_child(VSeparator.new())

	# ── XP bar ──────────────────────────────────────────────────────────────
	var xp_col := VBoxContainer.new()
	xp_col.custom_minimum_size = Vector2(220, 0)
	xp_col.add_theme_constant_override("separation", 3)
	row.add_child(xp_col)

	_xp_label = Label.new()
	_xp_label.text = "XP  0 / 100"
	_xp_label.add_theme_font_size_override("font_size", 11)
	_xp_label.modulate = Color(1.0, 0.6, 0.15, 1.0)
	xp_col.add_child(_xp_label)

	_xp_bar = ProgressBar.new()
	_xp_bar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_xp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_xp_bar.max_value = 100
	_xp_bar.value = 0
	_xp_bar.show_percentage = false
	_xp_bar.modulate = Color(1.0, 0.55, 0.1, 1.0)
	xp_col.add_child(_xp_bar)

	row.add_child(VSeparator.new())

	# ── Pilots ───────────────────────────────────────────────────────────────
	var pilots_col := VBoxContainer.new()
	pilots_col.add_theme_constant_override("separation", 2)
	pilots_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(pilots_col)

	var pilots_hdr := Label.new()
	pilots_hdr.text = "PILOTS"
	pilots_hdr.add_theme_font_size_override("font_size", 10)
	pilots_hdr.modulate = Color(0.6, 0.6, 0.85, 1.0)
	pilots_col.add_child(pilots_hdr)

	var pilot_row := HBoxContainer.new()
	pilot_row.add_theme_constant_override("separation", 8)
	pilot_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pilots_col.add_child(pilot_row)

	for _i in PilotManager.MAX_PILOTS:
		var lbl := Label.new()
		lbl.text = "—"
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.modulate = Color(0.4, 0.4, 0.4, 1.0)
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		pilot_row.add_child(lbl)
		_pilot_labels.append(lbl)

	row.add_child(VSeparator.new())

	# ── Score ────────────────────────────────────────────────────────────────
	_score_label = Label.new()
	_score_label.text = "Score  0"
	_score_label.add_theme_font_size_override("font_size", 14)
	_score_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_score_label.custom_minimum_size = Vector2(130, 0)
	row.add_child(_score_label)

func _build_boss_bar() -> void:
	# Centered at top of screen, hidden until boss spawns
	_boss_bar_container = VBoxContainer.new()
	_boss_bar_container.anchor_left   = 0.25
	_boss_bar_container.anchor_right  = 0.75
	_boss_bar_container.anchor_top    = 0.0
	_boss_bar_container.anchor_bottom = 0.0
	_boss_bar_container.offset_top    = 8.0
	_boss_bar_container.offset_bottom = 52.0
	_boss_bar_container.add_theme_constant_override("separation", 2)
	add_child(_boss_bar_container)

	_boss_name_label = Label.new()
	_boss_name_label.text = ""
	_boss_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_name_label.add_theme_font_size_override("font_size", 12)
	_boss_name_label.modulate = Color(1.0, 0.35, 0.2, 1.0)
	_boss_bar_container.add_child(_boss_name_label)

	_boss_bar = ProgressBar.new()
	_boss_bar.max_value = 100
	_boss_bar.value = 100
	_boss_bar.show_percentage = false
	_boss_bar.modulate = Color(1.0, 0.2, 0.1, 1.0)
	_boss_bar.custom_minimum_size = Vector2(0, 20)
	_boss_bar_container.add_child(_boss_bar)

	_boss_bar_container.hide()

func _make_bar_row(parent: Control, label_text: String, color: Color, max_val: int) -> ProgressBar:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	parent.add_child(hbox)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.custom_minimum_size = Vector2(28, 0)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(lbl)

	var bar := ProgressBar.new()
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.max_value = max_val
	bar.value = max_val
	bar.show_percentage = false
	bar.modulate = color
	hbox.add_child(bar)

	return bar

func _build_weapon_panels() -> void:
	for child in _weapon_slots_hbox.get_children():
		child.queue_free()
	_weapon_panels.clear()
	for i in Player.MAX_SLOTS:
		var panel := Panel.new()
		panel.custom_minimum_size = Vector2(SLOT_W, 0)
		panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
		panel.modulate = Color(0.5, 0.5, 0.5, 0.35)

		var name_lbl := Label.new()
		name_lbl.name = "NameLabel"
		name_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		name_lbl.offset_right = -26.0
		name_lbl.text = "[ empty ]"
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 10)
		panel.add_child(name_lbl)

		var tier_lbl := Label.new()
		tier_lbl.name = "TierLabel"
		tier_lbl.anchor_left   = 1.0
		tier_lbl.anchor_right  = 1.0
		tier_lbl.anchor_bottom = 1.0
		tier_lbl.offset_left   = -24.0
		tier_lbl.offset_right  = -3.0
		tier_lbl.offset_top    = 4.0
		tier_lbl.offset_bottom = -3.0
		tier_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tier_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_BOTTOM
		tier_lbl.add_theme_font_size_override("font_size", 10)
		panel.add_child(tier_lbl)

		_weapon_slots_hbox.add_child(panel)
		_weapon_panels.append(panel)

func _on_player_hp_changed(current: int, maximum: int) -> void:
	_hp_bar.max_value = maximum
	_hp_bar.value = current

func _on_player_shield_changed(current: int, maximum: int) -> void:
	_shield_bar.max_value = maximum
	_shield_bar.value = current

func _on_weapon_equipped(slot: int, weapon_data) -> void:
	if slot >= _weapon_panels.size():
		return
	var panel := _weapon_panels[slot]
	var name_lbl := panel.get_node("NameLabel") as Label
	var tier_lbl := panel.get_node("TierLabel") as Label
	if weapon_data == null:
		name_lbl.text = "[ empty ]"
		tier_lbl.text = ""
		panel.modulate = Color(0.5, 0.5, 0.5, 0.35)
	else:
		name_lbl.text = weapon_data["name"]
		tier_lbl.text = "T%d" % weapon_data["tier"]
		var c: Color = weapon_data["color"]
		panel.modulate = Color(c.r, c.g, c.b, 0.85)

func _on_weapon_xp_bar_updated(current: int, maximum: int) -> void:
	_xp_bar.max_value = maximum
	_xp_bar.value = current
	_xp_label.text = "XP  %d / %d" % [current, maximum]

func _on_boss_spawned(boss_name: String, max_hp: int) -> void:
	_boss_name_label.text = "⚠  %s  ⚠" % boss_name
	_boss_bar.max_value = max_hp
	_boss_bar.value = max_hp
	_boss_bar_container.show()

func _on_boss_hp_changed(current: int, maximum: int) -> void:
	_boss_bar.max_value = maximum
	_boss_bar.value = current

func _process(delta: float) -> void:
	if _chain_timer > 0.0:
		_chain_timer -= delta
		var alpha := clampf(_chain_timer / CHAIN_DISPLAY_DURATION, 0.0, 1.0)
		_chain_bg.modulate.a = alpha
		if _chain_timer <= 0.0:
			_chain_bg.hide()

func _build_chain_display() -> void:
	# Semi-transparent panel, top-right of screen
	_chain_bg = Panel.new()
	_chain_bg.anchor_left   = 1.0
	_chain_bg.anchor_right  = 1.0
	_chain_bg.anchor_top    = 0.0
	_chain_bg.anchor_bottom = 0.0
	_chain_bg.offset_left   = -520.0
	_chain_bg.offset_right  = -8.0
	_chain_bg.offset_top    = 8.0
	_chain_bg.offset_bottom = 42.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.65)
	style.set_corner_radius_all(4)
	_chain_bg.add_theme_stylebox_override("panel", style)

	_chain_label = Label.new()
	_chain_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_chain_label.add_theme_constant_override("margin_left", 10)
	_chain_label.add_theme_constant_override("margin_right", 10)
	_chain_label.add_theme_font_size_override("font_size", 14)
	_chain_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_chain_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_chain_label.modulate = Color(1.0, 0.95, 0.6, 1.0)
	_chain_bg.add_child(_chain_label)
	add_child(_chain_bg)
	_chain_bg.hide()

func _on_damage_chain_shown(steps: Array) -> void:
	# Throttle: don't replace a recent fresh chain
	if _chain_timer > CHAIN_THROTTLE:
		return
	_chain_label.text = _format_chain(steps)
	_chain_bg.modulate.a = 1.0
	_chain_bg.show()
	_chain_timer = CHAIN_DISPLAY_DURATION

func _format_chain(steps: Array) -> String:
	if steps.is_empty():
		return ""
	var parts: Array[String] = []
	# First step is Base — show its value
	parts.append(str(steps[0]["value"]))
	# Subsequent steps show "op (name) → value"
	for i in range(1, steps.size()):
		var s: Dictionary = steps[i]
		parts.append("%s (%s)" % [s["op"], s["label"]])
	# Final result
	var final_val: int = steps[-1]["value"]
	return "  ".join(parts) + "  =  " + str(final_val)

func _refresh_pilots() -> void:
	for i in _pilot_labels.size():
		if i < PilotManager.active_pilots.size():
			_pilot_labels[i].text = PilotManager.active_pilots[i]["name"]
			_pilot_labels[i].modulate = Color(0.9, 0.85, 1.0, 1.0)
		else:
			_pilot_labels[i].text = "—"
			_pilot_labels[i].modulate = Color(0.4, 0.4, 0.4, 1.0)

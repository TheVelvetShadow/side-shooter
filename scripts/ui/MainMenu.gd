extends Node

const PILOTS_PATH  := "res://data/pilots.json"
const SETTINGS_PATH := "user://settings.cfg"

const ACCENT   := Color(0.9,  0.8,  0.3,  1.0)
const DIM_TEXT := Color(0.55, 0.55, 0.65, 1.0)
const PANEL_BG := Color(0.04, 0.05, 0.14, 0.97)

# Keybindable actions shown in settings
const BIND_ACTIONS: Array[String] = ["move_up", "move_down", "move_left", "move_right", "fire"]
const BIND_LABELS:  Array[String] = ["Move Up", "Move Down", "Move Left", "Move Right", "Fire"]

# Settings state (loaded from file, applied to AudioServer/display before UI built)
var _cfg := { "master": 1.0, "music": 0.8, "sfx": 1.0, "fullscreen": false }

var _pilots: Array = []

# UI refs for refresh
var _master_slider:    HSlider
var _music_slider:     HSlider
var _sfx_slider:       HSlider
var _fullscreen_check: CheckButton
var _bind_labels: Dictionary = {}   # action → Label

# Rebind state
var _rebinding_action: String = ""
var _rebinding_label:  Label  = null
var _rebinding_button: Button = null

# Overlay panels
var _settings_panel: Panel
var _roster_panel:   Panel


func _ready() -> void:
	_load_and_apply_settings()
	_load_pilots()
	_build_ui()


# ── Data loading ───────────────────────────────────────────────────────────────

func _load_pilots() -> void:
	var file := FileAccess.open(PILOTS_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		for key in parsed:
			_pilots.append(parsed[key])


# ── Build UI ───────────────────────────────────────────────────────────────────

func _build_ui() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 5
	add_child(cl)

	# Dim the parallax slightly
	var dim := ColorRect.new()
	dim.anchor_right  = 1.0
	dim.anchor_bottom = 1.0
	dim.color = Color(0.0, 0.0, 0.0, 0.45)
	cl.add_child(dim)

	# Central column — title + nav buttons
	var col := VBoxContainer.new()
	col.anchor_left  = 0.5
	col.anchor_right = 0.5
	col.anchor_top   = 0.22
	col.offset_left  = -240
	col.offset_right = 240
	col.add_theme_constant_override("separation", 18)
	cl.add_child(col)

	# Title
	var title := Label.new()
	title.text = "THE VOID"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 108)
	title.modulate = ACCENT
	col.add_child(title)

	var tagline := Label.new()
	tagline.text = "SURVIVE THE ENDLESS DARK"
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.add_theme_font_size_override("font_size", 17)
	tagline.modulate = DIM_TEXT
	col.add_child(tagline)

	# Gap
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 48)
	col.add_child(gap)

	# Nav buttons
	var btns := [
		["LAUNCH",   _on_launch],
		["PILOTS",   _on_pilots],
		["SETTINGS", _on_settings],
		["QUIT",     _on_quit],
	]
	for entry in btns:
		var btn := _make_nav_button(entry[0])
		btn.pressed.connect(entry[1])
		col.add_child(btn)

	# Version tag — bottom left
	var ver := Label.new()
	ver.text = "v0.1-alpha"
	ver.anchor_left   = 0.0
	ver.anchor_top    = 1.0
	ver.anchor_bottom = 1.0
	ver.offset_left   = 24
	ver.offset_top    = -36
	ver.offset_bottom = -12
	ver.add_theme_font_size_override("font_size", 13)
	ver.modulate = Color(DIM_TEXT.r, DIM_TEXT.g, DIM_TEXT.b, 0.5)
	cl.add_child(ver)

	# Overlays
	_settings_panel = _build_settings_panel()
	cl.add_child(_settings_panel)
	_roster_panel = _build_roster_panel()
	cl.add_child(_roster_panel)


func _make_nav_button(label_text: String) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.custom_minimum_size = Vector2(480, 64)
	btn.add_theme_font_size_override("font_size", 22)

	var n := StyleBoxFlat.new()
	n.bg_color = Color(0.07, 0.08, 0.20, 0.88)
	n.border_color = Color(0.38, 0.32, 0.12, 0.9)
	n.set_border_width_all(1)
	n.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("normal", n)

	var h := StyleBoxFlat.new()
	h.bg_color = Color(0.12, 0.14, 0.32, 0.97)
	h.border_color = ACCENT
	h.set_border_width_all(2)
	h.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("hover", h)

	var p := StyleBoxFlat.new()
	p.bg_color = Color(0.18, 0.20, 0.42, 1.0)
	p.border_color = ACCENT
	p.set_border_width_all(2)
	p.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("pressed", p)

	return btn


# ── Nav callbacks ──────────────────────────────────────────────────────────────

func _on_launch() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_pilots() -> void:
	_roster_panel.show()

func _on_settings() -> void:
	_refresh_settings_ui()
	_settings_panel.show()

func _on_quit() -> void:
	get_tree().quit()


# ── Pilot Roster overlay ───────────────────────────────────────────────────────

func _build_roster_panel() -> Panel:
	var panel := _make_overlay()

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		vbox.add_theme_constant_override(side, 36)
	vbox.add_theme_constant_override("separation", 18)
	panel.add_child(vbox)

	# Header row
	var hdr := HBoxContainer.new()
	vbox.add_child(hdr)

	var title := Label.new()
	title.text = "PILOT ROSTER"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 34)
	title.modulate = ACCENT
	hdr.add_child(title)

	var close := _make_close_btn(func(): _roster_panel.hide())
	hdr.add_child(close)

	vbox.add_child(_make_sep())

	# Scroll + grid
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var grid := GridContainer.new()
	grid.columns = 4
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	scroll.add_child(grid)

	for p in _pilots:
		grid.add_child(_build_roster_card(p))

	panel.visible = false
	return panel


func _build_roster_card(pilot: Dictionary) -> Panel:
	var card := Panel.new()
	card.custom_minimum_size = Vector2(200, 280)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.10, 0.22, 1.0)
	style.border_color = _rarity_color(pilot.get("rarity", "common"))
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	card.add_theme_stylebox_override("panel", style)

	var mc := MarginContainer.new()
	mc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		mc.add_theme_constant_override(side, 14)
	card.add_child(mc)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 7)
	mc.add_child(inner)

	var img_path: String = pilot.get("image", "")
	if img_path != "":
		var tr := TextureRect.new()
		tr.custom_minimum_size = Vector2(0, 100)
		tr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var tex := load(img_path) as Texture2D
		if tex:
			tr.texture = tex
		inner.add_child(tr)

	var name_lbl := Label.new()
	name_lbl.text = pilot.get("name", "")
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 15)
	name_lbl.modulate = ACCENT
	inner.add_child(name_lbl)

	var rarity_lbl := Label.new()
	rarity_lbl.text = "%s  ·  %s" % [
		pilot.get("type", "").capitalize(),
		pilot.get("rarity", "").capitalize()
	]
	rarity_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity_lbl.add_theme_font_size_override("font_size", 11)
	rarity_lbl.modulate = _rarity_color(pilot.get("rarity", "common"))
	inner.add_child(rarity_lbl)

	inner.add_child(HSeparator.new())

	var desc := Label.new()
	desc.text = pilot.get("desc", "")
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc.add_theme_font_size_override("font_size", 12)
	desc.modulate = DIM_TEXT
	inner.add_child(desc)

	return card


# ── Settings overlay ───────────────────────────────────────────────────────────

func _build_settings_panel() -> Panel:
	var panel := _make_overlay()

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		vbox.add_theme_constant_override(side, 40)
	vbox.add_theme_constant_override("separation", 24)
	panel.add_child(vbox)

	# Header
	var hdr := HBoxContainer.new()
	vbox.add_child(hdr)

	var title := Label.new()
	title.text = "SETTINGS"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 34)
	title.modulate = ACCENT
	hdr.add_child(title)

	var close := _make_close_btn(func(): _settings_panel.hide(); _save_settings())
	hdr.add_child(close)

	vbox.add_child(_make_sep())

	# Two columns
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 60)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(cols)

	# ── Left: Audio + Display ───────────────────────────────────────────
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 14)
	cols.add_child(left)

	_add_section_hdr(left, "AUDIO")
	_master_slider = _add_slider_row(left, "Master Volume",
		_cfg["master"], _on_master_changed)
	_music_slider  = _add_slider_row(left, "Music",
		_cfg["music"],  _on_music_changed)
	_sfx_slider    = _add_slider_row(left, "SFX",
		_cfg["sfx"],    _on_sfx_changed)

	left.add_child(_make_sep())
	_add_section_hdr(left, "DISPLAY")

	var fs_row := HBoxContainer.new()
	fs_row.add_theme_constant_override("separation", 16)
	left.add_child(fs_row)
	var fs_lbl := Label.new()
	fs_lbl.text = "Fullscreen"
	fs_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fs_lbl.add_theme_font_size_override("font_size", 15)
	fs_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fs_row.add_child(fs_lbl)
	_fullscreen_check = CheckButton.new()
	_fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	fs_row.add_child(_fullscreen_check)

	# ── Right: Keybindings ───────────────────────────────────────────────
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 12)
	cols.add_child(right)

	_add_section_hdr(right, "KEYBINDINGS")

	for i in BIND_ACTIONS.size():
		_add_keybind_row(right, BIND_LABELS[i], BIND_ACTIONS[i])

	panel.visible = false
	return panel


func _add_section_hdr(parent: Control, text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.modulate = DIM_TEXT
	parent.add_child(lbl)


func _add_slider_row(parent: Control, label: String, init_val: float,
		callback: Callable) -> HSlider:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	parent.add_child(row)

	var lbl := Label.new()
	lbl.text = label
	lbl.custom_minimum_size = Vector2(140, 0)
	lbl.add_theme_font_size_override("font_size", 15)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(lbl)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step      = 0.01
	slider.value     = init_val
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(0, 30)
	slider.value_changed.connect(callback)
	row.add_child(slider)
	return slider


func _add_keybind_row(parent: Control, label: String, action: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)

	var lbl := Label.new()
	lbl.text = label
	lbl.custom_minimum_size = Vector2(110, 0)
	lbl.add_theme_font_size_override("font_size", 15)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(lbl)

	var bind_lbl := Label.new()
	bind_lbl.text = _get_key_label(action)
	bind_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bind_lbl.add_theme_font_size_override("font_size", 15)
	bind_lbl.modulate = ACCENT
	bind_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(bind_lbl)
	_bind_labels[action] = bind_lbl

	var btn := Button.new()
	btn.text = "Rebind"
	btn.custom_minimum_size = Vector2(80, 0)
	btn.pressed.connect(_start_rebind.bind(action, bind_lbl, btn))
	row.add_child(btn)


# ── Rebinding ──────────────────────────────────────────────────────────────────

func _get_key_label(action: String) -> String:
	var events := InputMap.action_get_events(action)
	for event in events:
		if event is InputEventKey:
			return OS.get_keycode_string(event.physical_keycode)
		if event is InputEventMouseButton:
			return "Mouse %d" % event.button_index
	return "—"


func _start_rebind(action: String, lbl: Label, btn: Button) -> void:
	_rebinding_action = action
	_rebinding_label  = lbl
	_rebinding_button = btn
	lbl.text    = "Press a key…"
	lbl.modulate = Color(1.0, 1.0, 0.4, 1.0)
	btn.disabled = true


func _unhandled_input(event: InputEvent) -> void:
	if _rebinding_action == "":
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			_cancel_rebind()
		else:
			_apply_rebind(event)
	elif event is InputEventMouseButton and event.pressed:
		_apply_rebind(event)


func _cancel_rebind() -> void:
	_rebinding_label.text    = _get_key_label(_rebinding_action)
	_rebinding_label.modulate = ACCENT
	_rebinding_button.disabled = false
	_rebinding_action = ""
	_rebinding_label  = null
	_rebinding_button = null


func _apply_rebind(event: InputEvent) -> void:
	# Remove existing keyboard/mouse events for this action, keep gamepad
	var keep: Array[InputEvent] = []
	for e in InputMap.action_get_events(_rebinding_action):
		if not (e is InputEventKey) and not (e is InputEventMouseButton):
			keep.append(e)
	InputMap.action_erase_events(_rebinding_action)
	for e in keep:
		InputMap.action_add_event(_rebinding_action, e)
	InputMap.action_add_event(_rebinding_action, event)

	_rebinding_label.text    = _get_key_label(_rebinding_action)
	_rebinding_label.modulate = ACCENT
	_rebinding_button.disabled = false
	_rebinding_action = ""
	_rebinding_label  = null
	_rebinding_button = null
	_save_settings()


# ── Audio / display callbacks ──────────────────────────────────────────────────

func _on_master_changed(v: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(v))

func _on_music_changed(v: float) -> void:
	var idx := AudioServer.get_bus_index("Music")
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(v))

func _on_sfx_changed(v: float) -> void:
	var idx := AudioServer.get_bus_index("SFX")
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(v))

func _on_fullscreen_toggled(pressed: bool) -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if pressed
		else DisplayServer.WINDOW_MODE_WINDOWED
	)
	_save_settings()


# ── Settings persistence ───────────────────────────────────────────────────────

func _load_and_apply_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return

	_cfg["master"]     = float(cfg.get_value("audio",   "master",     1.0))
	_cfg["music"]      = float(cfg.get_value("audio",   "music",      0.8))
	_cfg["sfx"]        = float(cfg.get_value("audio",   "sfx",        1.0))
	_cfg["fullscreen"] = bool( cfg.get_value("display", "fullscreen", false))

	AudioServer.set_bus_volume_db(0, linear_to_db(_cfg["master"]))
	var mi := AudioServer.get_bus_index("Music")
	if mi >= 0: AudioServer.set_bus_volume_db(mi, linear_to_db(_cfg["music"]))
	var si := AudioServer.get_bus_index("SFX")
	if si >= 0: AudioServer.set_bus_volume_db(si, linear_to_db(_cfg["sfx"]))

	if _cfg["fullscreen"]:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

	# Restore keybindings
	for action in BIND_ACTIONS:
		var keycode: int = int(cfg.get_value("bindings", action, 0))
		if keycode == 0:
			continue
		var keep: Array[InputEvent] = []
		for e in InputMap.action_get_events(action):
			if not (e is InputEventKey):
				keep.append(e)
		InputMap.action_erase_events(action)
		for e in keep:
			InputMap.action_add_event(action, e)
		var ev := InputEventKey.new()
		ev.physical_keycode = keycode
		InputMap.action_add_event(action, ev)


func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio",   "master",     _master_slider.value if _master_slider else _cfg["master"])
	cfg.set_value("audio",   "music",      _music_slider.value  if _music_slider  else _cfg["music"])
	cfg.set_value("audio",   "sfx",        _sfx_slider.value    if _sfx_slider    else _cfg["sfx"])
	cfg.set_value("display", "fullscreen",
		DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
	for action in BIND_ACTIONS:
		for event in InputMap.action_get_events(action):
			if event is InputEventKey:
				cfg.set_value("bindings", action, event.physical_keycode)
				break
	cfg.save(SETTINGS_PATH)


func _refresh_settings_ui() -> void:
	if _master_slider:    _master_slider.value    = _cfg["master"]
	if _music_slider:     _music_slider.value     = _cfg["music"]
	if _sfx_slider:       _sfx_slider.value       = _cfg["sfx"]
	if _fullscreen_check:
		_fullscreen_check.set_pressed_no_signal(
			DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		)
	for action in _bind_labels:
		_bind_labels[action].text = _get_key_label(action)


# ── Helpers ────────────────────────────────────────────────────────────────────

func _make_overlay() -> Panel:
	var panel := Panel.new()
	panel.anchor_left   = 0.08
	panel.anchor_right  = 0.92
	panel.anchor_top    = 0.08
	panel.anchor_bottom = 0.92
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_BG
	style.border_color = Color(0.28, 0.28, 0.45, 1.0)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _make_close_btn(callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = "✕"
	btn.custom_minimum_size = Vector2(44, 44)
	btn.add_theme_font_size_override("font_size", 18)
	btn.pressed.connect(callback)
	return btn


func _make_sep() -> HSeparator:
	var sep := HSeparator.new()
	sep.modulate = Color(0.25, 0.25, 0.42, 1.0)
	return sep


func _rarity_color(rarity: String) -> Color:
	match rarity:
		"common":    return Color(0.55, 0.55, 0.65, 1.0)
		"rare":      return Color(0.25, 0.55, 1.0,  1.0)
		"epic":      return Color(0.7,  0.3,  1.0,  1.0)
		"legendary": return Color(1.0,  0.75, 0.1,  1.0)
		_:           return Color(0.55, 0.55, 0.65, 1.0)

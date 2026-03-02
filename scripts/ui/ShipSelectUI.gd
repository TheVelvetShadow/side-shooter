extends CanvasLayer

# Emits both ID and full data so Main.gd doesn't need ShipDB loaded yet.
signal ship_selected(ship_id: String, ship_data: Dictionary)

const SHIPS_PATH := "res://data/ships.json"

const BG_COLOR := Color(0.03, 0.04, 0.10, 1.0)
const ACCENT   := Color(0.9,  0.8,  0.3,  1.0)
const DIM_TEXT := Color(0.55, 0.55, 0.65, 1.0)
const LOCKED_C := Color(0.35, 0.35, 0.45, 1.0)

# Ships unlocked for this prototype (Phase H save system will gate these properly)
const UNLOCKED_SHIPS: Array[String] = ["interceptor", "tank", "glass_cannon", "scout", "dreadnought"]
const SHIP_ORDER: Array[String]     = ["interceptor", "tank", "glass_cannon", "scout", "dreadnought"]

var _ships: Dictionary = {}
var _selected_id: String = "interceptor"
var _card_panels: Dictionary = {}
var _launch_btn: Button

func _ready() -> void:
	_load_ships()
	_build_ui()

func _load_ships() -> void:
	var file := FileAccess.open(SHIPS_PATH, FileAccess.READ)
	if file == null:
		push_error("ShipSelectUI: cannot open %s" % SHIPS_PATH)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		_ships = parsed
	else:
		push_error("ShipSelectUI: failed to parse ships.json")

func _get_ordered_ships() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for id in SHIP_ORDER:
		if _ships.has(id):
			result.append(_ships[id])
	return result

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.anchor_right  = 1.0
	bg.anchor_bottom = 1.0
	bg.color = BG_COLOR
	add_child(bg)

	var mc := MarginContainer.new()
	mc.anchor_right  = 1.0
	mc.anchor_bottom = 1.0
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		mc.add_theme_constant_override(side, 48)
	add_child(mc)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 28)
	mc.add_child(root)

	# ── Header ────────────────────────────────────────────────────────────────
	var title := Label.new()
	title.text = "SELECT YOUR SHIP"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.modulate = ACCENT
	root.add_child(title)

	var sub := Label.new()
	sub.text = "Each ship has a distinct identity. Choose your playstyle."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 16)
	sub.modulate = DIM_TEXT
	root.add_child(sub)

	var sep := HSeparator.new()
	sep.modulate = Color(0.25, 0.25, 0.4, 1.0)
	root.add_child(sep)

	# ── Ship cards ────────────────────────────────────────────────────────────
	var cards_row := HBoxContainer.new()
	cards_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards_row.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	cards_row.add_theme_constant_override("separation", 20)
	root.add_child(cards_row)

	for ship in _get_ordered_ships():
		var card := _build_ship_card(ship)
		cards_row.add_child(card)
		_card_panels[ship["id"]] = card

	# ── Bottom row ────────────────────────────────────────────────────────────
	var sep2 := HSeparator.new()
	sep2.modulate = Color(0.25, 0.25, 0.4, 1.0)
	root.add_child(sep2)

	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 20)
	root.add_child(bottom)

	var hint := Label.new()
	hint.text = "Locked ships unlock by completing Antes for the first time."
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.add_theme_font_size_override("font_size", 14)
	hint.modulate = DIM_TEXT
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bottom.add_child(hint)

	_launch_btn = Button.new()
	_launch_btn.text = "Launch  →"
	_launch_btn.custom_minimum_size = Vector2(220, 50)
	_launch_btn.add_theme_font_size_override("font_size", 20)
	_launch_btn.pressed.connect(_on_launch)
	bottom.add_child(_launch_btn)

	_highlight_selected()

func _build_ship_card(ship: Dictionary) -> Panel:
	var ship_id: String = ship["id"]
	var is_locked: bool = ship_id not in UNLOCKED_SHIPS

	var card := Panel.new()
	card.custom_minimum_size = Vector2(220, 0)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical   = Control.SIZE_EXPAND_FILL

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.10, 0.20, 1.0) if not is_locked else Color(0.06, 0.06, 0.12, 1.0)
	style.border_color = DIM_TEXT if not is_locked else LOCKED_C
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	card.add_theme_stylebox_override("panel", style)

	var mc := MarginContainer.new()
	mc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		mc.add_theme_constant_override(side, 16)
	card.add_child(mc)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	mc.add_child(vbox)

	# Portrait
	var portrait_container := PanelContainer.new()
	portrait_container.custom_minimum_size = Vector2(0, 120)
	var port_style := StyleBoxFlat.new()
	port_style.bg_color = Color(0.05, 0.05, 0.12, 1.0)
	port_style.set_corner_radius_all(4)
	portrait_container.add_theme_stylebox_override("panel", port_style)
	vbox.add_child(portrait_container)

	var tex_rect := TextureRect.new()
	tex_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.expand_mode  = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	var img_path: String = ship.get("image", "")
	if img_path != "":
		var tex := load(img_path) as Texture2D
		if tex:
			tex_rect.texture = tex
	if is_locked:
		tex_rect.modulate = Color(0.3, 0.3, 0.3, 1.0)
	portrait_container.add_child(tex_rect)

	if is_locked:
		var lock_lbl := Label.new()
		lock_lbl.text = "LOCKED"
		lock_lbl.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		lock_lbl.add_theme_font_size_override("font_size", 18)
		lock_lbl.modulate = Color(0.8, 0.6, 0.2, 1.0)
		portrait_container.add_child(lock_lbl)

	# Name
	var name_lbl := Label.new()
	name_lbl.text = ship["name"]
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 20)
	name_lbl.modulate = ACCENT if not is_locked else LOCKED_C
	vbox.add_child(name_lbl)

	# Desc
	var desc_lbl := Label.new()
	desc_lbl.text = ship.get("desc", "")
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_font_size_override("font_size", 12)
	desc_lbl.modulate = DIM_TEXT
	vbox.add_child(desc_lbl)

	vbox.add_child(HSeparator.new())

	# Stats
	var stats := [
		["HP",        str(ship.get("hp", 0))],
		["Speed",     str(ship.get("speed", 0))],
		["Slots",     str(ship.get("weapon_slots", 0))],
		["Armour",    str(ship.get("armour", 0))],
		["Wpn Bonus", "+%d" % ship.get("weapon_bonus", 0)],
	]
	for stat in stats:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		vbox.add_child(row)

		var key_lbl := Label.new()
		key_lbl.text = stat[0]
		key_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		key_lbl.add_theme_font_size_override("font_size", 13)
		key_lbl.modulate = DIM_TEXT
		row.add_child(key_lbl)

		var val_lbl := Label.new()
		val_lbl.text = stat[1]
		val_lbl.add_theme_font_size_override("font_size", 13)
		val_lbl.modulate = Color(1.0, 1.0, 1.0, 1.0) if not is_locked else LOCKED_C
		row.add_child(val_lbl)

	vbox.add_child(HSeparator.new())

	var btn := Button.new()
	btn.text = "Select" if not is_locked else "Locked"
	btn.disabled = is_locked
	btn.custom_minimum_size = Vector2(0, 36)
	btn.pressed.connect(_on_ship_card_pressed.bind(ship_id))
	vbox.add_child(btn)

	return card

func _on_ship_card_pressed(ship_id: String) -> void:
	_selected_id = ship_id
	_highlight_selected()

func _highlight_selected() -> void:
	for id in _card_panels:
		var card := _card_panels[id] as Panel
		var style := StyleBoxFlat.new()
		var is_locked: bool = id not in UNLOCKED_SHIPS
		if id == _selected_id:
			style.bg_color = Color(0.12, 0.13, 0.28, 1.0)
			style.border_color = ACCENT
			style.set_border_width_all(3)
		else:
			style.bg_color = Color(0.06, 0.06, 0.12, 1.0) if is_locked else Color(0.09, 0.10, 0.20, 1.0)
			style.border_color = LOCKED_C if is_locked else DIM_TEXT
			style.set_border_width_all(1)
		style.set_corner_radius_all(6)
		card.add_theme_stylebox_override("panel", style)

	var selected_name: String = _ships.get(_selected_id, {}).get("name", _selected_id)
	_launch_btn.text = "Launch %s  →" % selected_name

func _on_launch() -> void:
	ship_selected.emit(_selected_id, _ships.get(_selected_id, {}))
	queue_free()

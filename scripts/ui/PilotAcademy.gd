extends CanvasLayer

const SHIP_UPGRADES: Array[Dictionary] = [
	{"label": "+20 Max HP",      "cost": 30, "effect": "hp"},
	{"label": "+30 Move Speed",  "cost": 30, "effect": "speed"},
	{"label": "+1 Weapon Slot",  "cost": 50, "effect": "weapon_slot"},
	{"label": "+10% Dmg Bonus",  "cost": 40, "effect": "attack"},
]

const ACCENT   := Color(0.9,  0.8,  0.3,  1.0)
const DIM_TEXT := Color(0.55, 0.55, 0.65, 1.0)
const BG_COLOR := Color(0.03, 0.04, 0.10, 1.0)

var _credits_label:     Label
var _subtitle_label:    Label
var _offers_container:  HBoxContainer
var _active_pilots_box: VBoxContainer
var _upgrade_btns:      Array[Button] = []
var _continue_btn:      Button

var _current_ante:  int = 1
var _current_level: int = 1

# Swap state
var _swap_panel:            Panel
var _swap_roster_container: VBoxContainer
var _pending_swap_pilot:    Dictionary = {}


func _ready() -> void:
	visible = false
	_build_screen()
	_build_swap_panel()
	EventBus.level_completed.connect(_on_level_completed)


# ── Build screen ───────────────────────────────────────────────────────────────

func _build_screen() -> void:
	# Full-screen background
	var bg := ColorRect.new()
	bg.anchor_right  = 1.0
	bg.anchor_bottom = 1.0
	bg.color = BG_COLOR
	add_child(bg)

	# Outer margin
	var mc := MarginContainer.new()
	mc.anchor_right  = 1.0
	mc.anchor_bottom = 1.0
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		mc.add_theme_constant_override(side, 40)
	add_child(mc)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 18)
	mc.add_child(root)

	# ── Header ────────────────────────────────────────────────────────────────
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 20)
	root.add_child(header)

	var title_col := VBoxContainer.new()
	title_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_col.add_theme_constant_override("separation", 4)
	header.add_child(title_col)

	var title_lbl := Label.new()
	title_lbl.text = "PILOT ACADEMY"
	title_lbl.add_theme_font_size_override("font_size", 42)
	title_lbl.modulate = ACCENT
	title_col.add_child(title_lbl)

	_subtitle_label = Label.new()
	_subtitle_label.text = "Ante 1  ·  Level 1 Complete"
	_subtitle_label.add_theme_font_size_override("font_size", 16)
	_subtitle_label.modulate = DIM_TEXT
	title_col.add_child(_subtitle_label)

	_credits_label = Label.new()
	_credits_label.text = "0  credits"
	_credits_label.add_theme_font_size_override("font_size", 28)
	_credits_label.modulate = ACCENT
	_credits_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(_credits_label)

	root.add_child(_make_sep())

	# ── Main split: left (pilots) + right (upgrades + roster + continue) ──────
	var split := HBoxContainer.new()
	split.add_theme_constant_override("separation", 32)
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(split)

	# Left — hire pilots
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 14)
	split.add_child(left)

	var hire_hdr := Label.new()
	hire_hdr.text = "HIRE PILOTS"
	hire_hdr.add_theme_font_size_override("font_size", 16)
	hire_hdr.modulate = DIM_TEXT
	left.add_child(hire_hdr)

	_offers_container = HBoxContainer.new()
	_offers_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_offers_container.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	_offers_container.add_theme_constant_override("separation", 18)
	left.add_child(_offers_container)

	# Vertical separator
	var vsep := VSeparator.new()
	vsep.modulate = Color(0.28, 0.28, 0.45, 1.0)
	split.add_child(vsep)

	# Right panel — fixed width
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(340, 0)
	right.add_theme_constant_override("separation", 16)
	split.add_child(right)

	# Ship upgrades section
	var upg_hdr := Label.new()
	upg_hdr.text = "SHIP UPGRADES"
	upg_hdr.add_theme_font_size_override("font_size", 16)
	upg_hdr.modulate = DIM_TEXT
	right.add_child(upg_hdr)

	_upgrade_btns.clear()
	for i in SHIP_UPGRADES.size():
		var upg := SHIP_UPGRADES[i]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		right.add_child(row)

		var upg_lbl := Label.new()
		upg_lbl.text = upg["label"]
		upg_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		upg_lbl.add_theme_font_size_override("font_size", 15)
		row.add_child(upg_lbl)

		var cost_lbl := Label.new()
		cost_lbl.text = "%d cr" % upg["cost"]
		cost_lbl.modulate = ACCENT
		cost_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(cost_lbl)

		var buy_btn := Button.new()
		buy_btn.text = "Buy"
		buy_btn.custom_minimum_size = Vector2(64, 0)
		buy_btn.pressed.connect(_on_upgrade_buy.bind(i))
		row.add_child(buy_btn)
		_upgrade_btns.append(buy_btn)

	right.add_child(_make_sep())

	# Active roster section
	var roster_hdr := Label.new()
	roster_hdr.text = "ACTIVE PILOTS"
	roster_hdr.add_theme_font_size_override("font_size", 16)
	roster_hdr.modulate = DIM_TEXT
	right.add_child(roster_hdr)

	_active_pilots_box = VBoxContainer.new()
	_active_pilots_box.add_theme_constant_override("separation", 6)
	_active_pilots_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(_active_pilots_box)

	# Continue button — bottom of right panel
	_continue_btn = Button.new()
	_continue_btn.text = "Continue  →"
	_continue_btn.custom_minimum_size = Vector2(0, 52)
	_continue_btn.add_theme_font_size_override("font_size", 20)
	_continue_btn.pressed.connect(_on_continue_pressed)
	right.add_child(_continue_btn)


func _make_sep() -> HSeparator:
	var sep := HSeparator.new()
	sep.modulate = Color(0.25, 0.25, 0.4, 1.0)
	return sep


# ── Swap panel ────────────────────────────────────────────────────────────────

func _build_swap_panel() -> void:
	_swap_panel = Panel.new()
	_swap_panel.anchor_left   = 0.5
	_swap_panel.anchor_right  = 0.5
	_swap_panel.anchor_top    = 0.5
	_swap_panel.anchor_bottom = 0.5
	_swap_panel.offset_left   = -220.0
	_swap_panel.offset_right  =  220.0
	_swap_panel.offset_top    = -200.0
	_swap_panel.offset_bottom =  200.0

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.08, 0.18, 0.97)
	style.border_color = ACCENT
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	_swap_panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		vbox.add_theme_constant_override(side, 20)
	vbox.add_theme_constant_override("separation", 14)
	_swap_panel.add_child(vbox)

	var title := Label.new()
	title.text = "Replace which pilot?"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.modulate = ACCENT
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	_swap_roster_container = VBoxContainer.new()
	_swap_roster_container.add_theme_constant_override("separation", 8)
	vbox.add_child(_swap_roster_container)

	vbox.add_child(HSeparator.new())

	var cancel := Button.new()
	cancel.text = "Cancel"
	cancel.pressed.connect(func(): _swap_panel.hide())
	vbox.add_child(cancel)

	_swap_panel.visible = false
	add_child(_swap_panel)


func _show_swap_panel(offer_pilot: Dictionary) -> void:
	_pending_swap_pilot = offer_pilot
	for c in _swap_roster_container.get_children():
		c.queue_free()
	for i in PilotManager.active_pilots.size():
		var p: Dictionary = PilotManager.active_pilots[i]
		var btn := Button.new()
		btn.text = "%s  (%s)" % [p["name"], p.get("rarity", "").capitalize()]
		btn.pressed.connect(_on_swap_target.bind(i))
		_swap_roster_container.add_child(btn)
	_swap_panel.show()


func _on_swap_target(index: int) -> void:
	if not GameManager.spend_credits(_pending_swap_pilot["cost"]):
		_swap_panel.hide()
		return
	var player := get_tree().get_first_node_in_group("player")
	PilotManager.replace_pilot(index, _pending_swap_pilot, player)
	_swap_panel.hide()
	_refresh_credits()
	_refresh_roster()
	_show_offers()


# ── Level completed ────────────────────────────────────────────────────────────

func _on_level_completed(ante: int, level: int) -> void:
	_current_ante  = ante
	_current_level = level
	_subtitle_label.text = "Ante %d  ·  Level %d Complete" % [ante, level]
	_continue_btn.text = (
		"Enter Level %d  →" % (_current_level + 1)
		if _current_level < 3
		else "Ante %d Complete  →" % _current_ante
	)
	_refresh_credits()
	_show_offers()
	_refresh_upgrade_buttons()
	_refresh_roster()
	visible = true
	get_tree().paused = true


# ── Pilot offers ───────────────────────────────────────────────────────────────

func _show_offers() -> void:
	for c in _offers_container.get_children():
		c.queue_free()
	var offers := PilotManager.get_weighted_offers(3)
	for pilot in offers:
		_offers_container.add_child(_build_pilot_card(pilot))


func _build_pilot_card(pilot: Dictionary) -> Panel:
	var card := Panel.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical   = Control.SIZE_EXPAND_FILL

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.10, 0.22, 1.0)
	style.border_color = _rarity_color(pilot.get("rarity", "common"))
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	card.add_theme_stylebox_override("panel", style)

	var mc := MarginContainer.new()
	mc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		mc.add_theme_constant_override(side, 16)
	card.add_child(mc)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 10)
	mc.add_child(inner)

	# Portrait — taller for split layout
	var img_path: String = pilot.get("image", "")
	if img_path != "":
		var tr := TextureRect.new()
		tr.custom_minimum_size = Vector2(0, 180)
		tr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var tex := load(img_path) as Texture2D
		if tex:
			tr.texture = tex
		inner.add_child(tr)

	var name_lbl := Label.new()
	name_lbl.text = pilot["name"]
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 20)
	name_lbl.modulate = ACCENT
	inner.add_child(name_lbl)

	var type_lbl := Label.new()
	type_lbl.text = "%s  ·  %s" % [
		pilot["type"].capitalize(),
		pilot.get("rarity", "").capitalize()
	]
	type_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_lbl.add_theme_font_size_override("font_size", 12)
	type_lbl.modulate = _rarity_color(pilot.get("rarity", "common"))
	inner.add_child(type_lbl)

	inner.add_child(HSeparator.new())

	var desc_lbl := Label.new()
	desc_lbl.text = pilot.get("desc", "")
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc_lbl.add_theme_font_size_override("font_size", 14)
	inner.add_child(desc_lbl)

	var cost_lbl := Label.new()
	cost_lbl.text = "%d cr" % pilot["cost"]
	cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_lbl.add_theme_font_size_override("font_size", 16)
	cost_lbl.modulate = ACCENT
	inner.add_child(cost_lbl)

	var roster_full: bool = PilotManager.active_pilots.size() >= PilotManager.MAX_PILOTS
	var can_afford: bool  = GameManager.credits >= int(pilot["cost"])
	var hire_btn := Button.new()
	if roster_full:
		hire_btn.text     = "Swap"
		hire_btn.disabled = not can_afford
		hire_btn.pressed.connect(_show_swap_panel.bind(pilot))
	else:
		hire_btn.text     = "Hire"
		hire_btn.disabled = not can_afford
		hire_btn.pressed.connect(_on_pilot_buy.bind(pilot, hire_btn))
	hire_btn.custom_minimum_size = Vector2(0, 40)
	inner.add_child(hire_btn)

	return card


func _rarity_color(rarity: String) -> Color:
	match rarity:
		"common":    return Color(0.55, 0.55, 0.65, 1.0)
		"rare":      return Color(0.25, 0.55, 1.0,  1.0)
		"epic":      return Color(0.7,  0.3,  1.0,  1.0)
		"legendary": return Color(1.0,  0.75, 0.1,  1.0)
		_:           return Color(0.55, 0.55, 0.65, 1.0)


# ── Buy / upgrade callbacks ────────────────────────────────────────────────────

func _on_pilot_buy(pilot: Dictionary, hire_btn: Button) -> void:
	if not GameManager.spend_credits(pilot["cost"]):
		return
	var player := get_tree().get_first_node_in_group("player")
	PilotManager.add_pilot(pilot, player)
	hire_btn.disabled = true
	_refresh_credits()
	_refresh_roster()
	_show_offers()


func _on_upgrade_buy(index: int) -> void:
	var upg := SHIP_UPGRADES[index]
	if not GameManager.spend_credits(upg["cost"]):
		return
	var player := get_tree().get_first_node_in_group("player")
	if player:
		_apply_ship_upgrade(upg["effect"], player)
	_upgrade_btns[index].disabled = true
	_refresh_credits()


func _apply_ship_upgrade(effect: String, player: Node) -> void:
	match effect:
		"hp":
			player.max_hp += 20
			player.current_hp = mini(player.current_hp + 20, player.max_hp)
			EventBus.player_hp_changed.emit(player.current_hp, player.max_hp)
		"speed":
			player.move_speed += 30.0
		"weapon_slot":
			player.unlock_slot()
		"attack":
			player.attack_multiplier += 0.10


# ── Refresh helpers ────────────────────────────────────────────────────────────

func _refresh_credits() -> void:
	_credits_label.text = "%d  credits" % GameManager.credits
	_refresh_upgrade_buttons()


func _refresh_roster() -> void:
	for c in _active_pilots_box.get_children():
		c.queue_free()
	if PilotManager.active_pilots.is_empty():
		var none_lbl := Label.new()
		none_lbl.text = "None"
		none_lbl.add_theme_font_size_override("font_size", 14)
		none_lbl.modulate = DIM_TEXT
		_active_pilots_box.add_child(none_lbl)
		return
	for p in PilotManager.active_pilots:
		var lbl := Label.new()
		lbl.text = "·  %s" % p["name"]
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.modulate = _rarity_color(p.get("rarity", "common"))
		_active_pilots_box.add_child(lbl)


func _refresh_upgrade_buttons() -> void:
	for i in _upgrade_btns.size():
		if not _upgrade_btns[i].disabled:
			_upgrade_btns[i].disabled = GameManager.credits < SHIP_UPGRADES[i]["cost"]


# ── Continue ───────────────────────────────────────────────────────────────────

func _on_continue_pressed() -> void:
	visible = false
	get_tree().paused = false
	EventBus.pilot_academy_closed.emit()

extends CanvasLayer

const SHIP_UPGRADES: Array[Dictionary] = [
	{"label": "+20 Max HP",     "cost": 30, "effect": "hp"},
	{"label": "+30 Move Speed", "cost": 30, "effect": "speed"},
	{"label": "+1 Weapon Slot", "cost": 50, "effect": "weapon_slot"},
	{"label": "+10% Dmg Bonus", "cost": 40, "effect": "attack"},
]

const BG_COLOR    := Color(0.04, 0.05, 0.12, 1.0)   # deep navy — fully opaque
const ACCENT      := Color(0.9,  0.8,  0.3,  1.0)   # gold
const DIM_TEXT    := Color(0.55, 0.55, 0.65, 1.0)

var _credits_label: Label
var _subtitle_label: Label
var _offers_container: HBoxContainer
var _active_pilots_label: Label
var _upgrade_btns: Array[Button] = []
var _continue_btn: Button

var _current_ante: int = 1
var _current_level: int = 1

func _ready() -> void:
	visible = false
	_build_screen()
	EventBus.level_completed.connect(_on_level_completed)

func _build_screen() -> void:
	# ── Full-screen opaque background ────────────────────────────────────────
	var bg := ColorRect.new()
	bg.anchor_right  = 1.0
	bg.anchor_bottom = 1.0
	bg.color = BG_COLOR
	add_child(bg)

	# ── Content margin ────────────────────────────────────────────────────────
	var mc := MarginContainer.new()
	mc.anchor_right  = 1.0
	mc.anchor_bottom = 1.0
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		mc.add_theme_constant_override(side, 48)
	add_child(mc)

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 20)
	mc.add_child(root_vbox)

	# ── Header ────────────────────────────────────────────────────────────────
	var header_row := HBoxContainer.new()
	root_vbox.add_child(header_row)

	var title_col := VBoxContainer.new()
	title_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_col.add_theme_constant_override("separation", 4)
	header_row.add_child(title_col)

	var title_lbl := Label.new()
	title_lbl.text = "⚔  PILOT ACADEMY"
	title_lbl.add_theme_font_size_override("font_size", 42)
	title_lbl.modulate = ACCENT
	title_col.add_child(title_lbl)

	_subtitle_label = Label.new()
	_subtitle_label.text = "Ante 1  ·  Level 1 Complete"
	_subtitle_label.add_theme_font_size_override("font_size", 16)
	_subtitle_label.modulate = DIM_TEXT
	title_col.add_child(_subtitle_label)

	_credits_label = Label.new()
	_credits_label.text = "💰  0"
	_credits_label.add_theme_font_size_override("font_size", 28)
	_credits_label.modulate = ACCENT
	_credits_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header_row.add_child(_credits_label)

	root_vbox.add_child(_make_separator())

	# ── Main columns ──────────────────────────────────────────────────────────
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 40)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(cols)

	# Left: pilot offers
	var pilots_col := VBoxContainer.new()
	pilots_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pilots_col.add_theme_constant_override("separation", 14)
	cols.add_child(pilots_col)

	var hire_hdr := Label.new()
	hire_hdr.text = "HIRE PILOTS"
	hire_hdr.add_theme_font_size_override("font_size", 18)
	hire_hdr.modulate = DIM_TEXT
	pilots_col.add_child(hire_hdr)

	_offers_container = HBoxContainer.new()
	_offers_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_offers_container.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	_offers_container.add_theme_constant_override("separation", 16)
	pilots_col.add_child(_offers_container)

	# Separator
	var vsep := VSeparator.new()
	vsep.modulate = Color(0.3, 0.3, 0.45, 1.0)
	cols.add_child(vsep)

	# Right: ship upgrades
	var upgrades_col := VBoxContainer.new()
	upgrades_col.custom_minimum_size = Vector2(320, 0)
	upgrades_col.add_theme_constant_override("separation", 14)
	cols.add_child(upgrades_col)

	var upg_hdr := Label.new()
	upg_hdr.text = "SHIP UPGRADES"
	upg_hdr.add_theme_font_size_override("font_size", 18)
	upg_hdr.modulate = DIM_TEXT
	upgrades_col.add_child(upg_hdr)

	_upgrade_btns.clear()
	for i in SHIP_UPGRADES.size():
		var upg := SHIP_UPGRADES[i]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		upgrades_col.add_child(row)

		var upg_lbl := Label.new()
		upg_lbl.text = upg["label"]
		upg_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		upg_lbl.add_theme_font_size_override("font_size", 15)
		row.add_child(upg_lbl)

		var cost_lbl := Label.new()
		cost_lbl.text = "💰 %d" % upg["cost"]
		cost_lbl.modulate = ACCENT
		cost_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(cost_lbl)

		var buy_btn := Button.new()
		buy_btn.text = "Buy"
		buy_btn.custom_minimum_size = Vector2(70, 0)
		buy_btn.pressed.connect(_on_upgrade_buy.bind(i))
		row.add_child(buy_btn)
		_upgrade_btns.append(buy_btn)

	root_vbox.add_child(_make_separator())

	# ── Active roster ─────────────────────────────────────────────────────────
	var roster_row := HBoxContainer.new()
	roster_row.add_theme_constant_override("separation", 16)
	root_vbox.add_child(roster_row)

	var roster_hdr := Label.new()
	roster_hdr.text = "ACTIVE PILOTS:"
	roster_hdr.add_theme_font_size_override("font_size", 14)
	roster_hdr.modulate = DIM_TEXT
	roster_hdr.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	roster_row.add_child(roster_hdr)

	_active_pilots_label = Label.new()
	_active_pilots_label.text = "None"
	_active_pilots_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_active_pilots_label.add_theme_font_size_override("font_size", 14)
	_active_pilots_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	roster_row.add_child(_active_pilots_label)

	_continue_btn = Button.new()
	_continue_btn.text = "Continue  →"
	_continue_btn.custom_minimum_size = Vector2(200, 44)
	_continue_btn.add_theme_font_size_override("font_size", 18)
	_continue_btn.pressed.connect(_on_continue_pressed)
	roster_row.add_child(_continue_btn)

func _make_separator() -> HSeparator:
	var sep := HSeparator.new()
	sep.modulate = Color(0.25, 0.25, 0.4, 1.0)
	return sep

func _on_level_completed(ante: int, level: int) -> void:
	_current_ante  = ante
	_current_level = level
	_subtitle_label.text = "Ante %d  ·  Level %d Complete" % [ante, level]
	_continue_btn.text = "Enter Level %d  →" % (_current_level + 1) \
		if _current_level < 3 else "Ante %d Complete  →" % _current_ante
	_refresh_credits()
	_show_offers()
	_refresh_upgrade_buttons()
	_refresh_roster()
	visible = true
	get_tree().paused = true

func _show_offers() -> void:
	for c in _offers_container.get_children():
		c.queue_free()
	var available := PilotManager.get_available_pilots()
	available.shuffle()
	var offers := available.slice(0, min(3, available.size()))
	for pilot in offers:
		_offers_container.add_child(_build_pilot_card(pilot))

func _build_pilot_card(pilot: Dictionary) -> Panel:
	var card := Panel.new()
	card.custom_minimum_size = Vector2(200, 240)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Slightly lighter panel background
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.11, 0.22, 1.0)
	style.border_color = Color(0.25, 0.25, 0.45, 1.0)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	card.add_theme_stylebox_override("panel", style)

	var mc := MarginContainer.new()
	mc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		mc.add_theme_constant_override(side, 12)
	card.add_child(mc)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 8)
	mc.add_child(inner)

	var name_lbl := Label.new()
	name_lbl.text = pilot["name"]
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 17)
	name_lbl.modulate = ACCENT
	inner.add_child(name_lbl)

	var type_lbl := Label.new()
	type_lbl.text = "%s  ·  %s" % [pilot["type"].capitalize(), pilot.get("rarity", "").capitalize()]
	type_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_lbl.add_theme_font_size_override("font_size", 11)
	type_lbl.modulate = DIM_TEXT
	inner.add_child(type_lbl)

	inner.add_child(HSeparator.new())

	var desc_lbl := Label.new()
	desc_lbl.text = pilot.get("desc", "")
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc_lbl.add_theme_font_size_override("font_size", 13)
	inner.add_child(desc_lbl)

	var cost_lbl := Label.new()
	cost_lbl.text = "💰 %d" % pilot["cost"]
	cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_lbl.modulate = ACCENT
	inner.add_child(cost_lbl)

	var roster_full: bool = PilotManager.active_pilots.size() >= PilotManager.MAX_PILOTS
	var can_afford: bool  = GameManager.credits >= int(pilot["cost"])
	var hire_btn := Button.new()
	hire_btn.text = "Hire"
	hire_btn.disabled = not can_afford or roster_full
	hire_btn.pressed.connect(_on_pilot_buy.bind(pilot, hire_btn))
	inner.add_child(hire_btn)

	return card

func _on_pilot_buy(pilot: Dictionary, hire_btn: Button) -> void:
	if not GameManager.spend_credits(pilot["cost"]):
		return
	var player := get_tree().get_first_node_in_group("player")
	PilotManager.add_pilot(pilot, player)
	hire_btn.disabled = true
	_refresh_credits()
	_refresh_roster()
	_refresh_offer_buttons_for_roster()

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

func _refresh_credits() -> void:
	_credits_label.text = "💰  %d" % GameManager.credits
	_refresh_upgrade_buttons()

func _refresh_roster() -> void:
	if PilotManager.active_pilots.is_empty():
		_active_pilots_label.text = "None"
	else:
		var names: Array[String] = []
		for p in PilotManager.active_pilots:
			names.append(p["name"])
		_active_pilots_label.text = "  ·  ".join(names)

func _refresh_upgrade_buttons() -> void:
	for i in _upgrade_btns.size():
		if not _upgrade_btns[i].disabled:
			_upgrade_btns[i].disabled = GameManager.credits < SHIP_UPGRADES[i]["cost"]

func _refresh_offer_buttons_for_roster() -> void:
	if PilotManager.active_pilots.size() < PilotManager.MAX_PILOTS:
		return
	for card in _offers_container.get_children():
		var btn := _get_card_hire_btn(card)
		if btn and not btn.disabled:
			btn.disabled = true

func _get_card_hire_btn(card: Panel) -> Button:
	var mc := card.get_child(0)
	if mc == null:
		return null
	var inner := mc.get_child(0)
	if inner == null:
		return null
	return inner.get_child(inner.get_child_count() - 1) as Button

func _on_continue_pressed() -> void:
	visible = false
	get_tree().paused = false
	EventBus.pilot_academy_closed.emit()

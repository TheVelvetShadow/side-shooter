extends CanvasLayer
class_name DebugConsole

const _HEIGHT := 240

var _panel: PanelContainer
var _history: RichTextLabel
var _input: LineEdit

func _ready() -> void:
	layer = 101   # above DebugMenu (100)
	process_mode = PROCESS_MODE_ALWAYS
	_build_ui()
	_panel.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if event.keycode == KEY_QUOTELEFT:
		_set_open(not _panel.visible)
		get_viewport().set_input_as_handled()
	elif _panel.visible and event.keycode == KEY_ESCAPE:
		_set_open(false)
		get_viewport().set_input_as_handled()

func _set_open(v: bool) -> void:
	_panel.visible = v
	if v:
		_input.grab_focus()
	else:
		_input.release_focus()

# ── UI construction ───────────────────────────────────────────────────────────

func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.offset_top = -_HEIGHT

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.04, 0.07, 0.94)
	style.border_color = Color(0.2, 0.8, 0.35, 0.9)
	style.set_border_width_all(1)
	_panel.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   10)
	margin.add_theme_constant_override("margin_right",  10)
	margin.add_theme_constant_override("margin_top",    6)
	margin.add_theme_constant_override("margin_bottom", 6)
	_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "DEBUG CONSOLE  [` toggle | ESC close]"
	title.add_theme_color_override("font_color", Color(0.25, 0.75, 0.35))
	title.add_theme_font_size_override("font_size", 10)
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	_history = RichTextLabel.new()
	_history.bbcode_enabled = true
	_history.scroll_following = true
	_history.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_history.add_theme_font_size_override("normal_font_size", 11)
	_history.add_theme_color_override("default_color", Color(0.85, 0.85, 0.85))
	vbox.add_child(_history)

	var input_row := HBoxContainer.new()
	input_row.add_theme_constant_override("separation", 6)
	vbox.add_child(input_row)

	var prompt := Label.new()
	prompt.text = ">"
	prompt.add_theme_color_override("font_color", Color(0.25, 0.85, 0.4))
	prompt.add_theme_font_size_override("font_size", 13)
	input_row.add_child(prompt)

	_input = LineEdit.new()
	_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_input.add_theme_font_size_override("font_size", 12)
	_input.placeholder_text = "type a command — 'help' for list"
	_input.text_submitted.connect(_on_submitted)
	input_row.add_child(_input)

	add_child(_panel)

	_ok("Console ready.  Type [b]help[/b] for available commands.")

# ── Input handling ────────────────────────────────────────────────────────────

func _on_submitted(text: String) -> void:
	_input.text = ""
	var trimmed := text.strip_edges()
	if trimmed.is_empty():
		return
	_log("[color=#555555]> %s[/color]" % trimmed)
	_execute(trimmed)

# ── Logging helpers ───────────────────────────────────────────────────────────

func _log(msg: String) -> void:
	_history.append_text(msg + "\n")

func _ok(msg: String) -> void:
	_log("[color=#44dd66]%s[/color]" % msg)

func _err(msg: String) -> void:
	_log("[color=#ff5555]%s[/color]" % msg)

func _info(msg: String) -> void:
	_log("[color=#aaaaaa]%s[/color]" % msg)

# ── Command dispatch ──────────────────────────────────────────────────────────

func _execute(cmd: String) -> void:
	var parts := cmd.split(" ", false)
	if parts.is_empty():
		return
	match (parts[0] as String).to_lower():
		"help":     _cmd_help()
		"aim":      _cmd_flag("aiming_enabled",   "Auto-aim")
		"god":      _cmd_flag("god_mode",         "God mode")
		"labels":   _cmd_flag_redraw("show_enemy_labels", "Enemy labels")
		"upgrades": _cmd_flag("upgrades_enabled", "Upgrade cards")
		"skip":     _cmd_flag("skip_ship_select", "Skip ship select")
		"heal":     _cmd_heal()
		"kill":     _cmd_kill()
		"spawn":    _cmd_spawn(parts)
		"solo":     _cmd_solo(parts)
		"credits":  _cmd_credits(parts)
		"xp":       _cmd_xp()
		"level":    _cmd_level()
		"flock":    _cmd_flock(parts)
		_:          _err("Unknown: '%s'  —  type 'help'" % parts[0])

# ── Commands ──────────────────────────────────────────────────────────────────

func _cmd_help() -> void:
	_info("""[b]Flags[/b] (toggle on/off)
  aim       — auto-aim (off = fires straight left)
  god       — god mode (negate damage)
  labels    — enemy name tags
  upgrades  — weapon upgrade card menu
  skip      — skip ship select on next run start

[b]Actions[/b]
  heal              — fully heal player
  kill              — kill all live enemies
  spawn <id>        — spawn one enemy  (e.g. spawn enemy_02)
  solo  <id>        — restrict spawn pool to one type
  credits [amount]  — add credits (default 500)
  xp                — trigger weapon upgrade menu
  level             — skip to next level

[b]Flock[/b]
  flock <key> <val>
  keys: radius  sep_radius  sep_w  align_w  cohesion_w  seek_w  steer_rate""")

func _cmd_flag(property: String, label: String) -> void:
	var val := not GameManager.get(property) as bool
	GameManager.set(property, val)
	_ok("%s: %s" % [label, "ON" if val else "OFF"])

func _cmd_flag_redraw(property: String, label: String) -> void:
	_cmd_flag(property, label)
	for node in get_tree().get_nodes_in_group("level_objects"):
		if node.has_method("queue_redraw"):
			node.queue_redraw()

func _cmd_heal() -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null:
		_err("No player in scene")
		return
	player.heal(player.max_hp + player.max_shield)
	_ok("Player fully healed")

func _cmd_kill() -> void:
	var count := 0
	for node in get_tree().get_nodes_in_group("level_objects"):
		if node.is_in_group("player"):
			continue
		if node.has_method("take_damage"):
			node.call("take_damage", 999999, -1)
			count += 1
	_ok("Killed %d enemies" % count)

func _cmd_spawn(parts: Array) -> void:
	if parts.size() < 2:
		_err("Usage: spawn <enemy_id>")
		return
	var id: String = parts[1]
	var data := EnemyDB.get_enemy(id)
	if data.is_empty():
		_err("Unknown enemy id '%s'" % id)
		return
	var scene := load("res://scenes/enemies/Enemy.tscn") as PackedScene
	var enemy := scene.instantiate()
	enemy.enemy_id = id
	var vp := get_viewport().get_visible_rect().size
	enemy.global_position = Vector2(vp.x * 0.65, vp.y * 0.5)
	get_tree().root.add_child(enemy)
	var name_str: String = data.get("name", id)
	_ok("Spawned %s [%s]" % [name_str, id])

func _cmd_solo(parts: Array) -> void:
	if parts.size() < 2:
		_err("Usage: solo <enemy_id>")
		return
	var id: String = parts[1]
	if EnemyDB.get_enemy(id).is_empty():
		_err("Unknown enemy id '%s'" % id)
		return
	EnemyDB.enable_only(id)
	var name_str: String = EnemyDB.get_enemy(id).get("name", id)
	_ok("Solo: %s — all others disabled" % name_str)

func _cmd_credits(parts: Array) -> void:
	var amount := 500
	if parts.size() >= 2 and (parts[1] as String).is_valid_int():
		amount = (parts[1] as String).to_int()
	GameManager.credits += amount
	EventBus.credits_changed.emit(GameManager.credits)
	_ok("Added %d credits  (total: %d)" % [amount, GameManager.credits])

func _cmd_xp() -> void:
	GameManager.weapon_xp = GameManager.weapon_xp_threshold
	GameManager._check_weapon_upgrade()
	_ok("Weapon upgrade triggered")

func _cmd_level() -> void:
	LevelManager.debug_skip_level()
	_ok("Level skipped")

func _cmd_flock(parts: Array) -> void:
	if parts.size() < 3:
		_err("Usage: flock <key> <value>")
		_info("Keys: radius  sep_radius  sep_w  align_w  cohesion_w  seek_w  steer_rate")
		return
	var key: String = parts[1].to_lower()
	if not (parts[2] as String).is_valid_float():
		_err("Value must be a number")
		return
	var val: float = (parts[2] as String).to_float()
	var prop_map: Dictionary = {
		"radius":      "flock_radius",
		"sep_radius":  "flock_sep_radius",
		"sep_w":       "flock_sep_w",
		"align_w":     "flock_align_w",
		"cohesion_w":  "flock_cohesion_w",
		"seek_w":      "flock_seek_w",
		"steer_rate":  "flock_steer_rate",
	}
	if not prop_map.has(key):
		_err("Unknown key '%s'" % key)
		_info("Valid keys: " + "  ".join(prop_map.keys()))
		return
	GameManager.set(prop_map[key], val)
	_ok("flock.%s = %.2f" % [key, val])

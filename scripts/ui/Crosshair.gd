extends Node2D

const AIM_SPEED := 800.0
const SIZE := 10.0   # arm length
const GAP  := 5.0    # gap from centre
const COLOR := Color(1.0, 1.0, 1.0, 0.9)
const LINE_W := 1.5

var _using_gamepad := false

func _ready() -> void:
	add_to_group("crosshair")
	position = get_viewport_rect().size / 2.0
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PAUSED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			hide()
		NOTIFICATION_UNPAUSED:
			Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
			show()

func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_using_gamepad = false
	elif event is InputEventJoypadMotion and absf(event.axis_value) > 0.1:
		_using_gamepad = true

func _process(delta: float) -> void:
	if not _using_gamepad:
		position = get_viewport().get_mouse_position()
	else:
		var stick := Vector2(
			Input.get_axis("aim_left", "aim_right"),
			Input.get_axis("aim_up", "aim_down")
		)
		position += stick * AIM_SPEED * delta
		position = position.clamp(Vector2.ZERO, get_viewport_rect().size)
	queue_redraw()

func _draw() -> void:
	# Arms
	draw_line(Vector2(-SIZE - GAP, 0.0), Vector2(-GAP, 0.0), COLOR, LINE_W)
	draw_line(Vector2(GAP, 0.0),         Vector2(SIZE + GAP, 0.0), COLOR, LINE_W)
	draw_line(Vector2(0.0, -SIZE - GAP), Vector2(0.0, -GAP), COLOR, LINE_W)
	draw_line(Vector2(0.0, GAP),         Vector2(0.0, SIZE + GAP), COLOR, LINE_W)
	# Centre dot + ring
	draw_circle(Vector2.ZERO, 1.5, COLOR)
	draw_arc(Vector2.ZERO, GAP + 1.0, 0.0, TAU, 32, COLOR, LINE_W)

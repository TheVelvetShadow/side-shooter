extends Camera2D

var _strength: float = 0.0
var _duration: float = 0.0
var _elapsed:  float = 1.0   # start "finished" so offset is zero


func _ready() -> void:
	# Centre the camera so the view matches Godot's default (top-left at world origin)
	position = get_viewport().get_visible_rect().size / 2.0
	make_current()
	EventBus.camera_shake.connect(_on_camera_shake)


func _on_camera_shake(strength: float, duration: float) -> void:
	# Don't downgrade an active shake
	_strength = maxf(strength, _strength)
	_duration = duration
	_elapsed  = 0.0


func _process(delta: float) -> void:
	if _elapsed >= _duration:
		offset = Vector2.ZERO
		return
	_elapsed += delta
	var t := 1.0 - (_elapsed / _duration)   # 1→0 falloff
	var s := _strength * t
	offset = Vector2(randf_range(-s, s), randf_range(-s, s))
